## Reviewer round 4, major point 4. The previous revision said that the data
## requirement should be read off "conditional curves", but no conditional curve
## was ever produced: Table 2 reports success at fixed fitting sizes for two
## arrangements, which is a sensitivity analysis, not a curve indexed by a
## signal-to-noise ratio. It also carried a sentence naming the largest diluting
## coefficient as the governing quantity, which our own round-3 results contradict
## (spreading the enrichment helped by about 0.21 at 6000, and halving the
## dilution also halves the attainable gap, so coefficient and prize are
## confounded in that design). Both are corrected in the text.
##
## This script asks the modest version of the question that these resources can
## answer: within one generating family, does success probability track a
## criterion-specific signal-to-noise ratio
##       SNR(n) = |phi_pop(j)| / SD_n( phi_hat(j) )
## as the fitting size varies, and do different arrangements of the same total
## modification fall on a common curve when indexed by SNR rather than by n?
## Four arrangements at three sizes cannot establish a governing quantity; the
## output is reported as an indication of direction, and the text says so.
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

NREP  <- as.integer(Sys.getenv("SNRC_R", "30"))
POPN  <- as.integer(Sys.getenv("SNRC_P", "60000"))
SIZES <- as.integer(strsplit(Sys.getenv("SNRC_N", "800,2000,5000"), ",")[[1]])
NSCORE <- as.integer(Sys.getenv("SNRC_S", "40000"))
bits <- bitwShiftL(1L, 0:(P - 1)); full <- seq_len(P)

rows <- list()
for (k in names(CONFIG)) {
  G <- CONFIG[[k]]; gen <- gen_of(G)
  ## population Shapley, to name the most diluting criterion and fix the signal
  phi0 <- tp_shapley(tp_enumerate(prep_of(gen(POPN, seed = 909))), P, 1L)
  j <- which.max(phi0)
  ## one large scoring set per arrangement, enumerated once
  Vs <- tp_enumerate(prep_of(gen(NSCORE, seed = 4242)))
  ok <- Vs[, "feasible"] == 1; H <- Vs[, "logHR"]; kF <- sum(bits[full]) + 1L
  for (n in SIZES) {
    res <- .tp_lapply(seq_len(NREP), function(r) {
      pr <- prep_of(gen(n, seed = 77000 + 131*r + 7*n + which(names(CONFIG)==k)))
      V <- tryCatch(tp_enumerate(pr), error = function(e) NULL)
      if (is.null(V) || any(V[, "feasible"] == 0)) return(NULL)
      ph <- tp_shapley(V, P, 1L); S <- which(ph < 0); kR <- sum(bits[S]) + 1L
      if (!ok[kR] || !ok[kF]) return(NULL)
      c(phi = ph[j], win = as.numeric(H[kR] < H[kF]))
    }, 2L)
    M <- do.call(rbind, res[!vapply(res, is.null, logical(1))])
    if (is.null(M) || nrow(M) < 5) next
    sdp <- stats::sd(M[, "phi"]); snr <- abs(phi0[j]) / sdp
    rows[[paste(k, n)]] <- c(n = n, phi_pop = phi0[j], sd = sdp, snr = snr,
                             win = mean(M[, "win"]), rep = nrow(M),
                             arr = which(names(CONFIG) == k))
    say(sprintf("%-14s n %6d | phi_pop %+.4f | SD %.4f | SNR %.2f | P(lower) %.2f (%d reps)",
                k, n, phi0[j], sdp, snr, mean(M[, "win"]), nrow(M)))
  }
}
T <- do.call(rbind, rows)
sp_snr <- suppressWarnings(cor(T[, "snr"], T[, "win"], method = "spearman"))
sp_n   <- suppressWarnings(cor(T[, "n"],   T[, "win"], method = "spearman"))
say(sprintf("\nSpearman with success: SNR %.2f | fitting size %.2f (%d cells)",
            sp_snr, sp_n, nrow(T)))
saveRDS(list(T = T, sp_snr = sp_snr, sp_n = sp_n,
             sizes = SIZES, nrep = NREP), "analysis/out/snr_curve.rds")
say("ALL DONE")
