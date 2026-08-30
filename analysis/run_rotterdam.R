source("analysis/_setup.R")
prep <- tp_prepare(rott_data(), rott_criteria, "trt","dtime","death", rott_ps, tau = 2555)
fit  <- tp_fit(prep); saveRDS(list(prep=prep, fit=fit), "analysis/out/r_fit.rds")
say("fit done; infeasible", fit$n_infeasible, "; implications:",
    if (is.null(fit$impl$pairs)) "none" else nrow(fit$impl$pairs))
## the risk point first
M <- tp_boot_frontier(prep, fit, B = 400L, cores = 2L); saveRDS(M, "analysis/out/r_frontier.rds")
tp_frontier_report(M, "rotterdam paired frontier"); say("frontier done")
## then the full inference, staged
jack <- tp_jack(prep, K = 50L, cores = 2L); saveRDS(jack, "analysis/out/r_jack.rds"); say("jack done")
boot <- tp_boot(prep, B = 2000L, cores = 2L); saveRDS(boot, "analysis/out/r_boot.rds"); say("boot done", length(boot))
sm   <- tp_summarise(fit, boot, jack); saveRDS(sm, "analysis/out/r_sm.rds"); say("summarise done")
perm <- tp_perm(prep, fit, P = 500L, cores = 2L); saveRDS(perm, "analysis/out/r_perm.rds")
saveRDS(list(fit=fit, sm=sm, perm=perm, M=M), "analysis/out/rott_full.rds"); say("ALL DONE")
