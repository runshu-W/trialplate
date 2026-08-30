source("analysis/_setup.R")
run <- function(tag, dat, crit, ps, trt, tm, st, tau, R) {
  prep <- tp_prepare(dat, crit, trt, tm, st, ps, tau = tau)
  M <- tp_rule_eval(prep, R = R, cores = 2L); M <- M[complete.cases(M), , drop = FALSE]
  cn <- colnames(M)
  g <- function(k) M[, grep(k, cn, fixed = TRUE)[1]]
  dn  <- g("n_hr") - g("n_full"); dhr <- g("hr_hr") - g("hr_full"); drm <- g("rm_hr") - g("rm_full")
  se <- function(x) sd(x)/sqrt(length(x))
  say(sprintf("[%s] R=%d  Trial-Pathfinder rule vs the original protocol, OUT OF SAMPLE:", tag, nrow(M)))
  say(sprintf("   eligible n : %+.0f  (SE %.0f)   P(more patients) = %.3f", mean(dn), se(dn), mean(dn > 0)))
  say(sprintf("   hazard ratio: %+.4f (SE %.4f)   P(LOWER HR)      = %.3f", mean(dhr), se(dhr), mean(dhr < 0)))
  say(sprintf("   RMST diff   : %+.1f d (SE %.1f)  P(more benefit)  = %.3f", mean(drm), se(drm), mean(drm > 0)))
  saveRDS(M, sprintf("analysis/out/rule_%s.rds", tag)); invisible(M)
}
run("colon", colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825, 500L)
run("rotterdam", rott_data(), rott_criteria, rott_ps, "trt","dtime","death", 2555, 400L)
say("ALL DONE")
