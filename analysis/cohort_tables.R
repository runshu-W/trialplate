## Reviewer minor point 4 and major point 6. Everything a reader needs to judge
## the two criteria sets and the weighting: thresholds, marginal eligibility,
## missingness, pairwise correlation, retained events, and the propensity model
## with its balance, overlap and effective sample size.
source("analysis/_setup.R")

ALLS <- function(E, S) { r <- E[, S[1]]; for (j in S[-1]) r <- r & E[, j]; r }

## which raw variable does each criterion read? (for the missingness column)
VARS <- list(
  colon = c(AGE75="age", AGE40="age", NOOBS="obstruct", NOPRF="perfor",
            NOADH="adhere", DIFF12="differ", EXT13="extent", SURG0="surg", NOD4="node4"),
  rott  = c(AGE70="age", AGE30="age", ND9="nodes", NDPOS="nodes", SZ50="size_n",
            ERP="er", PGRP="pgr", YR85="year", YR90="year"))
LABEL <- list(
  colon = c(AGE75="age <= 75", AGE40="age >= 40", NOOBS="no obstruction",
            NOPRF="no perforation", NOADH="not adherent", DIFF12="differentiation <= 2",
            EXT13="extent <= 3", SURG0="short interval since surgery", NOD4="< 4 positive nodes"),
  rott  = c(AGE70="age <= 70", AGE30="age >= 30", ND9="nodes <= 9", NDPOS="nodes >= 1",
            SZ50="tumour size <= 50 mm", ERP="ER >= 10", PGRP="PgR >= 10",
            YR85="enrolled >= 1985", YR90="enrolled <= 1990"))

describe <- function(d, crit, ps, trt, tm, st, tau, key, label) {
  pr <- tp_prepare(d, crit, trt, tm, st, ps, tau = tau)
  p  <- pr$p; E <- pr$E; nm <- pr$names
  ## raw eligibility BEFORE the missing-as-eligible convention
  raw <- vapply(crit, function(f) { v <- f(d); mean(v, na.rm = TRUE) }, numeric(1))
  mis <- vapply(crit, function(f) mean(is.na(f(d))), numeric(1))
  cat(sprintf("\n================ %s  (n = %d, treated %d, events %d) ================\n",
              label, nrow(d), sum(pr$trt), sum(pr$status)))
  cat(sprintf("%-7s %-30s %8s %8s %9s %8s %8s\n",
              "code","definition","eligible","missing","evt kept","trt kept","ctl kept"))
  for (i in seq_len(p)) {
    k <- E[, i]
    cat(sprintf("%-7s %-30s %8.3f %8.3f %9d %8d %8d\n",
        nm[i], LABEL[[key]][nm[i]], raw[i], mis[i],
        sum(pr$status[k]), sum(pr$trt[k] == 1), sum(pr$trt[k] == 0)))
  }
  fullk <- ALLS(E, seq_len(p))
  cat(sprintf("\nFULL protocol: retains %d (%.1f%%), events %d, treated %d, control %d\n",
              sum(fullk), 100*mean(fullk), sum(pr$status[fullk]),
              sum(pr$trt[fullk]==1), sum(pr$trt[fullk]==0)))

  cat("\npairwise correlation of the eligibility indicators (phi):\n")
  C <- suppressWarnings(cor(E + 0))
  cat(sprintf("%-7s %s\n", "", paste(sprintf("%6s", nm), collapse="")))
  for (i in seq_len(p)) cat(sprintf("%-7s %s\n", nm[i],
      paste(sprintf("%6.2f", C[i, ]), collapse="")))
  cat(sprintf("max |off-diagonal correlation| = %.3f\n", max(abs(C[upper.tri(C)]))))

  ## ---- propensity model, balance, overlap, ESS (full protocol) -----------
  tr <- pr$trt[fullk]; X <- pr$X[fullk, , drop = FALSE]
  e  <- fast_logit(X, tr); e <- pmin(pmax(e, 0.05), 0.95)
  w  <- tr/e + (1-tr)/(1-e)
  smd <- function(x, g, ww = NULL) {
    if (is.null(ww)) ww <- rep(1, length(x))
    m1 <- weighted.mean(x[g==1], ww[g==1]); m0 <- weighted.mean(x[g==0], ww[g==0])
    v1 <- sum(ww[g==1]*(x[g==1]-m1)^2)/sum(ww[g==1]); v0 <- sum(ww[g==0]*(x[g==0]-m0)^2)/sum(ww[g==0])
    (m1-m0)/sqrt((v1+v0)/2)
  }
  cat("\npropensity model: main-effects logistic, no interactions or splines\n")
  cat(sprintf("  covariates: %s\n", paste(ps, collapse=", ")))
  cat(sprintf("  weights: unstabilised IPTW, e truncated to [0.05, 0.95]\n"))
  cat(sprintf("%-12s %12s %12s   %s\n", "covariate", "SMD before", "SMD after", "note"))
  cst <- character(0)
  for (v in colnames(X)[-1]) {
    x <- X[, v]
    if (stats::sd(x) == 0) {
      cst <- c(cst, v)
      cat(sprintf("%-12s %12s %12s   %s\n", v, "-", "-",
                  "constant inside the full protocol by construction"))
    } else cat(sprintf("%-12s %12.3f %12.3f\n", v, smd(x, tr), smd(x, tr, w)))
  }
  vv <- setdiff(colnames(X)[-1], cst)
  smds <- vapply(vv, function(v) abs(smd(X[,v], tr, w)), numeric(1))
  cat(sprintf("  max |SMD| after weighting = %.3f  (%d of %d non-degenerate above 0.10)\n",
              max(smds), sum(smds > 0.10), length(smds)))
  if (length(cst)) cat(sprintf("  %d covariate(s) are fixed by the criteria themselves and carry no balance information here: %s\n",
                               length(cst), paste(cst, collapse=", ")))
  cat(sprintf("  propensity range: [%.3f, %.3f]; %d truncated at 0.05/0.95\n",
              min(e), max(e), sum(e <= 0.05 | e >= 0.95)))
  cat(sprintf("  overlap: treated PS [%.3f, %.3f], control PS [%.3f, %.3f]\n",
              min(e[tr==1]), max(e[tr==1]), min(e[tr==0]), max(e[tr==0])))
  ess <- sum(w)^2/sum(w^2)
  cat(sprintf("  n = %d, effective sample size after weighting = %.0f (%.0f%%)\n",
              length(w), ess, 100*ess/length(w)))
  cat(sprintf("  weight range [%.2f, %.2f], max/mean = %.2f\n", min(w), max(w), max(w)/mean(w)))
  invisible(NULL)
}

sink("analysis/out/cohort_tables.txt", split = TRUE)
describe(colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825, "colon",
         "colon: adjuvant colon-cancer trial, Lev+5FU vs observation")
describe(rott_data(), rott_criteria, rott_ps, "trt","dtime","death", 2555, "rott",
         "Rotterdam: breast-cancer registry, chemotherapy vs none")
sink()
