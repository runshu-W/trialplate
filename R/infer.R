## trialplate :: inference ------------------------------------------------------
## B = 2000 percentile-of-2.5% endpoints need this many; BCa corrects the bias
## and skewness that a plain percentile interval ignores. Significance bands come
## from INTERVAL INVERSION (the smallest alpha at which the BCa interval excludes
## zero) rather than from a home-made p-value, and are then BH-adjusted across
## the pair family with logically-determined cells removed first.

## Parallel backend. mclapply forks, so it is unavailable on Windows; when
## future.apply is installed it is used instead and works everywhere. Bootstrap
## indices are always drawn SERIALLY before dispatch, so results are reproducible
## from the seed under either backend.
.tp_lapply <- function(X, FUN, cores) {
  if (cores <= 1L) return(lapply(X, FUN))
  if (requireNamespace("future.apply", quietly = TRUE) &&
      requireNamespace("future", quietly = TRUE)) {
    op <- future::plan(future::multisession, workers = cores)
    on.exit(future::plan(op), add = TRUE)
    return(future.apply::future_lapply(X, FUN, future.seed = NULL))
  }
  if (.Platform$OS.type == "windows") {
    warning("cores > 1 needs future.apply on Windows; running serially")
    return(lapply(X, FUN))
  }
  parallel::mclapply(X, FUN, mc.cores = cores)
}
## one replicate -> only the Shapley summaries, never the 2^p value matrix
.tp_summ <- function(prep) {
  V <- tp_enumerate(prep); p <- prep$p
  list(phi = vapply(OUTCOMES, function(k) tp_shapley(V, p, k), numeric(p)),
       I   = vapply(OUTCOMES, function(k) tp_interaction(V, p, k), matrix(0, p, p)),
       ok  = all(V[, "feasible"] == 1))
}
.reindex <- function(prep, ii) {
  q <- prep
  q$d <- prep$d[ii, , drop = FALSE]; q$E <- prep$E[ii, , drop = FALSE]
  q$X <- prep$X[ii, , drop = FALSE]; q$trt <- prep$trt[ii]
  q$time <- prep$time[ii]; q$status <- prep$status[ii]
  o <- order(q$time)                       # keep the sorted invariant
  q$E <- q$E[o, , drop = FALSE]; q$X <- q$X[o, , drop = FALSE]
  q$trt <- q$trt[o]; q$time <- q$time[o]; q$status <- q$status[o]
  q
}

## ---- nonparametric bootstrap ----------------------------------------------
tp_boot <- function(prep, B = 2000, cores = 2L, seed = 20260829) {
  set.seed(seed); n <- nrow(prep$E)
  idx <- lapply(seq_len(B), function(b) sample.int(n, n, replace = TRUE))  # serial => reproducible
  reps <- .tp_lapply(idx, function(ii) tryCatch(.tp_summ(.reindex(prep, ii)),
                                                error = function(e) NULL), cores)
  reps[!vapply(reps, is.null, logical(1))]
}
## ---- grouped (delete-one-group) jackknife for the BCa acceleration --------
## A full leave-one-out jackknife would need n enumerations; K groups need K.
tp_jack <- function(prep, K = 50L, cores = 2L, seed = 20260829) {
  set.seed(seed + 1L); n <- nrow(prep$E); g <- sample(rep_len(seq_len(K), n))
  reps <- .tp_lapply(seq_len(K), function(k) tryCatch(.tp_summ(.reindex(prep, which(g != k))),
                                                      error = function(e) NULL), cores)
  reps[!vapply(reps, is.null, logical(1))]
}

## ---- BCa interval and its inverted p-value --------------------------------
.bca_bounds <- function(t0, tb, tj, alpha) {
  tb <- tb[is.finite(tb)]; if (length(tb) < 50) return(c(NA, NA))
  z0 <- stats::qnorm(min(max(mean(tb < t0), 1/(2*length(tb))), 1 - 1/(2*length(tb))))
  tj <- tj[is.finite(tj)]; u <- mean(tj) - tj
  a <- if (length(tj) > 2 && sum(u^2) > 0) sum(u^3) / (6 * sum(u^2)^1.5) else 0
  za <- stats::qnorm(c(alpha/2, 1 - alpha/2))
  q  <- stats::pnorm(z0 + (z0 + za) / (1 - a * (z0 + za)))
  stats::quantile(tb, pmin(pmax(q, 0), 1), names = FALSE, na.rm = TRUE)
}
## smallest alpha at which the BCa interval excludes 0 == an exact p-value
.bca_p <- function(t0, tb, tj) {
  ex <- function(al) { b <- .bca_bounds(t0, tb, tj, al)
                       is.finite(b[1]) && (b[1] > 0 || b[2] < 0) }
  if (!ex(0.999)) return(1)
  lo <- 1/max(length(tb), 2); if (ex(lo)) return(lo)
  a <- lo; b <- 0.999
  for (i in 1:40) { m <- (a + b)/2; if (ex(m)) b <- m else a <- m }
  b
}

