## The mechanism, as a dose-response. Under proportional hazards the CONDITIONAL
## treatment effect is exp(bA) in every stratum of Z, so an eligibility criterion
## on Z changes no one's relative benefit. Yet the MARGINAL log HR moves, by an
## amount driven entirely by how much residual heterogeneity the criterion
## removes. Sweep bZ from 0 (no heterogeneity, nothing to collapse over) upward:
## if the artefact is real, phi_logHR must start at 0 and grow with bZ.
suppressPackageStartupMessages(library(survival))
set.seed(20260829); N <- 3e5; tau <- 5; bA <- log(0.6)
bZs <- c(0, .3, .6, .9, 1.2, 1.5, 1.8)
res <- t(sapply(bZs, function(bZ) {
  Z <- rnorm(N); A <- rbinom(N, 1, .5)
  t <- rexp(N, rate = 0.25 * exp(bA*A + bZ*Z))
  est <- function(k) c(
    unname(coef(coxph(Surv(t[k], rep(1, sum(k))) ~ A[k]))[1]),
    mean(pmin(t[k & A==1], tau)) - mean(pmin(t[k & A==0], tau)))
  a <- est(rep(TRUE,N)); s <- est(Z <= 0)
  c(bZ=bZ, HR_all=exp(a[1]), HR_sub=exp(s[1]), phi_logHR=s[1]-a[1],
    RM_all=a[2], RM_sub=s[2], phi_rmstD=s[2]-a[2]) }))
res <- as.data.frame(res)
res$conditional_HR <- exp(bA)      # constant by construction, in every stratum
print(round(res, 4), row.names = FALSE)
saveRDS(res, "analysis/out/sim_sweep.rds")

png("analysis/out/fig_sim.png", width=1900, height=880, res=205)
par(mfrow=c(1,2), mar=c(4.6,4.8,3.4,1.4), mgp=c(2.9,.7,0))
plot(res$bZ, res$phi_logHR, type="o", pch=21, bg="#C0392F", col="#8E1626", lwd=2, cex=1.3, las=1,
     xlab=expression("prognostic strength  "*beta[Z]), ylab=expression(phi*" on log HR"),
     main="", ylim=range(0, res$phi_logHR)*1.08)
abline(h=0, col="#B9C2CC", lwd=1.3)
mtext("HR: an artefact that grows with heterogeneity", side=3, line=.9, cex=.92, font=2)
mtext("true conditional effect is identical in every stratum, at every point on this curve",
      side=3, line=-.1, cex=.66, col="#666666")
plot(res$bZ, res$phi_rmstD, type="o", pch=21, bg="#2B6CAB", col="#10375F", lwd=2, cex=1.3, las=1,
     xlab=expression("prognostic strength  "*beta[Z]), ylab=expression(phi*" on RMST difference (time units)"),
     main="", ylim=range(0, res$phi_rmstD)*1.08)
abline(h=0, col="#B9C2CC", lwd=1.3)
mtext("RMST: tracks a real change in absolute benefit", side=3, line=.9, cex=.92, font=2)
mtext("the selected low-risk group genuinely has less room to gain", side=3, line=-.1, cex=.66, col="#666666")
dev.off()
cat("\n关键检验: bZ=0 时 phi_logHR =", signif(res$phi_logHR[1],3),
    " (无异质性 => 伪影应消失)\n")
