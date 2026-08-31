## Reviewer round 3, major point 7. At matched inclusiveness the rule has a modest
## advantage on the hazard ratio and none on the restricted mean difference, while
## the paper separately argues that hazard-ratio movement need not correspond to
## any individual's benefit. Saying the rule's "contribution is to the effect
## estimate" is therefore too broad. Two additions.
##
##   (a) The count-versus-RMST frontier alongside the count-versus-HR one, so the
##       absolute-benefit trade-off is reported on the same footing.
##   (b) A rule that selects on the RMST Shapley value instead of the log hazard
##       ratio, scored out of sample on both estimands. If the framework's value
##       is specific to the hazard ratio, the RMST-selected rule should not
##       inherit it, and an investigator who cares about absolute benefit should
##       know that before adopting either.
source("analysis/_setup.R")

run <- function(dat, crit, ps, trt, tm, st, tau, R, label, seed = 23) {
  set.seed(seed); n <- nrow(dat); p <- length(crit); full <- seq_len(p)
  bits <- bitwShiftL(1L, 0:(p - 1))
  res <- .tp_lapply(seq_len(R), function(r) {
    set.seed(seed * 1000 + r)
    ix <- sample(n, floor(0.5 * n))
    fit <- tp_prepare(dat[ix, , drop=FALSE],  crit, trt, tm, st, ps, tau = tau)
    sc  <- tp_prepare(dat[-ix, , drop=FALSE], crit, trt, tm, st, ps, tau = tau)
    Vf <- tryCatch(tp_enumerate(fit), error = function(e) NULL)
    if (is.null(Vf) || any(Vf[, "feasible"] == 0)) return(NULL)
    ## the published rule selects on the log hazard ratio (column 1);
    ## the alternative selects on the restricted mean difference (column 2),
    ## where a criterion worth keeping RAISES the difference, so the sign flips
    S_hr <- which(tp_shapley(Vf, p, 1L) < 0)
    S_rm <- which(tp_shapley(Vf, p, 2L) > 0)
    Vs <- tryCatch(tp_enumerate(sc), error = function(e) NULL); if (is.null(Vs)) return(NULL)
    ok <- Vs[, "feasible"] == 1
    N <- exp(Vs[, "logN"]); H <- Vs[, "logHR"]; RM <- Vs[, "rmstD"]
    kH <- sum(bits[S_hr]) + 1L; kM <- sum(bits[S_rm]) + 1L; kF <- sum(bits[full]) + 1L
    if (!ok[kH] || !ok[kM] || !ok[kF]) return(NULL)
    c(same_set = as.numeric(setequal(S_hr, S_rm)),
      n_hr = N[kH], n_rm = N[kM], n_full = N[kF],
      hr_of_hrrule = exp(H[kH]), hr_of_rmrule = exp(H[kM]), hr_full = exp(H[kF]),
      rm_of_hrrule = RM[kH], rm_of_rmrule = RM[kM], rm_full = RM[kF],
      hrrule_lowerHR = as.numeric(H[kH] < H[kF]),
      hrrule_moreRM  = as.numeric(RM[kH] > RM[kF]),
      rmrule_lowerHR = as.numeric(H[kM] < H[kF]),
      rmrule_moreRM  = as.numeric(RM[kM] > RM[kF]))
  }, 2L)
  M <- do.call(rbind, res[!vapply(res, is.null, logical(1))])
  ci <- function(x) { x <- x[is.finite(x)]
    q <- replicate(2000, mean(sample(x, replace=TRUE)))
    sprintf("%.3f [%.3f, %.3f]", mean(x), quantile(q,.025), quantile(q,.975)) }
  say(sprintf("\n===== %s : %d splits =====", label, nrow(M)))
  say(sprintf("  the two rules select the same criterion set : %s", ci(M[,"same_set"])))
  say(sprintf("  eligible: full %.0f | HR-rule %.0f | RMST-rule %.0f",
      mean(M[,"n_full"]), mean(M[,"n_hr"]), mean(M[,"n_rm"])))
  say(sprintf("  HR-selected rule   : P(lower HR) %s | P(more RMST) %s",
      ci(M[,"hrrule_lowerHR"]), ci(M[,"hrrule_moreRM"])))
  say(sprintf("  RMST-selected rule : P(lower HR) %s | P(more RMST) %s",
      ci(M[,"rmrule_lowerHR"]), ci(M[,"rmrule_moreRM"])))
  say(sprintf("  mean out-of-sample HR   : full %.4f | HR-rule %.4f | RMST-rule %.4f",
      mean(M[,"hr_full"]), mean(M[,"hr_of_hrrule"]), mean(M[,"hr_of_rmrule"])))
  say(sprintf("  mean out-of-sample RMST : full %+.2f | HR-rule %+.2f | RMST-rule %+.2f",
      mean(M[,"rm_full"]), mean(M[,"rm_of_hrrule"]), mean(M[,"rm_of_rmrule"])))
  M
}
out <- list()
out$colon <- run(colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825, 300, "colon")
saveRDS(out, "analysis/out/rmst_rule.rds")
out$rott  <- run(rott_data(),  rott_criteria,  rott_ps,  "trt","rtime","death", 1825, 250, "Rotterdam")
saveRDS(out, "analysis/out/rmst_rule.rds")
say("ALL DONE")
