## Reviewer round 3, major points 2 and 3. One nested resampling run that carries
## EVERY out-of-sample quantity, so the matched and frontier statistics get the
## same patient-level uncertainty as the two promises rather than an interval
## computed across splits that share patients.
##
## Two things the reviewer inferred that the previous code already did, and which
## we should have stated: the matched proportion is computed WITHIN each split and
## then averaged with equal weight across splits, never pooled over
## comparator-rule pairs; and the "between" component is
##     sqrt( SD_total^2 - SD_MC^2 ),
## a variance subtraction, not a subtraction of standard deviations. Both are now
## written out in the Methods. The part of the criticism that stands is that the
## interval was bootstrapped over splits, which reuse patients; it is now
## bootstrapped over patients, outside the split loop.
##
## Structure
##   outer  B bootstrap resamples of the cohort (b = 1 is the observed data)
##   inner  R stratified splits within each resample, split by unique patient id
##   per split: enumerate on the fitting half to get the rule, enumerate on the
##     scoring half to get every attainable subset, then compute all statistics
##   the component named "outer-sampling" below was called "between-cohort" in the
##     previous version; only one cohort is ever involved, so that name misled.
source("analysis/_setup.R")

B_OUT <- as.integer(Sys.getenv("BOUT", "150"))
R_IN  <- as.integer(Sys.getenv("RIN",  "25"))
BANDS <- c(0.02, 0.05, 0.10, 0.15)      # eligible-count matching tolerances
MARGIN <- 0.05                          # dominance must beat the rule's HR by this much

strat_split_ids <- function(d, trt, st, frac) {
  first <- !duplicated(d$.oid)
  key   <- interaction(d[[trt]][first], d[[st]][first], drop = TRUE)
  ids   <- d$.oid[first]
  pick  <- unlist(lapply(split(ids, key), function(v)
    if (length(v) < 2) v else sample(v, max(1, floor(frac * length(v))))))
  which(d$.oid %in% pick)
}

one_split <- function(db, crit, ps, trt, tm, st, tau, p, full, bits) {
  ix <- strat_split_ids(db, trt, st, 0.5)
  if (!length(ix) || length(ix) == nrow(db)) return(NULL)
  fitd <- db[ix, , drop = FALSE]; scd <- db[-ix, , drop = FALSE]
  if (length(intersect(fitd$.oid, scd$.oid))) stop("leak")
  fit <- tp_prepare(fitd, crit, trt, tm, st, ps, tau = tau)
  sc  <- tp_prepare(scd,  crit, trt, tm, st, ps, tau = tau)
  Vf <- tryCatch(tp_enumerate(fit), error = function(e) NULL)
  if (is.null(Vf) || any(Vf[, "feasible"] == 0)) return(NULL)
  S  <- which(tp_shapley(Vf, p, 1L) < 0)
  Vs <- tryCatch(tp_enumerate(sc), error = function(e) NULL)
  if (is.null(Vs)) return(NULL)
  ok <- Vs[, "feasible"] == 1
  N <- exp(Vs[, "logN"]); H <- Vs[, "logHR"]; RM <- Vs[, "rmstD"]
  kR <- sum(bits[S]) + 1L; kF <- sum(bits[full]) + 1L
  if (!ok[kR] || !ok[kF]) return(NULL)
  nR <- N[kR]; hR <- H[kR]; rR <- RM[kR]
  out <- c(more = as.numeric(N[kR] > N[kF]), lower = as.numeric(H[kR] < H[kF]))
  for (b in BANDS) {
    m <- ok & abs(N - nR) <= b * nR; m[kR] <- FALSE
    out[paste0("rank_hr_", b)] <- if (sum(m)) mean(H[m] > hR) else NA_real_
    out[paste0("rank_rm_", b)] <- if (sum(m)) mean(RM[m] < rR) else NA_real_
    out[paste0("nmatch_", b)]  <- sum(m)
    ## are the comparators sitting symmetrically around the rule's eligible count?
    out[paste0("skew_", b)]    <- if (sum(m)) mean((N[m] - nR) / nR) else NA_real_
  }
  dom  <- ok & N >= nR & H <= hR & (N > nR | H < hR)
  domM <- ok & N >= nR & H <= hR - MARGIN            # with a margin on the log HR
  domR <- ok & N >= nR & RM >= rR & (N > nR | RM > rR)
  out["front_hr"]  <- as.numeric(!any(dom))
  out["front_rm"]  <- as.numeric(!any(domR))
  out["front_hrM"] <- as.numeric(!any(domM))
  out["n_dom"]     <- sum(dom)
  out["n_domM"]    <- sum(domM)
  out
}

