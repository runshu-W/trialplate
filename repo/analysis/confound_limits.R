## Reviewer round 5, major point 1. The three population limits of the estimated
## between-protocol gap, and the full-protocol hazard ratio under each adjustment,
## were computed once and then typed into figures.R and into the Results text as
## literals. They are now computed here and written to a result file that both the
## figure and the manuscript read, so the figure and the text cannot drift apart.
##
## Only the population quantities are recomputed: one 100 000-patient evaluation
## set per arm, enumerated once. No replicate loop, so this is cheap.
source("analysis/_setup.R")

P <- 8L
CUT <- c(0.85, 0.75, 0.70, 0.90, 0.80, 0.85, 0.75, 0.90); THR <- qnorm(CUT)
GAM <- c(-0.35, -0.25, +0.30, 0, 0, 0, 0, 0)
ALPHA <- c(0.6, 0.5, 0.4, 0, 0, 0, 0, 0)
gen <- function(n, arm, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  Z <- matrix(rnorm(n * P), n, P)
  A <- if (arm == "A") rbinom(n, 1, .5)
       else rbinom(n, 1, 1/(1 + exp(-as.numeric(Z %*% ALPHA))))
  E <- sweep(Z, 2, THR, "<=")
  lp <- log(0.75)*A + Z %*% rep(0.55, P) + A * (E %*% GAM)
  t <- rexp(n, rate = 0.20 * exp(as.numeric(lp))); cens <- rexp(n, rate = 0.05)
  data.frame(t = pmin(t, cens), st = as.integer(t <= cens), A = A, as.data.frame(Z))
}
CRIT <- setNames(lapply(seq_len(P), function(k)
  local({ kk <- k; cut <- THR[k]; function(x) x[[paste0("V", kk)]] <= cut })), paste0("C", seq_len(P)))
PSOF <- list(A = paste0("V", 1:P), B = paste0("V", 1:P), C = paste0("V", 2:P))
prep_of <- function(d, arm) tp_prepare(d, CRIT, "A","t","st", PSOF[[arm]], tau = 8, min_per_arm = 3)
bits <- bitwShiftL(1L, 0:(P-1)); full <- seq_len(P); kF <- sum(bits[full]) + 1L

rows <- list()
for (arm in c("A","B","C")) {
  TEST <- prep_of(gen(1e5, arm, seed = 999), arm)
  V <- tp_enumerate(TEST)
  ok <- V[, "feasible"] == 1
  H <- V[, "logHR"]; H[!ok] <- NA_real_
  kBest <- which.min(H)
  ## The sentence in the Results is about "the estimator's population limit for the
  ## gap between protocols", which is the full protocol against the protocol the
  ## RULE converges to, not against the global oracle. Both are recorded; the text
  ## uses the rule-limit gap and the figure reads the same file.
  S0 <- which(tp_shapley(V, P, 1L) < 0); kR <- sum(bits[S0]) + 1L
  rows[[arm]] <- c(arm_i = match(arm, c("A","B","C")),
                   hr_full = exp(H[kF]), hr_best = exp(H[kBest]),
                   hr_rule = exp(H[kR]),
                   gap_oracle = unname(H[kF] - H[kBest]),
                   gap = unname(H[kF] - H[kR]),
                   n_full = exp(V[kF, "logN"]), n_best = exp(V[kBest, "logN"]),
                   n_rule = exp(V[kR, "logN"]), n_kept = length(S0))
  say(sprintf("arm %s : full HR %.4f | rule-limit HR %.4f | oracle HR %.4f | rule gap %.4f | oracle gap %.4f",
              arm, exp(H[kF]), exp(H[kR]), exp(H[kBest]), H[kF] - H[kR], H[kF] - H[kBest]))
}
T <- do.call(rbind, rows)
saveRDS(T, "analysis/out/confound_limits.rds")
say("ALL DONE")
