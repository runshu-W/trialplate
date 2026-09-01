## Reviewer round 3, major point 6, second half. Holding the total |gamma| fixed
## does not automatically hold the detectable target fixed, because the Cox hazard
## ratio is non-linear and non-collapsible. This checks, for each arrangement,
## the four quantities the reviewer asks about, on a large evaluation set.
source("analysis/_setup.R")
P <- 8L; RETAIN <- 0.20; KEEP <- RETAIN^(1/P); THR <- qnorm(rep(KEEP, P))
CONFIG <- list(
  A_dil1_enr1 = c(-0.55, +0.30,  0.00,  0.00, 0, 0, 0, 0),
  B_dil1_enr2 = c(-0.30, +0.30, -0.25,  0.00, 0, 0, 0, 0),
  C_dil1_enr4 = c(-0.16, +0.30, -0.14, -0.13, -0.12, 0, 0, 0),
  D_dil2_enr1 = c(-0.55, +0.15, +0.15,  0.00, 0, 0, 0, 0))
gen_of <- function(GAM) function(n, seed=NULL){ if(!is.null(seed)) set.seed(seed)
  Z <- matrix(rnorm(n*P),n,P); A <- rbinom(n,1,.5); E <- sweep(Z,2,THR,"<=")
  lp <- log(0.75)*A + Z%*%rep(0.55,P) + A*(E%*%GAM)
  t <- rexp(n, rate=0.20*exp(as.numeric(lp))); cs <- rexp(n, rate=0.05)
  data.frame(t=pmin(t,cs), st=as.integer(t<=cs), A=A, as.data.frame(Z)) }
CRIT <- setNames(lapply(1:P, function(k) local({kk<-k;ct<-THR[k];function(x) x[[paste0("V",kk)]]<=ct})), paste0("C",1:P))
prep_of <- function(d) tp_prepare(d, CRIT, "A","t","st", paste0("V",1:P), tau=8, min_per_arm=3)
bits <- bitwShiftL(1L, 0:(P-1)); full <- 1:P

ROWS <- list()
sink("analysis/out/conc_targets.txt", split = TRUE)
cat("Is the detectable target the same under every arrangement? (N = 120 000)\n\n")
cat(sprintf("%-14s %8s %10s %11s %10s %12s %s\n",
  "config","sum|g|","HR full","HR oracle","gap","elig frac","oracle set"))
for (k in names(CONFIG)) {
  G <- CONFIG[[k]]
  pr <- prep_of(gen_of(G)(120000, seed = 777))
  V <- tp_enumerate(pr); ok <- V[,"feasible"]==1
  H <- V[,"logHR"]; N <- exp(V[,"logN"])
  kF <- sum(bits[full])+1L
  best <- which.min(ifelse(ok, H, Inf))
  bs <- which(bitwAnd(best-1L, bits) > 0)
  cat(sprintf("%-14s %8.2f %10.4f %11.4f %10.4f %12.3f %s\n", k, sum(abs(G)),
      exp(H[kF]), exp(H[best]), exp(H[kF])-exp(H[best]), N[kF]/nrow(pr$d),
      paste(pr$names[bs], collapse=",")))
  ## Reviewer round 5, major point 1: these four rows were quoted in the Results as
  ## literals because the script only ever printed them. Now saved.
  ROWS[[k]] <- list(cfg = k, sum_g = sum(abs(G)), hr_full = exp(H[kF]),
                     hr_oracle = exp(H[best]), gap = exp(H[kF]) - exp(H[best]),
                     elig_frac = N[kF]/nrow(pr$d))
}
cat("\nThe full-protocol hazard ratio is identical by construction: under the full\n")
cat("protocol every criterion is met, so the treated bonus is sum(gamma), which the\n")
cat("design holds at -0.25 in all four arrangements. The oracle-relaxed hazard ratio\n")
cat("and the resulting gap are NOT constrained by that and are reported above, so a\n")
cat("reader can see how far the detectable target really is held fixed.\n")
sink()
saveRDS(ROWS, "analysis/out/conc_targets.rds")
