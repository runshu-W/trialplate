## Reviewer round 2, minor points on proportional hazards and on weighting a
## randomised trial, plus major point 7's second half.
##
## (a) The proportional-hazards assumption is not tested anywhere in the paper.
##     Under non-PH the Cox coefficient is a weighted average of the log hazard
##     ratio over the follow-up, which is still a summary but not a constant
##     effect; since the rule selects on that coefficient, it matters what it is
##     summarising.
## (b) In the randomised colon cohort the assignment probability is known by
##     design, so estimating a propensity model adds noise for nothing. We
##     compare three weighting schemes to check that none of our conclusions
##     rests on that estimation.
source("analysis/_setup.R")
suppressPackageStartupMessages(library(survival))
ALLS <- function(E, S) { r <- E[, S[1]]; for (j in S[-1]) r <- r & E[, j]; r }

sink("analysis/out/ph_and_weights.txt", split = TRUE)

cat("(a) Proportional hazards, Grambsch-Therneau test on the treatment term\n\n")
cat(sprintf("%-12s %-22s %8s %8s %10s\n", "cohort", "cohort definition", "n", "events", "p (zph)"))
for (nm in c("colon","rott")) {
  pr <- if (nm == "colon") tp_prepare(colon_data(), colon_criteria, "trt","time","status", colon_ps, tau=1825)
        else               tp_prepare(rott_data(),  rott_criteria,  "trt","dtime","death", rott_ps, tau=2555)
  for (which in c("whole cohort","full protocol")) {
    k <- if (which == "whole cohort") rep(TRUE, nrow(pr$E)) else ALLS(pr$E, seq_len(pr$p))
    d <- data.frame(t = pr$time[k], s = pr$status[k], a = pr$trt[k])
    f <- survival::coxph(Surv(t, s) ~ a, data = d)
    z <- survival::cox.zph(f)
    cat(sprintf("%-12s %-22s %8d %8d %10.4f\n", nm, which, sum(k), sum(d$s), z$table["a","p"]))
  }
}
cat("\n  A small p indicates the hazard ratio is not constant over follow-up. Where\n")
cat("  that holds, the Cox coefficient is a follow-up-weighted average rather than\n")
cat("  a constant effect, and the restricted mean difference carried alongside it\n")
cat("  is the estimand with an unambiguous reading.\n")

cat("\n(b) colon is randomised: does estimating a propensity model matter?\n\n")
pr <- tp_prepare(colon_data(), colon_criteria, "trt","time","status", colon_ps, tau = 1825)
p <- pr$p; full <- seq_len(p)
schemes <- list(
  "estimated PS (main analysis)" = NULL,
  "known randomisation prob"     = "known",
  "unweighted"                   = "none")
for (lab in names(schemes)) {
  sc <- schemes[[lab]]
  V <- matrix(NA_real_, 2^p, 2)
  bits <- bitwShiftL(1L, 0:(p-1))
  for (kk in 0:(2^p - 1)) {
    S <- which(bitwAnd(kk, bits) > 0)
    keep <- if (!length(S)) rep(TRUE, nrow(pr$E)) else ALLS(pr$E, S)
    tr <- pr$trt[keep]; ti <- pr$time[keep]; stt <- pr$status[keep]; nn <- sum(keep)
    if (min(sum(tr), nn - sum(tr)) < 5 || sum(stt) < 3) next
    w <- if (is.null(sc)) {
           e <- tryCatch(fast_logit(pr$X[keep,,drop=FALSE], tr), error=function(z) rep(mean(tr), nn))
           e <- pmin(pmax(e,.05),.95); tr/e + (1-tr)/(1-e)
         } else if (sc == "known") { pt <- mean(pr$trt); tr/pt + (1-tr)/(1-pt)
         } else rep(1, nn)
    b <- fast_cox_bin(ti, stt, tr, w, theta = pr$ridge)
    if (is.finite(b)) { V[kk+1L, 1] <- b; V[kk+1L, 2] <- log(nn) }
  }
  okv <- !is.na(V[,1])
  Vf <- V; Vf[!okv,1] <- 0
  phi <- tp_shapley(cbind(Vf[,1], 0, Vf[,2]), p, 1L)
  S <- which(phi < 0)
  cat(sprintf("  %-28s HR full %.4f | HR rule %.4f | retains %s\n", lab,
      exp(V[2^p,1]), exp(V[sum(bits[S])+1L,1]), paste(pr$names[S], collapse=",")))
}
cat("\n  If the three rows agree, the selection and the headline hazard ratios do not\n")
cat("  depend on estimating a propensity model in the randomised cohort.\n")
sink()
