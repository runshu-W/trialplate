## Reviewer round 2, major point 3. The previous analysis estimated a threshold
## per scenario, then computed coefficients of variation over the 6 scenarios in
## which a threshold was observable. That conditions on the outcome being
## uncensored and is a selection-biased comparison on 6 observations. The
## reviewer is right that it cannot support the claim that events and effective
## sample size travel worse than patients.
##
## Two replacements, both using all 16 scenarios.
##
## (a) FIXED-SAMPLE-SIZE COMPARISON. At each rung of the ladder every scenario
##     contributes a success probability, censored or not. Spread across
##     scenarios at a fixed size is the quantity of interest and needs no
##     threshold at all.
##
## (b) INTERVAL-CENSORED REGRESSION on log threshold, which uses the censored
##     runs as the interval information they are: right-censored runs contribute
##     (18000, Inf), the left-censored run (0, 600).
source("analysis/_setup.R")
suppressPackageStartupMessages(library(survival))

fa <- readRDS("analysis/out/factorial_threshold.rds")
LADDER <- c(600L, 2000L, 6000L, 18000L)

rows <- do.call(rbind, lapply(fa, function(r) {
  g <- r$grid; if (!length(g)) return(NULL)
  nv <- vapply(g, `[[`, numeric(1), "n")
  data.frame(run = r$row$run, p = r$sc$p, retain = r$sc$retain, nmod = r$sc$nmod,
             crate = r$sc$crate, alloc = r$sc$palloc, conf = r$sc$conf,
             n = nv,
             p_lower = vapply(g, `[[`, numeric(1), "p_lower"),
             R       = vapply(g, `[[`, numeric(1), "R"),
             events  = vapply(g, `[[`, numeric(1), "events"),
             ess     = vapply(g, `[[`, numeric(1), "ess"))
}))

sink("analysis/out/factorial_reanalysis.txt", split = TRUE)

cat("(a) Success probability at FIXED fitting size, all 16 scenarios\n")
cat("    concentrated = effect modification in 1-2 criteria; diffuse = spread over 5\n\n")
cat(sprintf("%8s %6s %28s %28s\n", "n_fit", "runs", "concentrated: median [min,max]", "diffuse: median [min,max]"))
for (nn in LADDER) {
  z <- rows[rows$n == nn, ]
  a <- z$p_lower[z$nmod == 2]; b <- z$p_lower[z$nmod == 5]
  cat(sprintf("%8d %6d %28s %28s\n", nn, nrow(z),
      sprintf("%.2f [%.2f, %.2f]", median(a), min(a), max(a)),
      sprintf("%.2f [%.2f, %.2f]", median(b), min(b), max(b))))
}
cat("\n    Monte Carlo SE of each cell probability is at most ")
cat(sprintf("%.3f (R = %d at the smallest rung)\n", sqrt(.25/min(rows$R)), min(rows$R)))

cat("\n(b) Spread of the success probability across scenarios at fixed size,\n")
cat("    with a bootstrap interval over scenarios\n\n")
bs_sd <- function(x, B = 2000) {
  s <- replicate(B, stats::sd(sample(x, replace = TRUE)))
  c(sd = stats::sd(x), lo = unname(quantile(s, .025)), hi = unname(quantile(s, .975)))
}
cat(sprintf("%8s %10s %22s\n", "n_fit", "SD across", "95% CI"))
for (nn in LADDER) {
  z <- rows$p_lower[rows$n == nn]; b <- bs_sd(z)
  cat(sprintf("%8d %10.3f %22s\n", nn, b["sd"], sprintf("[%.3f, %.3f]", b["lo"], b["hi"])))
}

cat("\n(c) Interval-censored regression of log threshold on the six factors\n")
cat("    right-censored runs contribute (18000, Inf); the left-censored run (0, 600)\n\n")
th <- do.call(rbind, lapply(fa, function(r) {
  t <- r$thr; if (is.null(t)) return(NULL)
  pg <- t$p_grid; left <- length(pg) && all(pg >= 0.80); right <- is.na(t$n_star)
  data.frame(run = r$row$run, p = factor(r$sc$p), retain = factor(r$sc$retain),
             nmod = factor(r$sc$nmod), crate = factor(r$sc$crate),
             alloc = factor(r$sc$palloc), conf = factor(r$sc$conf),
             lo = if (left) NA_real_ else if (right) 18000 else t$n_star,
             hi = if (left) 600 else if (right) NA_real_ else t$n_star)
}))
th$type <- ifelse(is.na(th$lo), "left", ifelse(is.na(th$hi), "right", "exact"))
cat(sprintf("  runs: %d exact, %d right-censored, %d left-censored\n\n",
            sum(th$type=="exact"), sum(th$type=="right"), sum(th$type=="left")))
sv <- survival::Surv(time = ifelse(is.na(th$lo), 1, th$lo),
                     time2 = ifelse(is.na(th$hi), NA, th$hi),
                     event = ifelse(th$type=="exact", 1, ifelse(th$type=="right", 0, 2)),
                     type = "interval")
fit <- survival::survreg(sv ~ nmod + p + retain + crate + alloc + conf,
                         data = th, dist = "lognormal")
co <- summary(fit)$table
cat("  multiplicative effect on the threshold (exp of coefficient), lognormal AFT\n")
cat(sprintf("%-14s %10s %10s %10s\n", "term", "x threshold", "95% lo", "95% hi"))
for (i in 2:(nrow(co))) {
  nmi <- rownames(co)[i]; if (nmi == "Log(scale)") next
  e <- co[i,1]; s <- co[i,2]
  cat(sprintf("%-14s %10.2f %10.2f %10.2f\n", nmi, exp(e), exp(e-1.96*s), exp(e+1.96*s)))
}
cat("\n  The concentration term is not estimable: all eight diffuse-modification runs\n")
cat("  are right-censored, so the likelihood is monotone in that coefficient and it\n")
cat("  is unbounded. That complete separation is itself the finding, but it means the\n")
cat("  regression cannot quantify the effect, and the remaining coefficients are\n")
cat("  estimated from 6 exact observations with correspondingly wide intervals. We\n")
cat("  therefore treat the fixed-size comparison in (a) as the primary analysis and\n")
cat("  this regression as supporting only.\n")

cat("\n(d) Is the events / ESS currency really worse? Same question, without\n")
cat("    conditioning on an observable threshold: spread of the success\n")
cat("    probability across scenarios at a fixed EVENT count and a fixed ESS.\n\n")
for (lab in c("events","ess")) {
  v <- rows[[lab]]
  brk <- stats::quantile(v, c(0, .25, .5, .75, 1), na.rm = TRUE)
  z <- cut(v, unique(brk), include.lowest = TRUE)
  cat(sprintf("  binned by %s:\n", lab))
  for (b in levels(z)) {
    k <- which(z == b)
    if (length(k) < 3) next
    cat(sprintf("    %-22s n cells %3d  P(lower) SD %.3f\n", b, length(k), stats::sd(rows$p_lower[k])))
  }
}
cat("\n  Compare with binning by fitting patients:\n")
z <- factor(rows$n)
for (b in levels(z)) {
  k <- which(z == b)
  cat(sprintf("    n = %-18s n cells %3d  P(lower) SD %.3f\n", b, length(k), stats::sd(rows$p_lower[k])))
}
sink()
saveRDS(list(rows = rows, th = th, aft = fit), "analysis/out/factorial_reanalysis.rds")
