## Does the HR / RMST disagreement survive as an ESTIMAND property, or is it two
## noisy estimates being uncorrelated? Settle it where the truth is known and
## sampling noise is negligible (n = 200,000 per scenario, no model fitting).
##
## Two data-generating processes, each null for ONE estimand by construction:
##  A. Proportional hazards       -> the conditional HR is constant in Z,
##                                   so a criterion on Z has NO true effect on
##                                   relative benefit. Any phi_HR is artefact.
##  B. Constant absolute benefit  -> the hazard DIFFERENCE is constant in Z,
##                                   so a criterion on Z has NO true effect on
##                                   absolute benefit. Any phi_RMST is artefact.
set.seed(20260829); N <- 2e5; tau <- 5

rmst_true <- function(t, tau) mean(pmin(t, tau))          # no censoring -> exact
run <- function(dgp) {
  Z <- rnorm(N); A <- rbinom(N, 1, .5)
  if (dgp == "PH") {                                       # h = h0 * exp(bA*A + bZ*Z)
    lp <- log(0.6)*A + 0.9*Z
    t  <- rexp(N, rate = 0.25*exp(lp))
  } else {                                                 # additive: h = l0 + g*exp(Z) + d*A
    h  <- 0.10 + 0.30*exp(0.9*Z - 0.405) - 0.05*A          # constant hazard DIFFERENCE
    h  <- pmax(h, 1e-4)
    t  <- rexp(N, rate = h)
  }
  ## marginal contrasts on the whole cohort and on the eligible subgroup Z <= 0
  est <- function(k) {
    cx <- coef(survival::coxph(survival::Surv(t[k], rep(1, sum(k))) ~ A[k]))[1]
    c(logHR = unname(cx),
      rmstD = rmst_true(t[k & A == 1], tau) - rmst_true(t[k & A == 0], tau))
  }
  all <- est(rep(TRUE, N)); sub <- est(Z <= 0)
  ## with a single criterion the Shapley value is just v({C}) - v(empty)
  c(phi_logHR = sub["logHR"] - all["logHR"], phi_rmstD = sub["rmstD"] - all["rmstD"],
    HR_all = exp(all["logHR"]), HR_sub = exp(sub["logHR"]),
    RM_all = all["rmstD"], RM_sub = sub["rmstD"])
}
for (g in c("PH","ADD")) {
  r <- run(g)
  cat(sprintf("\n--- DGP %s ---\n", g))
  cat(sprintf("  whole cohort : HR = %.4f   RMST diff = %+.4f\n", r["HR_all.logHR"], r["RM_all.rmstD"]))
  cat(sprintf("  Z <= 0       : HR = %.4f   RMST diff = %+.4f\n", r["HR_sub.logHR"], r["RM_sub.rmstD"]))
  cat(sprintf("  phi on log HR = %+.4f      phi on RMST = %+.4f\n",
              r["phi_logHR.logHR"], r["phi_rmstD.rmstD"]))
}
