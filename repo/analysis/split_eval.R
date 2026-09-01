source("analysis/_setup.R")
run <- function(tag, dat, crit, ps, trt, tm, st, tau, R) {
  prep <- tp_prepare(dat, crit, trt, tm, st, ps, tau = tau); fit <- tp_fit(prep)
  M <- tp_split_eval(prep, fit, R = R, cores = 2L)
  M <- M[stats::complete.cases(M), , drop = FALSE]
  g <- M[, "gap"]; ci <- quantile(g, c(.025,.975), names = FALSE)
  say(sprintf("[%s] R=%d  out-of-sample RMST gap (RMST-pick minus HR-pick):", tag, nrow(M)))
  say(sprintf("        mean %+.1f d   median %+.1f d   95%% [%+.1f, %+.1f]   P(gap>0) = %.3f",
      mean(g), median(g), ci[1], ci[2], mean(g > 0)))
  say(sprintf("        same protocol chosen in %.3f of splits", mean(M[,"same"])))
  saveRDS(M, sprintf("analysis/out/split_%s.rds", tag)); M
}
a <- run("colon", colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825, 500L)
b <- run("rotterdam", rott_data(), rott_criteria, rott_ps, "trt","dtime","death", 2555, 400L)
say("ALL DONE")