nested <- function(dat, crit, ps, trt, tm, st, tau, label, seed = 5) {
  set.seed(seed); n <- nrow(dat); p <- length(crit); full <- seq_len(p)
  bits <- bitwShiftL(1L, 0:(p - 1)); dat$.oid <- seq_len(n)
  outer <- .tp_lapply(seq_len(B_OUT), function(b) {
    set.seed(seed * 977 + b)
    db <- if (b == 1L) dat else dat[sample(n, n, replace = TRUE), , drop = FALSE]
    rows <- lapply(seq_len(R_IN), function(r)
      tryCatch(one_split(db, crit, ps, trt, tm, st, tau, p, full, bits),
               error = function(e) NULL))
    rows <- rows[!vapply(rows, is.null, logical(1))]
    if (!length(rows)) return(NULL)
    colMeans(do.call(rbind, rows), na.rm = TRUE)
  }, 2L)
  M <- do.call(rbind, outer[!vapply(outer, is.null, logical(1))])
  saveRDS(list(M = M, B_OUT = nrow(M), R_IN = R_IN, BANDS = BANDS, MARGIN = MARGIN),
          sprintf("analysis/out/nested_%s.rds", label))
  point <- M[1, ]; boot <- M[-1, , drop = FALSE]
  say(sprintf("\n===== %s : %d outer x %d inner, split by patient id =====", label, nrow(M), R_IN))
  rep1 <- function(nm, lab) {
    if (!(nm %in% colnames(boot))) return(invisible())
    x <- boot[, nm]; x <- x[is.finite(x)]
    v_tot <- stats::var(x); ph <- mean(x)
    v_mc <- ph * (1 - ph) / R_IN; v_out <- max(v_tot - v_mc, 0)
    ci <- stats::quantile(x, c(.025, .975))
    say(sprintf("  %-22s %.3f | SD tot %.3f (MC %.3f, outer-sampling %.3f) | 95%% [%.3f, %.3f]",
                lab, point[nm], sqrt(v_tot), sqrt(v_mc), sqrt(v_out), ci[1], ci[2]))
  }
  rep1("more", "P(more eligible)"); rep1("lower", "P(lower HR)")
  for (b in BANDS) rep1(paste0("rank_hr_", b), sprintf("matched HR, band %.0f%%", 100*b))
  for (b in BANDS) rep1(paste0("rank_rm_", b), sprintf("matched RMST, band %.0f%%", 100*b))
  rep1("front_hr", "on count/HR frontier"); rep1("front_rm", "on count/RMST frontier")
  rep1("front_hrM", sprintf("on frontier, margin %.2f", MARGIN))
  say(sprintf("  matched comparators per split : %s",
      paste(sprintf("%.0f%%:%.0f", 100*BANDS,
            vapply(BANDS, function(b) point[paste0("nmatch_", b)], numeric(1))), collapse="  ")))
  say(sprintf("  comparator count skew vs rule : %s",
      paste(sprintf("%.0f%%:%+.3f", 100*BANDS,
            vapply(BANDS, function(b) point[paste0("skew_", b)], numeric(1))), collapse="  ")))
  say(sprintf("  subsets dominating: %.0f plain, %.0f with margin", point["n_dom"], point["n_domM"]))
  ## endpoint stability: recompute the interval from growing subsets of the outer draws
  say("  percentile-endpoint stability for P(lower HR):")
  for (k in c(50, 100, nrow(boot))) {
    if (k > nrow(boot)) next
    q <- stats::quantile(boot[seq_len(k), "lower"], c(.025, .975))
    say(sprintf("    first %4d resamples -> [%.3f, %.3f]", k, q[1], q[2]))
  }
  invisible(M)
}

nested(colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825, "colon")
nested(rott_data(),  rott_criteria,  rott_ps,  "trt","rtime","death", 1825, "rott")
say("ALL DONE")
