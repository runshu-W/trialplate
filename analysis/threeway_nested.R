## Reviewer round 6, major point 1. The three-way results were reported as point
## estimates over 400 and 300 repeated splits, with no patient-level uncertainty,
## while the Methods say every out-of-sample quantity passes through the same outer
## bootstrap split by patient identifier. Repeated three-way splits reuse the same
## patients, so their spread understates population uncertainty in exactly the way
## the paper argues elsewhere. The reviewer is right that we cannot both make that
## argument and exempt the numbers we ask a reader to carry away.
##
## This wraps the WHOLE fit / select / test pipeline in the outer bootstrap:
##   outer  B resamples of the cohort (b = 1 is the observed data)
##   inner  R three-way stratified splits within each resample, split by patient id
## so no patient appears in more than one third of a given split.
##
## Reported with patient-level intervals:
##   repro       of the subsets that dominate on the selection third, the share
##               that still dominate on the untouched test third
##   front_conf  the rule is left undominated by EVERY pre-selected subset
##   best_holds  the single lowest-hazard-ratio dominator carries over
## and, so that the comparison the reviewer asks for is available within one design,
##   front_sel   the rule is undominated on the selection third   (empirical)
##   front_test  the rule is undominated on a fresh scan of the test third (descriptive)
source("analysis/_setup.R")

B_OUT <- as.integer(Sys.getenv("TW_B", "100"))
R_IN  <- as.integer(Sys.getenv("TW_R", "25"))
MARGIN <- 0.05

## three-way stratified split over UNIQUE patient identifiers
split3_ids <- function(d, trt, st) {
  first <- !duplicated(d$.oid)
  key <- interaction(d[[trt]][first], d[[st]][first], drop = TRUE)
  ids <- d$.oid[first]
  g <- integer(length(ids)); names(g) <- as.character(ids)
  for (lv in levels(key)) {
    v <- ids[key == lv]; if (!length(v)) next
    g[as.character(v)] <- sample(rep_len(1:3, length(v)))
  }
  g[as.character(d$.oid)]
}

one_split <- function(db, crit, ps, trt, tm, st, tau, p, bits) {
  g <- split3_ids(db, trt, st)
  if (length(unique(g)) < 3) return(NULL)
  A <- tp_prepare(db[g == 1, , drop = FALSE], crit, trt, tm, st, ps, tau = tau)
  Va <- tryCatch(tp_enumerate(A), error = function(e) NULL)
  if (is.null(Va) || any(Va[, "feasible"] == 0)) return(NULL)
  S <- which(tp_shapley(Va, p, 1L) < 0); kR <- sum(bits[S]) + 1L
  ev <- function(sel) {
    V <- tryCatch(tp_enumerate(tp_prepare(db[g == sel, , drop = FALSE],
                                          crit, trt, tm, st, ps, tau = tau)),
                  error = function(e) NULL)
    if (is.null(V)) return(NULL)
    list(ok = V[, "feasible"] == 1, N = exp(V[, "logN"]), H = V[, "logHR"])
  }
  B <- ev(2); C <- ev(3); if (is.null(B) || is.null(C)) return(NULL)
  if (!B$ok[kR] || !C$ok[kR]) return(NULL)
  dom <- function(X) X$ok & X$N >= X$N[kR] & X$H <= X$H[kR] & (X$N > X$N[kR] | X$H < X$H[kR])
  dB <- dom(B); dC <- dom(C); nB <- sum(dB)
  dBM <- B$ok & B$N >= B$N[kR] & B$H <= B$H[kR] - MARGIN
  c(n_domB = nB, n_domC = sum(dC), n_survive = if (nB) sum(dC[dB]) else 0,
    repro  = if (nB) mean(dC[dB]) else NA_real_,
    reproM = if (sum(dBM)) mean(dC[dBM]) else NA_real_,
    front_sel  = as.numeric(!any(dB)),
    front_test = as.numeric(!any(dC)),
    front_conf = if (nB) as.numeric(!any(dC[dB])) else 1,
    best_holds = if (nB) {
      j <- which(dB)[which.min(B$H[dB])]
      as.numeric(C$ok[j] && C$N[j] >= C$N[kR] && C$H[j] <= C$H[kR])
    } else NA_real_)
}

nested3 <- function(dat, crit, ps, trt, tm, st, tau, label, seed = 61) {
  set.seed(seed); n <- nrow(dat); p <- length(crit)
  bits <- bitwShiftL(1L, 0:(p - 1)); dat$.oid <- seq_len(n)
  outer <- .tp_lapply(seq_len(B_OUT), function(b) {
    set.seed(seed * 977 + b)
    db <- if (b == 1L) dat else dat[sample(n, n, replace = TRUE), , drop = FALSE]
    rows <- lapply(seq_len(R_IN), function(r)
      tryCatch(one_split(db, crit, ps, trt, tm, st, tau, p, bits),
               error = function(e) NULL))
    rows <- rows[!vapply(rows, is.null, logical(1))]
    if (!length(rows)) return(NULL)
    A <- do.call(rbind, rows)
    list(m = colMeans(A, na.rm = TRUE),
         v = apply(A, 2, function(u) stats::var(u[is.finite(u)])),
         k = apply(A, 2, function(u) sum(is.finite(u))))
  }, 2L)
  outer <- outer[!vapply(outer, is.null, logical(1))]
  M <- do.call(rbind, lapply(outer, `[[`, "m"))
  V <- do.call(rbind, lapply(outer, `[[`, "v"))
  K <- do.call(rbind, lapply(outer, `[[`, "k"))
  saveRDS(list(M = M, V = V, K = K, B_OUT = nrow(M), R_IN = R_IN, MARGIN = MARGIN,
               tau = tau, time_var = tm, status_var = st),
          sprintf("analysis/out/threeway_nested_%s.rds", label))
  point <- M[1, ]; boot <- M[-1, , drop = FALSE]
  Vb <- V[-1, , drop = FALSE]; Kb <- K[-1, , drop = FALSE]
  say(sprintf("\n===== %s : %d outer x %d inner three-way splits =====", label, nrow(M), R_IN))
  for (nm in c("repro","reproM","front_sel","front_conf","front_test","best_holds",
               "n_domB","n_survive","n_domC")) {
    if (!(nm %in% colnames(boot))) next
    x <- boot[, nm]; x <- x[is.finite(x)]
    vt <- stats::var(x); u <- Vb[, nm]/pmax(Kb[, nm], 1); vm <- mean(u[is.finite(u)])
    ci <- stats::quantile(x, c(.025, .975))
    h <- floor(length(x)/2)
    mv <- if (h >= 20) max(abs(stats::quantile(x[seq_len(h)], c(.025,.975)) - ci)) else NA_real_
    say(sprintf("  %-11s %7.3f | SD tot %.3f (MC %.3f, outer %.3f) | 95%% [%.3f, %.3f] | half-vs-full %.3f",
                nm, point[nm], sqrt(vt), sqrt(vm), sqrt(max(vt - vm, 0)), ci[1], ci[2], mv))
  }
  invisible(M)
}

nested3(colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825, "colon")
nested3(rott_data(),  rott_criteria,  rott_ps,  "trt","dtime","death", 2555, "rott")
say("ALL DONE")
