## A consequence of the reviewer's major point 6 that deserves its own result.
## The full protocol is the most restrictive cohort the rule has to evaluate,
## so it is exactly where positivity is most likely to fail. If overlap decays
## as criteria are added, then every eligibility-relaxation method inherits a
## problem that gets worse the stricter the protocol -- and the diagnostic
## belongs BEFORE the method, not after it.
source("analysis/_setup.R")
ALLS <- function(E, S) { if (!length(S)) return(rep(TRUE, nrow(E)))
                         r <- E[, S[1]]; for (j in S[-1]) r <- r & E[, j]; r }
smd <- function(x, g, ww) {
  m1 <- weighted.mean(x[g==1], ww[g==1]); m0 <- weighted.mean(x[g==0], ww[g==0])
  v1 <- sum(ww[g==1]*(x[g==1]-m1)^2)/sum(ww[g==1]); v0 <- sum(ww[g==0]*(x[g==0]-m0)^2)/sum(ww[g==0])
  if (!is.finite(v1+v0) || (v1+v0) == 0) return(NA_real_); (m1-m0)/sqrt((v1+v0)/2)
}
scan_subsets <- function(d, crit, ps, trt, tm, st, tau, label) {
  pr <- tp_prepare(d, crit, trt, tm, st, ps, tau = tau); p <- pr$p
  X0 <- pr$X; bits <- bitwShiftL(1L, 0:(p-1))
  res <- do.call(rbind, lapply(0:(2^p - 1), function(kk) {
    S <- which(bitwAnd(kk, bits) > 0); k <- ALLS(pr$E, S)
    n <- sum(k); tr <- pr$trt[k]
    if (n < 20 || min(sum(tr), n - sum(tr)) < 5) return(NULL)
    e <- tryCatch(fast_logit(pr$X[k,,drop=FALSE], tr), error=function(z) rep(mean(tr), n))
    et <- pmin(pmax(e, .05), .95); w <- tr/et + (1-tr)/(1-et)
    Xs <- pr$X[k,,drop=FALSE]
    s <- vapply(colnames(Xs)[-1], function(v)
      if (stats::sd(Xs[,v])==0) NA_real_ else abs(smd(Xs[,v], tr, w)), numeric(1))
    c(size = length(S), n = n, ess_frac = (sum(w)^2/sum(w^2))/n,
      trunc = mean(e <= .05 | e >= .95), maxsmd = max(s, na.rm = TRUE),
      events = sum(pr$status[k]))
  }))
  agg <- aggregate(cbind(ess_frac, trunc, maxsmd, n, events) ~ size, data = as.data.frame(res), FUN = median)
  cat(sprintf("\n===== %s =====\n", label))
  cat(sprintf("%5s %6s %8s %9s %9s %9s %8s\n","|S|","subsets","median n","events","ESS/n","truncated","max|SMD|"))
  for (i in seq_len(nrow(agg))) {
    z <- agg[i,]; cnt <- sum(res[,"size"] == z$size)
    cat(sprintf("%5d %6d %8.0f %9.0f %9.3f %9.3f %8.3f\n",
        z$size, cnt, z$n, z$events, z$ess_frac, z$trunc, z$maxsmd))
  }
  invisible(as.data.frame(res))
}
sink("analysis/out/overlap_vs_restriction.txt", split = TRUE)
A <- scan_subsets(colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825, "colon (randomised)")
B <- scan_subsets(rott_data(),  rott_criteria,  rott_ps,  "trt","rtime","death", 1825, "Rotterdam (registry)")
sink()
saveRDS(list(colon = A, rott = B), "analysis/out/overlap_vs_restriction.rds")
