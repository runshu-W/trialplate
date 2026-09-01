## How stable is the headline claim that the two estimands pick DIFFERENT
## protocols? Resample patients, rebuild both frontiers, record the picks.
source("analysis/_setup.R")
prep <- tp_prepare(colon_data(), colon_criteria, "trt","time","status", colon_ps, tau=1825)
fit  <- tp_fit(prep); p <- prep$p; n0 <- exp(fit$V[nrow(fit$V), "logN"])
picks <- function(V) {
  ok <- V[,"feasible"] == 1; n <- exp(V[ok,"logN"]); hr <- exp(V[ok,"logHR"]); rm <- V[ok,"rmstD"]
  key <- which(ok)[ok[ok]]                 # subset index among feasible
  el <- n >= n0
  if (!any(el)) return(c(NA, NA, NA, NA, NA))
  a <- which(el)[which.min(hr[el])]; b <- which(el)[which.max(rm[el])]
  c(same = as.numeric(a == b), n_hr = n[a], n_rm = n[b], rm_hr = rm[a], rm_rm = rm[b])
}
set.seed(20260829); nn <- nrow(prep$E)
idx <- lapply(1:400, function(i) sample.int(nn, nn, TRUE))
out <- parallel::mclapply(idx, function(ii)
  tryCatch(picks(tp_enumerate(.reindex(prep, ii))), error=function(e) rep(NA,5)), mc.cores = 2L)
M <- do.call(rbind, out); M <- M[complete.cases(M), , drop = FALSE]
saveRDS(M, "analysis/out/frontier_boot.rds")
cat(sprintf("reps %d\nP(two estimands pick the SAME protocol) = %.3f\n", nrow(M), mean(M[,1])))
cat(sprintf("P(RMST-optimal admits MORE patients than HR-optimal) = %.3f\n", mean(M[,3] > M[,2])))
cat(sprintf("median RMST gain of RMST-pick over HR-pick = %.1f days (IQR %.1f to %.1f)\n",
  median(M[,5]-M[,4]), quantile(M[,5]-M[,4],.25), quantile(M[,5]-M[,4],.75)))
