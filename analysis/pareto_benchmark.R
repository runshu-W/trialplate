## Reviewer round 2, major point 2. The previous benchmark matched the rule to
## random relaxations on the NUMBER of criteria removed, not on inclusiveness.
## Since the rule admitted 442 patients against random relaxation's 664 in
## Rotterdam, the hazard-ratio comparison was made at different eligible counts,
## and "beats random relaxation" conflates a genuine advantage with the fact
## that a smaller expansion moves the hazard ratio less. The reviewer is right.
##
## Three replacements, all scored out of sample on the half that took no part in
## the selection:
##   (1) MATCHED comparison. Among the 2^p subsets, keep those whose eligible
##       count on the scoring half is within +/-10% of the rule's, and ask how
##       the rule's hazard ratio ranks among them.
##   (2) PARETO frontier. A subset is dominated if another admits at least as
##       many patients AND achieves a hazard ratio at least as low. Report the
##       probability that the rule's choice is on the frontier, and its
##       dominance count.
##   (3) The same two on the restricted mean difference, since the frontier in
##       the absolute-benefit estimand need not agree.
source("analysis/_setup.R")

BAND <- 0.10                      # +/-10% eligible-count matching window

run <- function(dat, crit, ps, trt, tm, st, tau, R, frac, label, seed = 19) {
  set.seed(seed); n <- nrow(dat); p <- length(crit); full <- seq_len(p)
  bits <- bitwShiftL(1L, 0:(p - 1))
  res <- .tp_lapply(seq_len(R), function(r) {
    set.seed(seed * 1000 + r)
    ix <- sample(n, floor(frac * n))
    fit <- tp_prepare(dat[ix, , drop = FALSE],  crit, trt, tm, st, ps, tau = tau)
    sc  <- tp_prepare(dat[-ix, , drop = FALSE], crit, trt, tm, st, ps, tau = tau)
    Vf <- tryCatch(tp_enumerate(fit), error = function(e) NULL)
    if (is.null(Vf) || any(Vf[, "feasible"] == 0)) return(NULL)
    S <- which(tp_shapley(Vf, p, 1L) < 0)
    ## score EVERY subset on the held-out half: this is the achievable set
    Vs <- tp_enumerate(sc)
    ok <- Vs[, "feasible"] == 1
    N  <- exp(Vs[, "logN"]); H <- Vs[, "logHR"]; RM <- Vs[, "rmstD"]
    kR <- sum(bits[S]) + 1L; kF <- sum(bits[full]) + 1L
    if (!ok[kR] || !ok[kF]) return(NULL)
    nR <- N[kR]; hR <- H[kR]; rR <- RM[kR]
    ## (1) matched on eligible count
    m <- ok & abs(N - nR) <= BAND * nR
    m[kR] <- FALSE
    ## (2) Pareto: not dominated on (more patients, lower log HR)
    dom_hr <- any(ok & N >= nR & H <= hR & (N > nR | H < hR))
    dom_rm <- any(ok & N >= nR & RM >= rR & (N > nR | RM > rR))
    c(n_rule = nR, hr_rule = exp(hR),
      n_match = sum(m),
      rank_hr = if (sum(m)) mean(H[m] > hR) else NA_real_,   # share of matched it beats
      rank_rm = if (sum(m)) mean(RM[m] < rR) else NA_real_,
      on_frontier_hr = as.numeric(!dom_hr),
      on_frontier_rm = as.numeric(!dom_rm),
      n_dominating   = sum(ok & N >= nR & H <= hR & (N > nR | H < hR)),
      n_feasible     = sum(ok))
  }, 2L)
  M <- do.call(rbind, res[!vapply(res, is.null, logical(1))])
  bci <- function(x, B = 2000) { x <- x[is.finite(x)]
    q <- replicate(B, mean(sample(x, replace = TRUE)))
    sprintf("%.3f [%.3f, %.3f]", mean(x), quantile(q,.025), quantile(q,.975)) }
  say(sprintf("\n===== %s : %d splits, matched band +/-%.0f%% =====", label, nrow(M), 100*BAND))
  say(sprintf("  matched subsets available per split      : median %.0f of %.0f feasible",
              median(M[,"n_match"]), median(M[,"n_feasible"])))
  say(sprintf("  rule beats a MATCHED subset on log HR    : %s", bci(M[,"rank_hr"])))
  say(sprintf("  rule beats a MATCHED subset on RMST      : %s", bci(M[,"rank_rm"])))
  say(sprintf("  rule is ON the eligible-count/HR frontier: %s", bci(M[,"on_frontier_hr"])))
  say(sprintf("  rule is ON the count/RMST frontier       : %s", bci(M[,"on_frontier_rm"])))
  say(sprintf("  subsets dominating the rule              : median %.0f", median(M[,"n_dominating"])))
  M
}

out <- list()
out$colon <- run(colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825, 250, 0.5, "colon")
saveRDS(out, "analysis/out/pareto_benchmark.rds")
out$rott  <- run(rott_data(),  rott_criteria,  rott_ps,  "trt","rtime","death", 1825, 200, 0.5, "Rotterdam")
saveRDS(out, "analysis/out/pareto_benchmark.rds")
say("ALL DONE")
