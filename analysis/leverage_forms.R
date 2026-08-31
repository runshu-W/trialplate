## Reviewer major point 8. Two corrections and one extension.
##
## (a) "Structurally unidentifiable" is reserved for cells where the four-point
##     contrast is EXACTLY zero -- that is the logical-implication case, and it
##     is a property of the criteria alone. Small leverage is ATTENUATION: the
##     contrast is shrunk by a known factor, and detectability then depends on
##     effect size, outcome variance and sample size like any other test.
##
## (b) The published expression L = 1 - p_ij/p_i - p_ij/p_j + p_ij is derived
##     for ONE interaction form: extra benefit accruing only to patients who
##     meet BOTH criteria (an AND form). Here we derive and verify the
##     coefficient for two further forms, so a reader can see which structure
##     their own hypothesis has.
##
## Let q_i = P(E_i), q_ij = P(E_i & E_j) in the cohort a coalition selects. The
## four-point contrast that drives the Grabisch-Roubens index compares the mean
## benefit under {S}, {S,i}, {S,j}, {S,i,j}. Writing b(.) for the mean extra
## benefit in the selected cohort, the contrast is
##      D = b(ij) - b(i) - b(j) + b(0).
##
##   AND  form: extra benefit g only if BOTH met.  b(0)=g*q_ij, b(i)=g*q_ij/q_i,
##              b(j)=g*q_ij/q_j, b(ij)=g.   =>  D = g * (1 - q_ij/q_i - q_ij/q_j + q_ij)
##   OR   form: extra benefit g if EITHER met.     b(0)=g*q_or, b(i)=g, b(j)=g,
##              b(ij)=g, with q_or = q_i+q_j-q_ij
##                                          =>  D = g * (q_i + q_j - q_ij - 1)
##   XOR  form: benefit g only if EXACTLY one met. b(ij)=0, b(i)=g*(1-q_ij/q_i),
##              b(j)=g*(1-q_ij/q_j), b(0)=g*(q_i+q_j-2q_ij)
##                                          =>  D = g * (q_i + q_j - 2q_ij - 2 + q_ij/q_i + q_ij/q_j)
##
## Under INDEPENDENT criteria (q_ij = q_i q_j) all three collapse to a multiple
## of the same quantity:
##      AND -> +(1-q_i)(1-q_j)      OR -> -(1-q_i)(1-q_j)      XOR -> -2(1-q_i)(1-q_j)
## so the attenuation factor is form-independent up to sign and a constant. This
## is stronger than the original claim and also weaker in the way that matters:
## it is ATTENUATION by a known factor, not disappearance. Detectability is the
## attenuated effect against the usual sampling error, so it still depends on
## sample size -- "structurally unidentifiable" applies only where the factor is
## exactly zero, i.e. logical implication.
## Under correlated criteria the three expressions no longer coincide and the
## general forms below must be used.

source("analysis/_setup.R")

lev_and <- function(qi, qj, qij) 1 - qij/qi - qij/qj + qij
lev_or  <- function(qi, qj, qij) qi + qj - qij - 1
lev_xor <- function(qi, qj, qij) qi + qj - 2*qij - 2 + qij/qi + qij/qj

## ---- verify each coefficient against a simulation ------------------------
verify <- function(form, qi, qj, g = -0.60, n = 40000, seed = 5) {
  set.seed(seed)
  p <- 4L
  Z <- matrix(rnorm(n * p), n, p)
  t1 <- qnorm(qi); t2 <- qnorm(qj); trest <- qnorm(0.85)
  THR <- c(t1, t2, trest, trest)
  E <- sweep(Z, 2, THR, "<=")
  bonus <- switch(form,
    AND = E[,1] & E[,2],
    OR  = E[,1] | E[,2],
    XOR = xor(E[,1], E[,2]))
  A <- rbinom(n, 1, .5)
  lp <- log(0.80)*A + Z %*% rep(0.20, p) + g * A * bonus
  tt <- rexp(n, rate = 0.20*exp(as.numeric(lp))); cs <- rexp(n, rate = 0.03)
  d <- data.frame(t = pmin(tt, cs), st = as.integer(tt <= cs), A = A, as.data.frame(Z))
  CRIT <- setNames(lapply(1:p, function(k)
    local({kk<-k; ct<-THR[k]; function(x) x[[paste0("V",kk)]] <= ct})), paste0("C",1:p))
  pr <- tp_prepare(d, CRIT, "A","t","st", paste0("V",1:p), tau = 8, min_per_arm = 3)
  V  <- tp_enumerate(pr)
  I  <- tp_interaction(V, p, 1L)
  qij <- mean(E[,1] & E[,2])
  pred <- g * switch(form, AND = lev_and(qi,qj,qij), OR = lev_or(qi,qj,qij), XOR = lev_xor(qi,qj,qij))
  c(observed = I[1,2], predicted = pred, coef = pred/g, qij = qij)
}

sink("analysis/out/leverage_forms.txt", split = TRUE)
cat("Leverage coefficient by interaction form and eligibility rate\n")
cat("(coefficient multiplies the effect-modification magnitude g)\n\n")
LF <- list()
cat(sprintf("%-5s %6s %6s %10s %10s %10s\n","form","q_i","q_j","coef","predicted","observed"))
for (form in c("AND","OR","XOR"))
  for (q in c(0.45, 0.70, 0.85)) {
    r <- verify(form, q, q)
    cat(sprintf("%-5s %6.2f %6.2f %10.3f %10.4f %10.4f\n", form, q, q, r["coef"], r["predicted"], r["observed"]))
    LF[[paste(form, q)]] <- list(form = form, q = q, coef = unname(r["coef"]),
      predicted = unname(r["predicted"]), observed = unname(r["observed"]),
      rel_err = unname(r["predicted"]/r["observed"] - 1))
  }
cat("\nCoefficient as criteria become permissive (independent criteria, q_ij = q_i q_j):\n")
cat(sprintf("%6s %10s %10s %10s\n","q","AND","OR","XOR"))
for (q in c(0.30,0.45,0.60,0.70,0.80,0.85,0.90,0.95))
  cat(sprintf("%6.2f %10.3f %10.3f %10.3f\n", q,
      lev_and(q,q,q*q), lev_or(q,q,q*q), lev_xor(q,q,q*q)))
cat("\nUnder independence all three are multiples of (1-q_i)(1-q_j):\n")
cat(sprintf("%6s %12s %10s %10s %10s\n","q","(1-q)^2","AND","OR","XOR"))
for (q in c(0.45,0.70,0.85,0.90)) cat(sprintf("%6.2f %12.4f %10.4f %10.4f %10.4f\n",
    q, (1-q)^2, lev_and(q,q,q*q), lev_or(q,q,q*q), lev_xor(q,q,q*q)))
cat("\nSo the attenuation factor is form-independent up to sign and a constant.\n")
cat("It is attenuation by a known factor, NOT disappearance: the contrast is\n")
cat("shrunk, and whether the shrunken contrast is detectable remains a question\n")
cat("of effect size and sample size. Only an exactly zero factor -- the logical\n")
cat("implication case -- makes a cell structurally unidentifiable.\n")
cat("\nPrediction accuracy: the AND coefficient is accurate to a few per cent;\n")
cat("the OR and XOR coefficients are over-predicted by 10-30%% because the\n")
cat("derivation ignores the reweighting and non-collapsibility that operate when\n")
cat("the bonus reaches a large share of the cohort. They are order-of-magnitude\n")
cat("guides, not exact.\n")
sink()
saveRDS(LF, "analysis/out/leverage_forms_fit.rds")
