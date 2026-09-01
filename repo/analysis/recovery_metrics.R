## Reviewer minor point 2. Exact criterion-set recovery is an unnecessarily
## strict success criterion when several protocols perform almost identically.
## Reported here alongside it: Hamming distance, Jaccard similarity, false
## retention (a criterion the rule keeps that truly ought to be relaxed), false
## relaxation (the reverse), and REGRET -- how much worse the selected protocol
## is than the best attainable one, on the population scale where both are known.
source("analysis/_setup.R")

P <- 8L
CUT <- c(0.85, 0.75, 0.70, 0.90, 0.80, 0.85, 0.75, 0.90)
THR <- qnorm(CUT); GAM <- c(-0.35, -0.25, +0.30, 0, 0, 0, 0, 0)
gen <- function(n, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  Z <- matrix(rnorm(n * P), n, P); A <- rbinom(n, 1, .5)
  E <- sweep(Z, 2, THR, "<=")
  lp <- log(0.75)*A + Z %*% rep(0.55, P) + A * (E %*% GAM)
  t <- rexp(n, rate = 0.20 * exp(as.numeric(lp))); cs <- rexp(n, rate = 0.05)
  data.frame(t = pmin(t, cs), st = as.integer(t <= cs), A = A, as.data.frame(Z))
}
CRIT <- setNames(lapply(seq_len(P), function(k)
  local({ kk <- k; cut <- THR[k]; function(x) x[[paste0("V", kk)]] <= cut })), paste0("C", seq_len(P)))
prep_of <- function(d) tp_prepare(d, CRIT, "A","t","st", paste0("V", seq_len(P)), tau = 8, min_per_arm = 3)

say("population reference (N = 3e5)")
V0 <- { f <- "analysis/out/sim_rule_V0.rds"
        if (file.exists(f)) readRDS(f) else { v <- tp_enumerate(prep_of(gen(3e5, seed = 1))); saveRDS(v, f); v } }
keep0 <- which(tp_shapley(V0, P, 1L) < 0)            # what the rule converges to
best  <- which.min(ifelse(V0[, "feasible"] == 1, V0[, "logHR"], Inf))
bits  <- bitwShiftL(1L, 0:(P-1))
best_set <- which(bitwAnd(best - 1L, bits) > 0)
say(sprintf("  rule's limit set : %s  (population logHR %.4f)",
            paste(names(CRIT)[keep0], collapse=","), V0[sum(bits[keep0])+1L, "logHR"]))
say(sprintf("  best attainable  : %s  (population logHR %.4f)",
            paste(names(CRIT)[best_set], collapse=","), V0[best, "logHR"]))

TEST <- prep_of(gen(1e5, seed = 999))
lhr_of <- function(S) { v <- tp_value(TEST, S); if (v["feasible"] == 1) unname(v["logHR"]) else NA_real_ }
lhr_best <- lhr_of(best_set); lhr_full <- lhr_of(seq_len(P))

R <- as.integer(Sys.getenv("REC_R", "200"))
rows <- list()
for (ntr in c(300L, 1000L, 3000L, 5167L, 20000L)) {
  out <- .tp_lapply(seq_len(R), function(r) {
    pr <- prep_of(gen(ntr, seed = 4000 + 31*r + ntr))
    V <- tryCatch(tp_enumerate(pr), error = function(e) NULL)
    if (is.null(V) || any(V[, "feasible"] == 0)) return(NULL)
    S <- which(tp_shapley(V, P, 1L) < 0)
    inS <- seq_len(P) %in% S; in0 <- seq_len(P) %in% keep0
    c(exact = as.numeric(setequal(S, keep0)),
      hamming = sum(inS != in0),
      jaccard = if (sum(inS | in0)) sum(inS & in0)/sum(inS | in0) else 1,
      false_retain  = sum(inS & !in0) / max(1, sum(!in0)),
      false_relax   = sum(!inS & in0) / max(1, sum(in0)),
      regret = lhr_of(S) - lhr_best)
  }, 2L)
  M <- do.call(rbind, out[!vapply(out, is.null, logical(1))])
  rows[[as.character(ntr)]] <- c(n = ntr, R = nrow(M), colMeans(M, na.rm = TRUE),
                                 regret_med = median(M[,"regret"], na.rm = TRUE))
}
tab <- do.call(rbind, rows)
sink("analysis/out/recovery_metrics.txt", split = TRUE)
cat(sprintf("Set-recovery beyond exact match (%d criteria, R replicates per size)\n", P))
cat(sprintf("Regret is on the log hazard-ratio scale against the best attainable protocol\n"))
cat(sprintf("(full protocol regret = %+.4f for reference)\n\n", lhr_full - lhr_best))
cat(sprintf("%7s %5s %8s %9s %9s %13s %13s %10s\n",
    "n_fit","R","exact","hamming","jaccard","false retain","false relax","regret"))
for (i in seq_len(nrow(tab))) cat(sprintf("%7.0f %5.0f %8.3f %9.2f %9.3f %13.3f %13.3f %10.4f\n",
    tab[i,"n"], tab[i,"R"], tab[i,"exact"], tab[i,"hamming"], tab[i,"jaccard"],
    tab[i,"false_retain"], tab[i,"false_relax"], tab[i,"regret"]))
sink()
## the full protocol's own regret is the reference the rule has to beat, so it
## is saved rather than only printed
saveRDS(list(tab = tab, full_regret = unname(lhr_full - lhr_best),
             rule_limit_is_optimal = setequal(keep0, best_set)),
        "analysis/out/recovery_metrics.rds")
say("ALL DONE")
