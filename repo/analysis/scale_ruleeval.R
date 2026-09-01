## Does the HR-vs-log-HR choice move the headline numbers?
source("analysis/_setup.R")
run <- function(tag, dat, crit, ps, trt, tm, st, tau, R) {
  prep <- tp_prepare(dat, crit, trt, tm, st, ps, tau = tau)
  for (sc in c("log", "hr")) {
    M <- tp_rule_eval(prep, R = R, cores = 2L, scale = sc)
    M <- M[complete.cases(M), , drop = FALSE]; cn <- colnames(M)
    g <- function(k) M[, grep(k, cn, fixed = TRUE)[1]]
    se <- function(x) sd(x)/sqrt(length(x))
    say(sprintf("[%s / %-3s] R=%d | P(more n)=%.3f (%+.0f, SE %.0f) | P(lower HR)=%.3f (%+.4f, SE %.4f)",
        tag, sc, nrow(M), mean(g("n_hr")-g("n_full")>0), mean(g("n_hr")-g("n_full")), se(g("n_hr")-g("n_full")),
        mean(g("hr_hr")-g("hr_full")<0), mean(g("hr_hr")-g("hr_full")), se(g("hr_hr")-g("hr_full"))))
    saveRDS(M, sprintf("analysis/out/rule_%s_%s.rds", tag, sc))
  }
}
run("colon", colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825, 500L)
run("rotterdam", rott_data(), rott_criteria, rott_ps, "trt","dtime","death", 2555, 400L)
say("ALL DONE")
