## Positive control + sample-size curve for the split-sample design.
## The real cohorts show no out-of-sample advantage to selecting on RMST. Two
## explanations are possible and they have opposite implications:
##   (a) the estimands do not differ in a way that matters, or
##   (b) they do, but n = 619 / 2982 is far too small to act on it.
## Settle it on a DGP where the disagreement is KNOWN to exist (proportional
## hazards with strong prognostic heterogeneity: the criterion lowers the
## marginal HR while lowering absolute benefit) and sweep n.
source("analysis/_setup.R")

P <- 6L; BZ <- 0.9
gen <- function(n, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  Z <- matrix(rnorm(n * P), n, P); A <- rbinom(n, 1, .5)
  ## conditional HR is exp(log .6) in EVERY stratum; the criteria act only through
  ## which patients they select, which is exactly the non-collapsibility setting.
  lp <- log(0.6)*A + BZ * Z[, 1] + 0.5 * rowSums(Z[, -1, drop = FALSE]) / sqrt(P - 1)
  t <- rexp(n, rate = 0.25 * exp(as.numeric(lp))); cens <- rexp(n, rate = 0.04)
  data.frame(t = pmin(t, cens), st = as.integer(t <= cens), A = A, as.data.frame(Z))
}
CRIT <- setNames(lapply(seq_len(P), function(k)
  local({ kk <- k; function(x) x[[paste0("V", kk)]] <= 0.0 })), paste0("C", seq_len(P)))
PS <- paste0("V", seq_len(P))
prep_of <- function(d) tp_prepare(d, CRIT, "A","t","st", PS, tau = 6, min_per_arm = 3)

## truth: does selecting on RMST really give more RMST, at the population level?
say("population truth (N = 2e5)")
p0 <- prep_of(gen(2e5, seed = 1)); V0 <- tp_enumerate(p0)
el <- V0[,"feasible"] == 1
a0 <- which(el)[which.min(V0[el,"logHR"])]; b0 <- which(el)[which.max(V0[el,"rmstD"])]
say(sprintf("  HR-optimal protocol : RMST %+.3f | RMST-optimal : RMST %+.3f  ->  true gap %+.3f",
    V0[a0,"rmstD"], V0[b0,"rmstD"], V0[b0,"rmstD"] - V0[a0,"rmstD"]))
say(sprintf("  same protocol at the population level? %s", a0 == b0))

R <- as.integer(Sys.getenv("SPLIT_R", "300"))
for (n in c(600, 2000, 6000, 20000)) {
  pr <- prep_of(gen(n, seed = 77)); ft <- tp_fit(pr)
  M <- tp_split_eval(pr, ft, R = R, cores = 2L); M <- M[complete.cases(M), , drop = FALSE]
  g <- M[,"gap"]
  say(sprintf("n = %5d  R=%d | out-of-sample gap: mean %+.3f  median %+.3f  P(>0) %.3f | same pick %.3f",
      n, nrow(M), mean(g), median(g), mean(g > 0), mean(M[,"same"])))
  saveRDS(M, sprintf("analysis/out/splitsim_%d.rds", n))
}
say("ALL DONE")