## ---- assemble --------------------------------------------------------------
tp_summarise <- function(fit, boot, jack, level = 0.95, exclude = NULL) {
  p <- fit$p; al <- 1 - level; B <- length(boot)
  det <- if (is.null(exclude)) fit$impl$determined else exclude
  out <- list(names = fit$names, B = B, K = length(jack), determined = det)
  for (o in names(OUTCOMES)) {
    k <- match(o, names(OUTCOMES))
    pb <- vapply(boot, function(r) r$phi[, k], numeric(p))
    pj <- vapply(jack, function(r) r$phi[, k], numeric(p))
    ib <- vapply(boot, function(r) r$I[, , k], matrix(0, p, p))
    ij <- vapply(jack, function(r) r$I[, , k], matrix(0, p, p))
    ph <- fit[[paste0("phi_", o)]]; Ih <- fit[[paste0("I_", o)]]
    lo <- hi <- pv <- numeric(p)
    for (i in seq_len(p)) { b <- .bca_bounds(ph[i], pb[i, ], pj[i, ], al)
      lo[i] <- b[1]; hi[i] <- b[2]; pv[i] <- .bca_p(ph[i], pb[i, ], pj[i, ]) }
    Ilo <- Ihi <- Ip <- matrix(NA_real_, p, p)
    for (i in 1:(p-1)) for (j in (i+1):p) {
      b <- .bca_bounds(Ih[i,j], ib[i,j,], ij[i,j,], al)
      Ilo[i,j] <- Ilo[j,i] <- b[1]; Ihi[i,j] <- Ihi[j,i] <- b[2]
      Ip[i,j]  <- Ip[j,i]  <- .bca_p(Ih[i,j], ib[i,j,], ij[i,j,]) }
    ## BH across the pair family, logically-determined cells removed first
    up <- upper.tri(Ip); test <- up & !det
    q <- matrix(NA_real_, p, p); q[test] <- stats::p.adjust(Ip[test], "BH")
    q[lower.tri(q)] <- t(q)[lower.tri(q)]
    ## CRS: SUCRA analogue from the bootstrap rank distribution. Heuristic
    ## ordering aid, NOT an inferential quantity - see the design note.
    sgn <- if (o == "HR") 1 else -1     # larger phi_HR / more negative phi_RMST,phi_N = relax sooner
    R <- apply(sgn * pb, 2, function(v) rank(-v, na.last = "keep"))
    crs <- 100 * (p - rowMeans(R, na.rm = TRUE)) / (p - 1)
    crs_sd <- apply(R, 1, stats::sd, na.rm = TRUE) * 100 / (p - 1)
    out[[o]] <- list(phi = ph, phi_lo = lo, phi_hi = hi, phi_p = pv,
                     phi_q = stats::p.adjust(pv, "BH"),
                     I = Ih, I_lo = Ilo, I_hi = Ihi, I_p = Ip, I_q = q,
                     CRS = crs, CRS_sd = crs_sd, n_tested = sum(test))
  }
  out
}

## ---- global permutation test ----------------------------------------------
## One degree of freedom instead of 36-45 marginal tests: is the whole
## interaction matrix distinguishable from what treatment-label noise produces?
## Only defined for the benefit estimands - permuting treatment cannot change n.
tp_perm <- function(prep, fit, P = 500L, cores = 2L, seed = 20260829) {
  set.seed(seed + 2L); n <- nrow(prep$E)
  perms <- lapply(seq_len(P), function(i) sample.int(n))
  stat <- function(I, det) sqrt(sum(I[upper.tri(I) & !det]^2))
  det <- fit$impl$determined
  obs <- vapply(c("HR","RMST"), function(o) stat(fit[[paste0("I_", o)]], det), numeric(1))
  nul <- .tp_lapply(perms, function(pm) {
    q <- prep; q$trt <- prep$trt[pm]
    V <- tp_enumerate(q)
    vapply(c(HR = 1L, RMST = 2L), function(k) stat(tp_interaction(V, q$p, k), det), numeric(1))
  }, cores)
  nul <- do.call(cbind, nul)
  list(observed = obs, null = nul,
       p = setNames(vapply(seq_along(obs), function(i)
         (1 + sum(nul[i, ] >= obs[i])) / (ncol(nul) + 1), numeric(1)), names(obs)))
}

