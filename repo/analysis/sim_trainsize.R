## W5-a  Is the W4 result ("the hazard-ratio promise does not survive out of
## sample") a small-training-set artefact? The real cohorts give the rule only
## 309 / 1491 patients to learn from, against roughly 5,167 per trial in the
## original work. Separate the two things that a 50/50 split confounds:
##   - TRAINING size  -> how well the rule finds the right criteria
##   - TEST     size  -> how precisely we can score what it found
## Here the test set is fixed at N = 1e5, so test noise is negligible and the
## sweep isolates training size alone.
##
## The DGP gives the rule something real to find: three criteria genuinely
## modify the treatment effect (two enrich benefit, one dilutes it), on top of
## strong prognostic heterogeneity so non-collapsibility is live.
source("analysis/_setup.R")

P <- 8L
CUT <- c(0.85, 0.75, 0.70, 0.90, 0.80, 0.85, 0.75, 0.90)      # per-criterion keep rate
THR <- qnorm(CUT)
GAM <- c(-0.35, -0.25, +0.30, 0, 0, 0, 0, 0)   # effect modification: 1,2 enrich; 3 dilutes
gen <- function(n, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  Z <- matrix(rnorm(n * P), n, P); A <- rbinom(n, 1, .5)
  E <- sweep(Z, 2, THR, "<=")                              # eligible on each criterion
  lp <- log(0.75)*A + Z %*% rep(0.55, P) + A * (E %*% GAM)
  t <- rexp(n, rate = 0.20 * exp(as.numeric(lp))); cens <- rexp(n, rate = 0.05)
  data.frame(t = pmin(t, cens), st = as.integer(t <= cens), A = A, as.data.frame(Z))
}
CRIT <- setNames(lapply(seq_len(P), function(k)
  local({ kk <- k; cut <- THR[k]; function(x) x[[paste0("V", kk)]] <= cut })),
  paste0("C", seq_len(P)))
PS <- paste0("V", seq_len(P))
prep_of <- function(d) tp_prepare(d, CRIT, "A","t","st", PS, tau = 8, min_per_arm = 3)

## ---- 1. is the rule even correct in the limit? ---------------------------
say("population behaviour of the rule (N = 3e5)")
CACHE <- "analysis/out/sim_rule_V0.rds"
V0 <- if (file.exists(CACHE)) readRDS(CACHE) else {
  v <- tp_enumerate(prep_of(gen(3e5, seed = 1))); saveRDS(v, CACHE); v }
phi0 <- tp_shapley(V0, P, 1L); keep0 <- which(phi0 < 0)
full <- seq_len(P); bits <- bitwShiftL(1L, 0:(P-1))
kidx <- function(S) sum(bits[S]) + 1L
say(sprintf("  phi_HR = %s", paste(sprintf("%+.3f", phi0), collapse = " ")))
say(sprintf("  rule keeps: %s", paste(names(CRIT)[keep0], collapse = ", ")))
say(sprintf("  full protocol : n = %6.0f  HR = %.4f", exp(V0[kidx(full),"logN"]), exp(V0[kidx(full),"logHR"])))
say(sprintf("  rule protocol : n = %6.0f  HR = %.4f", exp(V0[kidx(keep0),"logN"]), exp(V0[kidx(keep0),"logHR"])))
say(sprintf("  => in the limit the rule %s the hazard ratio",
    if (V0[kidx(keep0),"logHR"] < V0[kidx(full),"logHR"]) "LOWERS" else "does NOT lower"))
saveRDS(list(phi0=phi0, keep0=keep0, V0row_full=V0[kidx(full),], V0row_rule=V0[kidx(keep0),]),
        "analysis/out/sim_rule_truth.rds")

## ---- 2. sweep the TRAINING size, test set fixed and large ----------------
TEST <- prep_of(gen(1e5, seed = 999))
ev <- function(S) tp_value(TEST, S)
o_full <- ev(full)
say(sprintf("  fixed test set: full protocol n = %.0f, HR = %.4f, RMST = %+.3f",
    exp(o_full["logN"]), exp(o_full["logHR"]), o_full["rmstD"]))

R <- as.integer(Sys.getenv("TRN_R", "300"))
res <- list()
for (ntr in c(300L, 1000L, 3000L, 5167L, 20000L)) {
  out <- .tp_lapply(seq_len(R), function(r) tryCatch({
    pr <- prep_of(gen(ntr, seed = 4000 + 31*r + ntr))
    V <- tp_enumerate(pr); if (any(V[,"feasible"] == 0)) return(NULL)
    S <- which(tp_shapley(V, P, 1L) < 0); if (!length(S)) S <- integer(0)
    a <- ev(S)
    c(nsel = length(S), n = unname(exp(a["logN"])), hr = unname(exp(a["logHR"])),
      rm = unname(a["rmstD"]), match = as.numeric(setequal(S, keep0)))
  }, error = function(e) NULL), 2L)
  M <- do.call(rbind, out[!vapply(out, is.null, logical(1))])
  se <- function(x) sd(x)/sqrt(length(x))
  res[[as.character(ntr)]] <- list(n_train = ntr, R = nrow(M),
    p_lower_hr = mean(M[,"hr"] < exp(o_full["logHR"])),
    p_more_n   = mean(M[,"n"]  > exp(o_full["logN"])),
    d_hr = mean(M[,"hr"]) - exp(o_full["logHR"]), se_hr = se(M[,"hr"]),
    d_rm = mean(M[,"rm"]) - o_full["rmstD"],
    p_exact_rule = mean(M[,"match"]), mean_kept = mean(M[,"nsel"]))
  r <- res[[as.character(ntr)]]
  say(sprintf("n_train %6d  R=%3d | P(lower HR)=%.3f  P(more n)=%.3f | dHR %+.4f (se %.4f) | recovers the true rule %.3f | keeps %.1f/8",
      ntr, r$R, r$p_lower_hr, r$p_more_n, r$d_hr, r$se_hr, r$p_exact_rule, r$mean_kept))
  saveRDS(res, "analysis/out/sim_trainsize.rds")
}
say("ALL DONE")
