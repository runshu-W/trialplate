## W5-b  The training-size curve predicts what the real cohorts should give at a
## different split. Test that prediction: frac = 0.7 puts colon's training set at
## 433 and rotterdam's at 2087, which the curve maps to roughly 0.32 and 0.62.
source("analysis/_setup.R")
run <- function(tag, dat, crit, ps, trt, tm, st, tau, R, fr) {
  prep <- tp_prepare(dat, crit, trt, tm, st, ps, tau = tau)
  M <- tp_rule_eval(prep, R = R, frac = fr, cores = 2L)
  M <- M[complete.cases(M), , drop = FALSE]; cn <- colnames(M)
  g <- function(k) M[, grep(k, cn, fixed = TRUE)[1]]
  say(sprintf("[%s frac=%.1f] n_train=%d R=%d | P(lower HR)=%.3f  P(more n)=%.3f  dHR %+.4f",
      tag, fr, floor(fr*nrow(prep$E)), nrow(M),
      mean(g("hr_hr") - g("hr_full") < 0), mean(g("n_hr") - g("n_full") > 0),
      mean(g("hr_hr") - g("hr_full"))))
  saveRDS(M, sprintf("analysis/out/rule_%s_f%02d.rds", tag, round(fr*10)))
}
run("colon", colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825, 500L, 0.7)
run("rotterdam", rott_data(), rott_criteria, rott_ps, "trt","dtime","death", 2555, 400L, 0.7)
say("ALL DONE")
