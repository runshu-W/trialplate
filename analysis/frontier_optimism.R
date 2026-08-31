## Reviewer round 3, major point 1. The frontier in the previous version was built
## by scoring all 512 subsets on the held-out half and taking the best. The rule
## never saw that half, so the comparison is honest for the RULE, but the FRONTIER
## is an argmax over 512 noisy estimates and is therefore optimistic. "1.6% on the
## frontier" and "72 subsets dominate" partly measure test-set noise rather than
## genuine population dominance. The reviewer is right, and this script measures
## how large that optimism is.
##
## In simulation the population truth is available, so we can compare
##   (a) dominance judged on a held-out half the size of a real cohort, against
##   (b) dominance judged against the population, computed at N = 300 000.
## The gap between them is the winner's curse. We also report the reproducibility
## a reader can check without truth: of the subsets that dominate on half A, what
## fraction still dominate on an independent half B.
source("analysis/_setup.R")

P <- 9L
RETAIN <- 0.28; KEEP <- RETAIN^(1/P); THR <- qnorm(rep(KEEP, P))
GAM <- c(-0.35, +0.30, -0.20, 0, 0, 0, 0, 0, 0)
gen <- function(n, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  Z <- matrix(rnorm(n * P), n, P); A <- rbinom(n, 1, .5)
  E <- sweep(Z, 2, THR, "<=")
  lp <- log(0.75)*A + Z %*% rep(0.55, P) + A * (E %*% GAM)
  t <- rexp(n, rate = 0.20 * exp(as.numeric(lp))); cs <- rexp(n, rate = 0.05)
  data.frame(t = pmin(t, cs), st = as.integer(t <= cs), A = A, as.data.frame(Z))
}
CRIT <- setNames(lapply(seq_len(P), function(k)
  local({ kk <- k; ct <- THR[k]; function(x) x[[paste0("V", kk)]] <= ct })), paste0("C", seq_len(P)))
prep_of <- function(d) tp_prepare(d, CRIT, "A","t","st", paste0("V", seq_len(P)), tau = 8, min_per_arm = 3)
bits <- bitwShiftL(1L, 0:(P-1)); full <- seq_len(P)

say("population reference (N = 3e5)")
CACHE <- "analysis/out/frontier_pop.rds"
V0 <- if (file.exists(CACHE)) readRDS(CACHE) else { v <- tp_enumerate(prep_of(gen(3e5, seed = 11)))
  saveRDS(v, CACHE); v }
ok0 <- V0[, "feasible"] == 1
N0 <- exp(V0[, "logN"]); H0 <- V0[, "logHR"]
say(sprintf("  feasible subsets at the population: %d of %d", sum(ok0), length(ok0)))

## how many subsets genuinely dominate a given subset, at the population?
pop_dom <- function(k) sum(ok0 & N0 >= N0[k] & H0 <= H0[k] & (N0 > N0[k] | H0 < H0[k]))

R <- as.integer(Sys.getenv("FOPT_R", "160"))
NHALF <- as.integer(Sys.getenv("FOPT_N", "310"))     # size of a colon scoring half

res <- .tp_lapply(seq_len(R), function(r) {
  dfit <- gen(NHALF, seed = 30000 + 7*r)
  dA   <- gen(NHALF, seed = 40000 + 7*r)             # held-out half A
  dB   <- gen(NHALF, seed = 50000 + 7*r)             # independent half B
  pf <- prep_of(dfit); Vf <- tryCatch(tp_enumerate(pf), error=function(e) NULL)
  if (is.null(Vf) || any(Vf[,"feasible"]==0)) return(NULL)
  S <- which(tp_shapley(Vf, P, 1L) < 0); kR <- sum(bits[S]) + 1L
  pa <- prep_of(dA); Va <- tryCatch(tp_enumerate(pa), error=function(e) NULL)
  pb <- prep_of(dB); Vb <- tryCatch(tp_enumerate(pb), error=function(e) NULL)
  if (is.null(Va) || is.null(Vb)) return(NULL)
  oa <- Va[,"feasible"]==1; Na <- exp(Va[,"logN"]); Ha <- Va[,"logHR"]
  obb<- Vb[,"feasible"]==1; Nb <- exp(Vb[,"logN"]); Hb <- Vb[,"logHR"]
  if (!oa[kR] || !obb[kR] || !ok0[kR]) return(NULL)
  ## dominance sets
  domA <- which(oa & Na >= Na[kR] & Ha <= Ha[kR] & (Na > Na[kR] | Ha < Ha[kR]))
  domP <- which(ok0 & N0 >= N0[kR] & H0 <= H0[kR] & (N0 > N0[kR] | H0 < H0[kR]))
  ## of those dominating on A, how many still dominate on the independent B?
  stillB <- if (length(domA)) mean(obb[domA] & Nb[domA] >= Nb[kR] & Hb[domA] <= Hb[kR]) else NA_real_
  ## and how many of them genuinely dominate at the population?
  trueP  <- if (length(domA)) mean(domA %in% domP) else NA_real_
  c(n_domA = length(domA), n_domP = length(domP),
    front_emp = as.numeric(length(domA) == 0), front_pop = as.numeric(length(domP) == 0),
    repro_B = stillB, true_frac = trueP)
}, 2L)

M <- do.call(rbind, res[!vapply(res, is.null, logical(1))])
sink("analysis/out/frontier_optimism.txt", split = TRUE)
cat(sprintf("Winner's curse in the held-out frontier (%d replicates, half size %d)\n\n", nrow(M), NHALF))
ci <- function(x) { x <- x[is.finite(x)]
  q <- replicate(2000, mean(sample(x, replace = TRUE)))
  sprintf("%.3f [%.3f, %.3f]", mean(x), quantile(q,.025), quantile(q,.975)) }
cat(sprintf("  subsets dominating the rule, judged on a held-out half : median %.0f\n", median(M[,"n_domA"])))
cat(sprintf("  subsets dominating the rule, judged at the population  : median %.0f\n", median(M[,"n_domP"])))
cat(sprintf("  rule on the EMPIRICAL held-out frontier                : %s\n", ci(M[,"front_emp"])))
cat(sprintf("  rule on the POPULATION frontier                        : %s\n", ci(M[,"front_pop"])))
cat(sprintf("\n  of the subsets that dominate on half A:\n"))
cat(sprintf("    still dominate on an independent half B              : %s\n", ci(M[,"repro_B"])))
cat(sprintf("    genuinely dominate at the population                 : %s\n", ci(M[,"true_frac"])))
cat("\n  The empirical frontier is an argmax over 512 noisy estimates, so it sits\n")
cat("  below the population frontier and the count of dominating subsets is\n")
cat("  inflated. The ratio of the two medians is the optimism factor a reader\n")
cat("  should apply when reading the corresponding numbers in the two cohorts.\n")
sink()
saveRDS(M, "analysis/out/frontier_optimism.rds")
say("ALL DONE")
