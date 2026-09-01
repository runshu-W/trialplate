## Reviewer round 3, major point 5. The reviewer argues that a raw effect-
## modification coefficient cannot be the general governing quantity, since the
## same coefficient on a criterion retaining 90% of the cohort and on one
## retaining 30% carries different information, and proposes a criterion-specific
## signal-to-noise ratio instead. We agree and test it.
##
## For each arrangement we compute
##   signal = the population Shapley value of the most diluting criterion
##   noise  = the standard deviation of that Shapley value across replicates at a
##            fixed fitting size
##   SNR    = |signal| / noise
## and ask whether the ordering of success probability follows SNR more closely
## than it follows the raw coefficient. The conc_targets.R output shows why this
## matters: splitting the dilution also halves the ATTAINABLE gap, so coefficient
## and prize move together by construction and cannot be separated in that design.
source("analysis/_setup.R")
P <- 8L; RETAIN <- 0.20; KEEP <- RETAIN^(1/P); THR <- qnorm(rep(KEEP, P))
CONFIG <- list(
  A_dil1_enr1 = c(-0.55, +0.30,  0.00,  0.00, 0, 0, 0, 0),
  B_dil1_enr2 = c(-0.30, +0.30, -0.25,  0.00, 0, 0, 0, 0),
  C_dil1_enr4 = c(-0.16, +0.30, -0.14, -0.13, -0.12, 0, 0, 0),
  D_dil2_enr1 = c(-0.55, +0.15, +0.15,  0.00, 0, 0, 0, 0))
OBS <- list(A_dil1_enr1=0.58, B_dil1_enr2=0.79, C_dil1_enr4=0.78, D_dil2_enr1=0.19)  # P(lower) at n=6000
gen_of <- function(GAM) function(n, seed=NULL){ if(!is.null(seed)) set.seed(seed)
  Z <- matrix(rnorm(n*P),n,P); A <- rbinom(n,1,.5); E <- sweep(Z,2,THR,"<=")
  lp <- log(0.75)*A + Z%*%rep(0.55,P) + A*(E%*%GAM)
  t <- rexp(n, rate=0.20*exp(as.numeric(lp))); cs <- rexp(n, rate=0.05)
  data.frame(t=pmin(t,cs), st=as.integer(t<=cs), A=A, as.data.frame(Z)) }
CRIT <- setNames(lapply(1:P, function(k) local({kk<-k;ct<-THR[k];function(x) x[[paste0("V",kk)]]<=ct})), paste0("C",1:P))
prep_of <- function(d) tp_prepare(d, CRIT, "A","t","st", paste0("V",1:P), tau=8, min_per_arm=3)

NREP <- as.integer(Sys.getenv("SNR_R", "60")); NFIT <- 6000L
rows <- list()
for (k in names(CONFIG)) {
  G <- CONFIG[[k]]; gen <- gen_of(G)
  phi0 <- tp_shapley(tp_enumerate(prep_of(gen(120000, seed = 909))), P, 1L)
  j <- which.max(phi0)                       # the most diluting criterion
  est <- unlist(.tp_lapply(seq_len(NREP), function(r) {
    pr <- prep_of(gen(NFIT, seed = 12000 + 13*r + which(names(CONFIG)==k)))
    V <- tryCatch(tp_enumerate(pr), error=function(e) NULL)
    if (is.null(V) || any(V[,"feasible"]==0)) return(NA_real_)
    tp_shapley(V, P, 1L)[j]
  }, 2L))
  est <- est[is.finite(est)]
  rows[[k]] <- c(coef = max(G), phi_pop = phi0[j], sd = stats::sd(est),
                 snr = abs(phi0[j])/stats::sd(est), obs = OBS[[k]], nrep = length(est))
  say(sprintf("%-14s max gamma %.2f | phi_pop %+.4f | SD %.4f | SNR %.2f | observed P %.2f",
      k, max(G), phi0[j], stats::sd(est), abs(phi0[j])/stats::sd(est), OBS[[k]]))
}
T <- do.call(rbind, rows)
sink("analysis/out/snr_check.txt", split = TRUE)
cat(sprintf("Signal-to-noise of the most diluting criterion (n_fit = %d, %d replicates)\n\n", NFIT, NREP))
cat(sprintf("%-14s %10s %12s %10s %8s %12s\n","arrangement","max gamma","population phi","SD(phi)","SNR","observed P"))
for (k in rownames(T)) cat(sprintf("%-14s %10.2f %12.4f %10.4f %8.2f %12.2f\n",
  k, T[k,"coef"], T[k,"phi_pop"], T[k,"sd"], T[k,"snr"], T[k,"obs"]))
cat(sprintf("\nSpearman correlation with observed success:  raw coefficient %.2f | SNR %.2f\n",
  cor(T[,"coef"], T[,"obs"], method="spearman"), cor(T[,"snr"], T[,"obs"], method="spearman")))
cat("\nFour arrangements is far too few to establish a governing quantity. This is\n")
cat("reported as a direction for the reviewer's suggestion, not as evidence for it.\n")
sink()
saveRDS(T, "analysis/out/snr_check.rds")
