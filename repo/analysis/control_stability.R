source("analysis/_setup.R")
run <- function(tag, dat, crit, ps, trt, tm, st, tau, B) {
  prep <- tp_prepare(dat, crit, trt, tm, st, ps, tau = tau); fit <- tp_fit(prep)
  M <- tp_boot_frontier(prep, fit, B = B, cores = 2L)
  s <- tp_stability(M)
  say(sprintf("[%s] between %.3f | within-HR %.3f | within-RMST %.3f | distinct picks %d / %d of %d",
      tag, s["between"], s["within_HR"], s["within_RMST"],
      s["n_distinct_HR"], s["n_distinct_RMST"], nrow(M)))
  list(M = M, s = s)
}
a <- run("colon", colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825, 500L)
saveRDS(a, "analysis/out/ctrl_colon.rds")
b <- run("rotterdam", rott_data(), rott_criteria, rott_ps, "trt","dtime","death", 2555, 400L)
saveRDS(b, "analysis/out/ctrl_rott.rds"); say("ALL DONE")
