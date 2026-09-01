## Reviewer round 2, major point 1. The previous version of this script
## bootstrapped the cohort and then split the RESAMPLED rows. Because a
## bootstrap resample contains duplicate copies of the same patient, two copies
## of one patient could land on opposite sides of the inner split, so the
## "scoring" half was not free of the patients used for fitting. That breaks the
## out-of-sample property and would tend to make the rule look more stable than
## it is. The reviewer was right and the results below are recomputed.
##
## The fix: every row carries the identifier of the patient it was drawn from,
## the inner split is taken over UNIQUE identifiers, and all copies of a patient
## follow their identifier to one side. No patient contributes to both halves.
##
## Design, stated explicitly because the reviewer asked:
##   outer  B_OUT bootstrap resamples of the cohort (b = 1 is the observed data)
##   inner  R_IN  stratified splits within each resample
##   the inner mean estimates that resample's probability, with binomial Monte
##     Carlo error R_IN^-1/2; the variance ACROSS resamples contains both that
##     Monte Carlo term and the genuine between-cohort variance, so we subtract
##     the former to report the between-cohort component separately
##   intervals are percentile intervals of the outer distribution; we do not use
##     BCa here because the statistic is a proportion of proportions and the
##     acceleration estimate is unstable at this outer count
source("analysis/_setup.R")

B_OUT <- as.integer(Sys.getenv("BOUT", "80"))
R_IN  <- as.integer(Sys.getenv("RIN",  "20"))

## split UNIQUE ids, stratified by arm and event status, then take all rows of
## the chosen ids
strat_split_ids <- function(d, trt, st, frac) {
  first <- !duplicated(d$.oid)
  key   <- interaction(d[[trt]][first], d[[st]][first], drop = TRUE)
  ids   <- d$.oid[first]
  pick  <- unlist(lapply(split(ids, key), function(v)
    if (length(v) < 2) v else sample(v, max(1, floor(frac * length(v))))))
  which(d$.oid %in% pick)
}

nested <- function(dat, crit, ps, trt, tm, st, tau, label, frac = 0.5, seed = 3) {
  set.seed(seed); n <- nrow(dat); p <- length(crit); full <- seq_len(p)
  dat$.oid <- seq_len(n)                       # identity of the source patient
  outer <- .tp_lapply(seq_len(B_OUT), function(b) {
    set.seed(seed * 977 + b)
    db <- if (b == 1L) dat else dat[sample(n, n, replace = TRUE), , drop = FALSE]
    hits <- t(vapply(seq_len(R_IN), function(r) {
      ix <- strat_split_ids(db, trt, st, frac)
      if (!length(ix) || length(ix) == nrow(db)) return(c(NA_real_, NA_real_))
      fitd <- db[ix, , drop = FALSE]; scd <- db[-ix, , drop = FALSE]
      stopifnot(length(intersect(fitd$.oid, scd$.oid)) == 0)   # no leakage
      fit <- tp_prepare(fitd, crit, trt, tm, st, ps, tau = tau)
      sc  <- tp_prepare(scd,  crit, trt, tm, st, ps, tau = tau)
      V <- tryCatch(tp_enumerate(fit), error = function(e) NULL)
      if (is.null(V) || any(V[, "feasible"] == 0)) return(c(NA_real_, NA_real_))
      S <- which(tp_shapley(V, p, 1L) < 0)
      a <- tp_value(sc, S); b2 <- tp_value(sc, full)
      if (a["feasible"] != 1 || b2["feasible"] != 1) return(c(NA_real_, NA_real_))
      c(as.numeric(a["logN"] > b2["logN"]), as.numeric(a["logHR"] < b2["logHR"]))
    }, numeric(2)))
    c(colMeans(hits, na.rm = TRUE), n_ok = sum(stats::complete.cases(hits)))
  }, 2L)
  M <- do.call(rbind, outer); M <- M[stats::complete.cases(M[, 1:2]), , drop = FALSE]
  point <- M[1, 1:2]; boot <- M[-1, 1:2, drop = FALSE]
  say(sprintf("\n===== %s : %d outer x %d inner, split by patient id =====",
              label, nrow(boot) + 1L, R_IN))
  nm <- c("P(more eligible)", "P(lower hazard ratio)")
  out <- list(point = point, boot = boot, B_OUT = nrow(boot) + 1L, R_IN = R_IN)
  for (j in 1:2) {
    p_hat <- mean(boot[, j])
    v_tot <- stats::var(boot[, j])                 # across-resample variance
    v_mc  <- p_hat * (1 - p_hat) / R_IN            # inner Monte Carlo component
    v_bet <- max(v_tot - v_mc, 0)                  # between-cohort component
    se_naive <- sqrt(point[j] * (1 - point[j]) / (R_IN * (nrow(boot) + 1L)))
    ci <- stats::quantile(boot[, j], c(.025, .975))
    say(sprintf("  %-22s point %.3f | naive SE %.4f | total SD %.4f (MC %.4f, between-cohort %.4f) | 95%% percentile CI [%.3f, %.3f]",
                nm[j], point[j], se_naive, sqrt(v_tot), sqrt(v_mc), sqrt(v_bet), ci[1], ci[2]))
    out[[c("more","lower")[j]]] <- list(point = unname(point[j]), sd_total = sqrt(v_tot),
      sd_mc = sqrt(v_mc), sd_between = sqrt(v_bet), se_naive = unname(se_naive),
      ci = unname(ci), inflation = unname(sqrt(v_tot) / se_naive))
  }
  out
}

res <- list()
res$colon <- nested(colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825, "colon")
saveRDS(res, "analysis/out/split_dependence.rds")
res$rott  <- nested(rott_data(),  rott_criteria,  rott_ps,  "trt","dtime","death", 2555, "Rotterdam")
saveRDS(res, "analysis/out/split_dependence.rds")
say("ALL DONE")
