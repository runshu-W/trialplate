## Reviewer round 3, minor point 1. We reported that estimating a propensity model
## in the randomised colon cohort changes the selected criterion set by one of
## nine and the headline hazard ratios by about 0.01, which the reviewer rightly
## says is not obviously negligible. Here the three weighting schemes are carried
## through the full out-of-sample evaluation rather than compared only on the
## whole cohort, so a reader can see whether the conclusions depend on the choice.
source("analysis/_setup.R")
ALLS <- function(E, S) { if (!length(S)) return(rep(TRUE, nrow(E)))
                         r <- E[, S[1]]; for (j in S[-1]) r <- r & E[, j]; r }

## enumerate with a chosen weighting scheme
enum_w <- function(pr, scheme) {
  p <- pr$p; bits <- bitwShiftL(1L, 0:(p-1))
  V <- matrix(NA_real_, 2^p, 3, dimnames = list(NULL, c("logHR","rmstD","logN")))
  for (kk in 0:(2^p - 1)) {
    S <- which(bitwAnd(kk, bits) > 0); keep <- ALLS(pr$E, S)
    n <- sum(keep); tr <- pr$trt[keep]; ti <- pr$time[keep]; stt <- pr$status[keep]
    if (min(sum(tr), n - sum(tr)) < 3 || sum(stt) < 3) next
    w <- if (scheme == "ps") {
           e <- tryCatch(fast_logit(pr$X[keep,,drop=FALSE], tr), error=function(z) rep(mean(tr), n))
           e <- pmin(pmax(e,.05),.95); tr/e + (1-tr)/(1-e)
         } else if (scheme == "known") { pt <- mean(pr$trt); tr/pt + (1-tr)/(1-pt)
         } else rep(1, n)
    b <- fast_cox_bin(ti, stt, tr, w, theta = pr$ridge)
    i1 <- tr == 1L
    r1 <- fast_rmst(ti[i1], stt[i1], w[i1], pr$tau)
    r0 <- fast_rmst(ti[!i1], stt[!i1], w[!i1], pr$tau)
    if (is.finite(b)) { V[kk+1L,] <- c(b, r1 - r0, log(n)) }
  }
  V
}

R <- as.integer(Sys.getenv("CWT_R", "300"))
d <- colon_data(); n <- nrow(d); p <- length(colon_criteria); full <- seq_len(p)
bits <- bitwShiftL(1L, 0:(p-1))
set.seed(31)
res <- .tp_lapply(seq_len(R), function(r) {
  set.seed(31000 + r)
  ix <- sample(n, floor(0.5*n))
  fit <- tp_prepare(d[ix,,drop=FALSE],  colon_criteria, "trt","time","status", colon_ps, tau=1825)
  sc  <- tp_prepare(d[-ix,,drop=FALSE], colon_criteria, "trt","time","status", colon_ps, tau=1825)
  o <- c()
  for (scheme in c("ps","known","none")) {
    Vf <- enum_w(fit, scheme); if (any(is.na(Vf[,1]))) return(NULL)
    S <- which(tp_shapley(Vf, p, 1L) < 0)
    Vs <- enum_w(sc, scheme); if (any(is.na(Vs[,1]))) return(NULL)
    kR <- sum(bits[S])+1L; kF <- sum(bits[full])+1L
    o[paste0(scheme,"_lower")] <- as.numeric(Vs[kR,1] < Vs[kF,1])
    o[paste0(scheme,"_more")]  <- as.numeric(Vs[kR,3] > Vs[kF,3])
    o[paste0(scheme,"_hr")]    <- exp(Vs[kR,1])
    o[paste0(scheme,"_nkeep")] <- length(S)
  }
  o
}, 2L)
M <- do.call(rbind, res[!vapply(res, is.null, logical(1))])
ci <- function(x){x<-x[is.finite(x)]; q<-replicate(2000, mean(sample(x,replace=TRUE)))
  sprintf("%.3f [%.3f, %.3f]", mean(x), quantile(q,.025), quantile(q,.975))}
sink("analysis/out/colon_weighting_oos.txt", split = TRUE)
cat(sprintf("colon is randomised: out-of-sample performance under three weightings (%d splits)\n\n", nrow(M)))
cat(sprintf("%-28s %22s %22s %10s %8s\n","weighting","P(lower HR)","P(more eligible)","mean HR","criteria kept"))
for (s in c("ps","known","none")) cat(sprintf("%-28s %22s %22s %10.4f %8.2f\n",
  c(ps="estimated propensity", known="known randomisation prob", none="unweighted")[s],
  ci(M[,paste0(s,"_lower")]), ci(M[,paste0(s,"_more")]),
  mean(M[,paste0(s,"_hr")]), mean(M[,paste0(s,"_nkeep")])))
cat("\nIntervals are across splits and so are narrower than the patient-level\nuncertainty reported elsewhere; they are shown to compare the three schemes\nwith each other, not to quantify population uncertainty.\n")
sink()
saveRDS(M, "analysis/out/colon_weighting_oos.rds")
