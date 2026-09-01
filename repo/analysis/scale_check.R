## Fidelity check against the published implementation.
##
## The official repo (RuishanLiu/TrialPathfinder) states the rule as "select all
## the rules with Shapley value less than 0" and reports hazard ratios, but does
## not say whether the Shapley decomposition runs on HR or on log HR. We use log
## HR, because the Shapley axioms presuppose an additive value function and the
## log is the additive scale of a ratio.
##
## Does the choice matter? A monotone transform preserves the sign of each
## marginal contribution v(S+i) - v(S), but Shapley is a weighted average of
## contributions that can have mixed signs, and the transform reweights their
## magnitudes -- so the SELECTED SET can differ in principle. Measure how often
## it does, on random half-samples of both cohorts.
source("analysis/_setup.R")

compare <- function(tag, dat, crit, ps, trt, tm, st, tau, R = 400L, frac = 0.5) {
  prep <- tp_prepare(dat, crit, trt, tm, st, ps, tau = tau)
  p <- prep$p
  ## on the full cohort first
  V <- tp_enumerate(prep)
  Vh <- V; Vh[, 1] <- exp(V[, 1])                       # HR scale in column 1
  sel_log <- which(tp_shapley(V,  p, 1L) < 0)
  sel_hr  <- which(tp_shapley(Vh, p, 1L) < 0)
  say(sprintf("=== %s, 全队列 ===", tag))
  say(sprintf("  log HR 尺度选中: %s", paste(prep$names[sel_log], collapse=", ")))
  say(sprintf("  HR     尺度选中: %s", paste(prep$names[sel_hr],  collapse=", ")))
  say(sprintf("  两者相同? %s", setequal(sel_log, sel_hr)))

  ## then across random half-samples, which is what the split evaluation uses
  set.seed(20260830); nn <- nrow(prep$E)
  idx <- lapply(seq_len(R), function(i) sample.int(nn, floor(frac * nn)))
  res <- do.call(rbind, .tp_lapply(idx, function(ii) tryCatch({
    q <- .reindex(prep, ii); Vq <- tp_enumerate(q)
    if (any(Vq[, "feasible"] == 0)) return(NULL)
    Vqh <- Vq; Vqh[, 1] <- exp(Vq[, 1])
    a <- which(tp_shapley(Vq,  p, 1L) < 0)
    b <- which(tp_shapley(Vqh, p, 1L) < 0)
    c(same = as.numeric(setequal(a, b)), n_log = length(a), n_hr = length(b),
      ndiff = length(union(setdiff(a,b), setdiff(b,a))))
  }, error = function(e) NULL), 2L))
  res <- res[complete.cases(res), , drop = FALSE]
  say(sprintf("  %d 次半样本: 选出同一标准集的比例 = %.3f", nrow(res), mean(res[,"same"])))
  say(sprintf("  不同时平均差 %.2f 条标准；log 尺度平均保留 %.2f 条，HR 尺度 %.2f 条",
      if (any(res[,"same"]==0)) mean(res[res[,"same"]==0, "ndiff"]) else 0,
      mean(res[,"n_log"]), mean(res[,"n_hr"])))
  saveRDS(res, sprintf("analysis/out/scale_%s.rds", tag)); invisible(res)
}
compare("colon",     colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825)
compare("rotterdam", rott_data(),  rott_criteria,  rott_ps,  "trt","dtime","death", 2555, R = 300L)
say("ALL DONE")
