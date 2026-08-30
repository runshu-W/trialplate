## Data-generating process for the power scan (W3-c).
## Eight criteria on eight covariates; the treatment effect gains GAMMA extra
## log-hazard benefit only for patients meeting BOTH C1 and C2, so the pair
## (C1, C2) carries a genuine interaction and the other 27 pairs do not.

## The interaction coefficient of a "benefit only if BOTH criteria met" design is
## 1 - p11/p1 - p11/p2 + p11. At p1 = p2 = 0.70 with positive correlation this
## nearly cancels (~0.02), which is why the first attempt planted no signal.
## C1 and C2 are therefore made restrictive (keep 45%) and independent -> ~0.30,
## while C3..C8 stay mild (keep 85%) so the full protocol remains feasible.
P <- 8L; GAMMA <- -0.60         # treated patients meeting BOTH C1 and C2 gain extra benefit
C12 <- qnorm(0.45); CREST <- qnorm(0.85)
gen <- function(n, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  Z <- matrix(rnorm(n * P), n, P)
  A <- rbinom(n, 1, .5)
  E1 <- Z[, 1] <= C12; E2 <- Z[, 2] <= C12             # C1, C2 keep 45% each, independent
  lp <- log(0.80) * A + Z %*% rep(0.28, P) + GAMMA * A * E1 * E2
  d <- data.frame(t = rexp(n, rate = 0.22 * exp(as.numeric(lp))), A = A)
  d$st <- 1L
  cens <- rexp(n, rate = 0.05)
  d$st <- as.integer(d$t <= cens); d$t <- pmin(d$t, cens)
  cbind(d, as.data.frame(Z))
}
CRIT <- setNames(lapply(seq_len(P), function(k)
  local({ kk <- k; cut <- if (k <= 2) C12 else CREST
          function(x) x[[paste0("V", kk)]] <= cut })), paste0("C", seq_len(P)))
PS <- paste0("V", seq_len(P))
one <- function(d) {
  pr <- tp_prepare(d, CRIT, "A", "t", "st", PS, tau = 6, min_per_arm = 3)
  V <- tp_enumerate(pr)
  list(I = tp_interaction(V, P, 1L), IR = tp_interaction(V, P, 2L),
       ok = all(V[, "feasible"] == 1))
}