## ---- paired frontier disagreement -----------------------------------------
## The headline claim is a PAIRED quantity: within one resample, do the two
## estimands pick the same protocol? Marginal summaries (e.g. a rank correlation
## between the two phi vectors) compound two large sampling errors and are
## uninformative; differencing inside a resample cancels the shared noise.
tp_picks <- function(V, n_floor) {
  ok <- V[, "feasible"] == 1
  n <- exp(V[ok, "logN"]); hr <- exp(V[ok, "logHR"]); rm <- V[ok, "rmstD"]
  el <- n >= n_floor
  if (!any(el)) return(c(same = NA, n_hr = NA, n_rm = NA, rm_hr = NA, rm_rm = NA,
                         hr_hr = NA, hr_rm = NA))
  a <- which(el)[which.min(hr[el])]; b <- which(el)[which.max(rm[el])]
  key <- which(ok)                       # map back to the 1..2^p subset index
  c(same = as.numeric(a == b), n_hr = n[a], n_rm = n[b],
    rm_hr = rm[a], rm_rm = rm[b], hr_hr = hr[a], hr_rm = hr[b],
    id_hr = key[a], id_rm = key[b])      # subset IDENTITY, needed for the
                                         # within-estimand stability control
}
tp_boot_frontier <- function(prep, fit, B = 400L, cores = 2L, seed = 20260829) {
  n_floor <- exp(fit$v_full["logN"])
  set.seed(seed + 3L); nn <- nrow(prep$E)
  idx <- lapply(seq_len(B), function(i) sample.int(nn, nn, TRUE))
  M <- do.call(rbind, .tp_lapply(idx, function(ii)
    tryCatch(tp_picks(tp_enumerate(.reindex(prep, ii)), n_floor),
             error = function(e) rep(NA_real_, 9)), cores))
  M[stats::complete.cases(M), , drop = FALSE]
}
tp_frontier_report <- function(M, tag = "") {
  cat(sprintf("\n--- %s (B = %d) ---\n", tag, nrow(M)))
  cat(sprintf("  P(two estimands pick the SAME protocol) = %.3f\n", mean(M[,"same"])))
  cat(sprintf("  P(RMST pick admits more patients)       = %.3f\n", mean(M[,"n_rm"] > M[,"n_hr"])))
  d <- M[,"rm_rm"] - M[,"rm_hr"]
  cat(sprintf("  RMST forgone by picking on HR: median %.1f d (IQR %.1f-%.1f)\n",
              median(d), quantile(d,.25), quantile(d,.75)))
  cat(sprintf("  median n: HR pick %.0f, RMST pick %.0f\n",
              median(M[,"n_hr"]), median(M[,"n_rm"])))
  invisible(NULL)
}


## ---- negative control for the disagreement claim ---------------------------
## "The two estimands pick different protocols 91.5% of the time" is only
## informative if the pick is otherwise STABLE. If one estimand also fails to
## reproduce its own choice across two independent resamples, the between-
## estimand disagreement carries no information. Compare:
##   between-estimand : P(HR pick == RMST pick)  within one resample
##   within-estimand  : P(HR pick == HR pick)    across two resamples
tp_stability <- function(M, pairs = 20000L, seed = 20260829) {
  set.seed(seed + 4L); B <- nrow(M)
  i <- sample.int(B, pairs, TRUE); j <- sample.int(B, pairs, TRUE)
  k <- i != j
  c(between      = mean(M[, "same"]),
    within_HR    = mean(M[i[k], "id_hr"] == M[j[k], "id_hr"]),
    within_RMST  = mean(M[i[k], "id_rm"] == M[j[k], "id_rm"]),
    n_distinct_HR   = length(unique(M[, "id_hr"])),
    n_distinct_RMST = length(unique(M[, "id_rm"])),
    B = B)
}

