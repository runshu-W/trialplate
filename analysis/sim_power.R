source("analysis/_setup.R")
## ---- population truth ------------------------------------------------------
say("computing population truth (N = 3e5)")
truth <- one(gen(3e5, seed = 1))
I0 <- truth$I; cat(sprintf("  true I_12 (log HR) = %+.4f   |  median |I| over the other 27 pairs = %.4f\n",
   I0[1,2], median(abs(I0[upper.tri(I0)][-1]))))
saveRDS(truth, "analysis/out/sim_truth.rds")

## ---- sampling distribution at each n --------------------------------------
NS <- c(600, 1500, 4000, 10000); R <- as.integer(Sys.getenv("SIM_R", "300"))
res <- list()
for (n in NS) {
  say("n =", n, " reps =", R)
  reps <- .tp_lapply(seq_len(R), function(r)
    tryCatch(one(gen(n, seed = 1000 + 97 * r + n))$I, error = function(e) NULL), 2L)
  reps <- reps[!vapply(reps, is.null, logical(1))]
  I12 <- vapply(reps, function(M) M[1, 2], numeric(1))
  nulls <- do.call(c, lapply(reps, function(M) M[upper.tri(M)][-1]))   # the other 27 pairs
  se <- sd(I12)
  pw <- function(a) mean(abs(I12) > qnorm(1 - a/2) * se)
  fp <- function(a) mean(abs(nulls) > qnorm(1 - a/2) * sd(nulls))
  res[[as.character(n)]] <- list(n = n, R = length(reps), mean = mean(I12), bias = mean(I12) - I0[1,2],
    se = se, power05 = pw(.05), power_bonf = pw(.05/28), fp05 = fp(.05), nulls_sd = sd(nulls),
    null_mean_abs = mean(abs(nulls)))
  say(sprintf("   mean %+.4f  bias %+.4f  SE %.4f  power(.05) %.3f  power(.05/28) %.3f",
      mean(I12), mean(I12)-I0[1,2], se, pw(.05), pw(.05/28)))
  saveRDS(res, "analysis/out/sim_power.rds")
}
say("ALL DONE")
