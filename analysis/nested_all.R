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
##
## Reviewer round 4, major point 5. The inner Monte Carlo variance was taken as
## p(1-p)/R. That is the right formula only for a statistic that is 0/1 within a
## split, which "more eligible", "lower HR" and the frontier indicators are, but
## the matched statistics are not: within one split the matched rank is already a
## proportion over comparators, so p(1-p)/R overstates its Monte Carlo component
## and the outer-sampling component obtained by subtraction is understated. We now
## record the sample variance of the per-split values inside each resample and use
##     V_MC = mean_b ( s^2_b / R_b ),
## which reduces to the binomial formula for the 0/1 statistics and is correct for
## the others. Endpoint convergence is reported for every statistic, not just one.
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
  ## round 4, major 6: the RMST-selected variant is carried through the same
  ## resampling so its out-of-sample metrics get patient-level intervals rather
  ## than an interval bootstrapped across splits that share patients
  S2 <- which(tp_shapley(Vf, p, 2L) > 0)
  Vs <- tryCatch(tp_enumerate(sc), error = function(e) NULL)
  if (is.null(Vs)) return(NULL)
  ok <- Vs[, "feasible"] == 1
  N <- exp(Vs[, "logN"]); H <- Vs[, "logHR"]; RM <- Vs[, "rmstD"]
  kR <- sum(bits[S]) + 1L; kF <- sum(bits[full]) + 1L; kM <- sum(bits[S2]) + 1L
  if (!ok[kR] || !ok[kF] || !ok[kM]) return(NULL)
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
  out["rm_same"]        <- as.numeric(setequal(S, S2))
  out["rmrule_more"]    <- as.numeric(N[kM] > N[kF])
  out["rmrule_lower"]   <- as.numeric(H[kM] < H[kF])
  out["rmrule_greater"] <- as.numeric(RM[kM] > RM[kF])
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
    A <- do.call(rbind, rows)
    ## per-resample mean, the sample variance of the per-split values, and the
    ## number of usable splits behind each column
    list(m  = colMeans(A, na.rm = TRUE),
         v  = apply(A, 2, function(u) stats::var(u[is.finite(u)])),
         k  = apply(A, 2, function(u) sum(is.finite(u))))
  }, 2L)
  outer <- outer[!vapply(outer, is.null, logical(1))]
  M <- do.call(rbind, lapply(outer, `[[`, "m"))
  V <- do.call(rbind, lapply(outer, `[[`, "v"))
  K <- do.call(rbind, lapply(outer, `[[`, "k"))
  saveRDS(list(M = M, V = V, K = K, B_OUT = nrow(M), R_IN = R_IN,
               BANDS = BANDS, MARGIN = MARGIN,
               tau = tau, time_var = tm, status_var = st),
          sprintf("analysis/out/nested_%s.rds", label))
  point <- M[1, ]; boot <- M[-1, , drop = FALSE]
  Vb <- V[-1, , drop = FALSE]; Kb <- K[-1, , drop = FALSE]
  ## inner Monte Carlo variance of a resample mean, averaged over resamples
  vmc <- function(nm) { u <- Vb[, nm] / pmax(Kb[, nm], 1); mean(u[is.finite(u)]) }
  say(sprintf("\n===== %s : %d outer x %d inner, split by patient id =====", label, nrow(M), R_IN))
  rep1 <- function(nm, lab) {
    if (!(nm %in% colnames(boot))) return(invisible())
    x <- boot[, nm]; x <- x[is.finite(x)]
    v_tot <- stats::var(x)
    v_mc <- vmc(nm); v_out <- max(v_tot - v_mc, 0)
    ci <- stats::quantile(x, c(.025, .975))
    say(sprintf("  %-22s %.3f | SD tot %.3f (MC %.3f, outer-sampling %.3f) | 95%% [%.3f, %.3f]",
                lab, point[nm], sqrt(v_tot), sqrt(v_mc), sqrt(v_out), ci[1], ci[2]))
  }
  rep1("more", "P(more eligible)"); rep1("lower", "P(lower HR)")
  for (b in BANDS) rep1(paste0("rank_hr_", b), sprintf("matched HR, band %.0f%%", 100*b))
  for (b in BANDS) rep1(paste0("rank_rm_", b), sprintf("matched RMST, band %.0f%%", 100*b))
  rep1("front_hr", "on count/HR frontier"); rep1("front_rm", "on count/RMST frontier")
  rep1("front_hrM", sprintf("on frontier, margin %.2f", MARGIN))
  rep1("rm_same", "RMST rule picks same set"); rep1("rmrule_more", "RMST rule: P(more)")
  rep1("rmrule_lower", "RMST rule: P(lower HR)")
  rep1("rmrule_greater", "RMST rule: P(greater RMST)")
  say(sprintf("  matched comparators per split : %s",
      paste(sprintf("%.0f%%:%.0f", 100*BANDS,
            vapply(BANDS, function(b) point[paste0("nmatch_", b)], numeric(1))), collapse="  ")))
  say(sprintf("  comparator count skew vs rule : %s",
      paste(sprintf("%.0f%%:%+.3f", 100*BANDS,
            vapply(BANDS, function(b) point[paste0("skew_", b)], numeric(1))), collapse="  ")))
  say(sprintf("  subsets dominating: %.0f plain, %.0f with margin", point["n_dom"], point["n_domM"]))
  ## endpoint stability: recompute each interval from growing subsets of the draws
  say("  percentile-endpoint stability (first k resamples):")
  conv <- c("more","lower","front_hr","front_rm","front_hrM",
            "rm_same","rmrule_more","rmrule_lower","rmrule_greater",
            paste0("rank_hr_", BANDS), paste0("rank_rm_", BANDS))
  ks <- unique(c(50, 100, floor(nrow(boot)/2), nrow(boot)))
  ks <- ks[ks >= 25 & ks <= nrow(boot)]
  for (nm in conv) {
    if (!(nm %in% colnames(boot))) next
    xs <- boot[, nm]
    ss <- vapply(ks, function(k) {
      q <- stats::quantile(xs[seq_len(k)][is.finite(xs[seq_len(k)])], c(.025, .975))
      sprintf("k=%d [%.3f, %.3f]", k, q[1], q[2]) }, character(1))
    say(sprintf("    %-14s %s", nm, paste(ss, collapse = "  ")))
  }
  ## largest movement of either endpoint between half and full outer count
  mv <- vapply(conv, function(nm) {
    if (!(nm %in% colnames(boot))) return(NA_real_)
    h <- floor(nrow(boot)/2); if (h < 25) return(NA_real_)
    a <- stats::quantile(boot[seq_len(h), nm][is.finite(boot[seq_len(h), nm])], c(.025,.975))
    b <- stats::quantile(boot[, nm][is.finite(boot[, nm])], c(.025,.975))
    max(abs(a - b)) }, numeric(1))
  say(sprintf("  max endpoint movement, half vs full outer count: %.3f (%s)",
              max(mv, na.rm = TRUE), conv[which.max(mv)]))
  invisible(M)
}

nested(colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825, "colon")
nested(rott_data(),  rott_criteria,  rott_ps,  "trt","dtime","death", 2555, "rott")
say("ALL DONE")