## ---- out-of-sample protocol evaluation ------------------------------------
## tp_boot_frontier compares the HR-optimal and RMST-optimal protocols INSIDE the
## sample that chose them. That comparison is rigged: the RMST-optimal protocol
## maximises RMST there by construction, so the gap is guaranteed positive and
## measures the optimisation (winner's-curse) gap, not a difference between the
## estimands. tp_stability makes the problem concrete - on colon a single
## estimand reproduces its own pick in only 3.6% of resamples, LESS often than
## the two estimands agree with each other (10.6%).
##
## The fix: select the protocol on one split, score it on the other, so both
## candidates are evaluated on data that had no part in choosing them.
tp_split_eval <- function(prep, fit, R = 400L, frac = 0.5, cores = 2L, seed = 20260829) {
  keep_frac <- exp(fit$v_full["logN"]) / nrow(prep$E)   # size constraint, as a fraction
  p <- prep$p; bits <- bitwShiftL(1L, 0:(p - 1))
  set.seed(seed + 5L); nn <- nrow(prep$E)
  idx <- lapply(seq_len(R), function(i) sample.int(nn, floor(frac * nn)))
  do.call(rbind, .tp_lapply(idx, function(tr) tryCatch({
    te <- setdiff(seq_len(nn), tr)
    Ptr <- .reindex(prep, tr); Pte <- .reindex(prep, te)
    Vtr <- tp_enumerate(Ptr)
    el <- Vtr[, "feasible"] == 1 & exp(Vtr[, "logN"]) >= keep_frac * length(tr)
    if (!any(el)) return(rep(NA_real_, 6))
    a <- which(el)[which.min(Vtr[el, "logHR"])]      # protocol chosen on HR
    b <- which(el)[which.max(Vtr[el, "rmstD"])]      # protocol chosen on RMST
    ev <- function(k) tp_value(Pte, which(bitwAnd(k - 1L, bits) > 0))
    va <- ev(a); vb <- ev(b)
    c(same = as.numeric(a == b), rmst_hr = unname(va["rmstD"]), rmst_rm = unname(vb["rmstD"]),
      hr_hr = unname(exp(va["logHR"])), hr_rm = unname(exp(vb["logHR"])),
      gap = unname(vb["rmstD"] - va["rmstD"]))       # > 0 = RMST-selection genuinely wins
  }, error = function(e) rep(NA_real_, 6)), cores))
}

## ---- out-of-sample test of the published selection RULE --------------------
## The argmax over all 2^p protocols is a harsher selection than Trial
## Pathfinder actually performs, so a failure there does not indict the
## published method. Its rule is milder: keep every criterion whose Shapley
## value on the log hazard ratio is negative, relax the rest. That rule is
## tested here the way it would have to be used - fitted on one split, scored on
## the other - against the original full protocol.
tp_rule_eval <- function(prep, R = 400L, frac = 0.5, cores = 2L, seed = 20260829) {
  p <- prep$p; bits <- bitwShiftL(1L, 0:(p - 1)); full <- seq_len(p)
  set.seed(seed + 6L); nn <- nrow(prep$E)
  idx <- lapply(seq_len(R), function(i) sample.int(nn, floor(frac * nn)))
  do.call(rbind, .tp_lapply(idx, function(tr) tryCatch({
    Ptr <- .reindex(prep, tr); Pte <- .reindex(prep, setdiff(seq_len(nn), tr))
    Vtr <- tp_enumerate(Ptr)
    if (any(Vtr[, "feasible"] == 0)) return(rep(NA_real_, 8))
    phiHR <- tp_shapley(Vtr, p, 1L)
    keepHR <- which(phiHR < 0)                     # Trial Pathfinder's rule
    phiRM  <- tp_shapley(Vtr, p, 2L)
    keepRM <- which(phiRM > 0)                     # the same rule on absolute benefit
    ev <- function(S) tp_value(Pte, S)
    o <- ev(full); a <- ev(keepHR); b <- ev(keepRM)
    c(n_full = exp(o["logN"]), hr_full = exp(o["logHR"]), rm_full = o["rmstD"],
      n_hr   = exp(a["logN"]), hr_hr   = exp(a["logHR"]), rm_hr   = a["rmstD"],
      n_rm   = exp(b["logN"]), hr_rm   = exp(b["logHR"]))
  }, error = function(e) rep(NA_real_, 8)), cores))
}
