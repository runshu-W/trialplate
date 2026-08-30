## W4-b  Do the 95% BCa intervals actually cover? Known truth, so this is a
## direct check. Run at p = 6 (64 subsets) rather than p = 8, because each
## replicate needs 1 + B + K enumerations; the reduction is stated in the paper.
## Reported for the PLANTED pair (nonzero truth) and for a null pair, and
## against the plain percentile interval so BCa has to earn its cost.
source("analysis/_setup.R")

P <- 6L; GAMMA <- -0.60; C12 <- qnorm(0.45); CREST <- qnorm(0.85)
gen <- function(n, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  Z <- matrix(rnorm(n * P), n, P); A <- rbinom(n, 1, .5)
  E1 <- Z[,1] <= C12; E2 <- Z[,2] <= C12
  lp <- log(0.80)*A + Z %*% rep(0.28, P) + GAMMA * A * E1 * E2
  t <- rexp(n, rate = 0.22 * exp(as.numeric(lp))); cens <- rexp(n, rate = 0.05)
  data.frame(t = pmin(t, cens), st = as.integer(t <= cens), A = A, as.data.frame(Z))
}
CRIT <- setNames(lapply(seq_len(P), function(k)
  local({ kk <- k; cut <- if (k <= 2) C12 else CREST
          function(x) x[[paste0("V", kk)]] <= cut })), paste0("C", seq_len(P)))
PS <- paste0("V", seq_len(P))
prep_of <- function(d) tp_prepare(d, CRIT, "A", "t", "st", PS, tau = 6, min_per_arm = 3)

say("population truth (N = 2e5)")
V0 <- tp_enumerate(prep_of(gen(2e5, seed = 1))); I0 <- tp_interaction(V0, P, 1L)
NULLPAIR <- c(4L, 5L)
say(sprintf("  true I[1,2] = %+.4f    true I[4,5] = %+.4f", I0[1,2], I0[NULLPAIR[1],NULLPAIR[2]]))

R <- as.integer(Sys.getenv("COV_R", "150")); B <- 200L; K <- 25L; N <- 1500L
cov1 <- cov2 <- pct1 <- pct2 <- logical(0); wid <- numeric(0)
for (r in seq_len(R)) {
  d <- gen(N, seed = 5000 + 13*r); pr <- prep_of(d)
  V <- tp_enumerate(pr); if (any(V[,"feasible"] == 0)) next
  Ih <- tp_interaction(V, P, 1L)
  bt <- tp_boot(pr, B = B, cores = 2L, seed = 900 + r)
  jk <- tp_jack(pr, K = K, cores = 2L, seed = 900 + r)
  gb <- function(i,j) vapply(bt, function(x) x$I[i,j,1], numeric(1))
  gj <- function(i,j) vapply(jk, function(x) x$I[i,j,1], numeric(1))
  ck <- function(i,j,truth) {
    b <- .bca_bounds(Ih[i,j], gb(i,j), gj(i,j), .05)
    q <- quantile(gb(i,j), c(.025,.975), na.rm = TRUE, names = FALSE)
    c(bca = truth >= b[1] && truth <= b[2], pct = truth >= q[1] && truth <= q[2], w = b[2]-b[1]) }
  a <- ck(1,2,I0[1,2]); b2 <- ck(NULLPAIR[1],NULLPAIR[2],I0[NULLPAIR[1],NULLPAIR[2]])
  cov1 <- c(cov1, a["bca"]==1); pct1 <- c(pct1, a["pct"]==1); wid <- c(wid, a["w"])
  cov2 <- c(cov2, b2["bca"]==1); pct2 <- c(pct2, b2["pct"]==1)
  if (r %% 15 == 0) say(sprintf("  rep %3d  BCa cover: planted %.3f  null %.3f | percentile %.3f / %.3f",
      r, mean(cov1), mean(cov2), mean(pct1), mean(pct2)))
  saveRDS(list(cov_bca_planted=cov1, cov_bca_null=cov2, cov_pct_planted=pct1,
               cov_pct_null=pct2, width=wid, I0=I0, n=N, B=B, K=K), "analysis/out/sim_coverage.rds")
}
say(sprintf("FINAL  reps %d | BCa: planted %.3f null %.3f | percentile: planted %.3f null %.3f | median width %.3f",
    length(cov1), mean(cov1), mean(cov2), mean(pct1), mean(pct2), median(wid)))
