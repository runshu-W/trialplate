## Reviewer major point 1. The data-driven protocol retains a SUBSET of the
## criteria, so its eligible set is a superset of the full protocol's by
## construction and P(more patients) cannot fall below P(the rule removes at
## least one non-redundant criterion). It is a removal-rate statistic, not a
## validation. The informative question is whether the rule's choice of WHICH
## criteria to drop beats dropping the same NUMBER at random.
##
## For every split we therefore run, alongside the rule, B random relaxations
## that remove exactly as many criteria as the rule did, scored on the same
## held-out half. If the rule is doing work, it should beat random on the
## hazard ratio. Whether it beats random on eligible count is the tautology
## test: it should NOT, because count is monotone in removals alone.
source("analysis/_setup.R")

BRAND <- as.integer(Sys.getenv("BRAND", "20"))

run <- function(dat, crit, ps, trt, tm, st, tau, R, frac, label, seed = 11) {
  set.seed(seed); d <- dat; n <- nrow(d); p <- length(crit); full <- seq_len(p)
  res <- .tp_lapply(seq_len(R), function(r) {
    set.seed(seed * 1000 + r)
    idx <- sample(n, floor(frac * n))
    fit <- tp_prepare(d[idx, , drop = FALSE],  crit, trt, tm, st, ps, tau = tau)
    sc  <- tp_prepare(d[-idx, , drop = FALSE], crit, trt, tm, st, ps, tau = tau)
    V <- tp_enumerate(fit); if (any(V[, "feasible"] == 0)) return(NULL)
    S <- which(tp_shapley(V, p, 1L) < 0)
    k <- p - length(S)                       # how many the rule dropped
    b <- tp_value(sc, full)
    a <- tp_value(sc, S)
    if (!a["feasible"] || !b["feasible"]) return(NULL)
    ## B random relaxations dropping exactly k criteria
    rn <- rh <- numeric(0)
    if (k > 0) for (bb in seq_len(BRAND)) {
      Sr <- sort(sample(full, p - k))
      v  <- tp_value(sc, Sr)
      if (v["feasible"] == 1) { rn <- c(rn, exp(v["logN"])); rh <- c(rh, exp(v["logHR"])) }
    }
    c(k = k,
      n_rule = unname(exp(a["logN"])),  hr_rule = unname(exp(a["logHR"])),
      n_full = unname(exp(b["logN"])),  hr_full = unname(exp(b["logHR"])),
      n_rand = if (length(rn)) mean(rn) else NA_real_,
      hr_rand = if (length(rh)) mean(rh) else NA_real_,
      ## does the rule beat the median random relaxation of the same size?
      beat_n  = if (length(rn)) mean(exp(a["logN"])  > rn) else NA_real_,
      beat_hr = if (length(rh)) mean(exp(a["logHR"]) < rh) else NA_real_)
  }, 2L)
  M <- do.call(rbind, res[!vapply(res, is.null, logical(1))])
  say(sprintf("\n== %s ==  R = %d, %d random relaxations per split", label, nrow(M), BRAND))
  say(sprintf("  criteria dropped by the rule           : mean %.2f of %d", mean(M[,"k"]), p))
  say(sprintf("  P(rule admits more than FULL)          : %.3f   <- monotone, the tautology",
              mean(M[,"n_rule"] > M[,"n_full"])))
  say(sprintf("  P(rule admits more than RANDOM same-k) : %.3f   <- rule vs random on count",
              mean(M[,"beat_n"], na.rm = TRUE)))
  say(sprintf("  P(rule beats RANDOM same-k on HR)      : %.3f   <- rule vs random on effect",
              mean(M[,"beat_hr"], na.rm = TRUE)))
  say(sprintf("  mean eligible : full %.0f | rule %.0f | random %.0f",
              mean(M[,"n_full"]), mean(M[,"n_rule"]), mean(M[,"n_rand"], na.rm=TRUE)))
  say(sprintf("  mean HR       : full %.4f | rule %.4f | random %.4f",
              mean(M[,"hr_full"]), mean(M[,"hr_rule"]), mean(M[,"hr_rand"], na.rm=TRUE)))
  M
}

out <- list()
out$colon <- run(colon_data(), colon_criteria, colon_ps, "trt","time","status",   1825, 300, 0.5, "colon")
saveRDS(out, "analysis/out/random_benchmark.rds")
out$rott  <- run(rott_data(),  rott_criteria,  rott_ps,  "trt","rtime","death",   1825, 250, 0.5, "Rotterdam")
saveRDS(out, "analysis/out/random_benchmark.rds")
say("ALL DONE")
