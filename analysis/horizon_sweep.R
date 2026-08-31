## Reviewer round 4, major point 6. The restricted mean difference is reported at
## one horizon per cohort, and the RMST-selected rule variant is compared with the
## published rule at that same horizon only. Two things were missing: why those
## horizons, and how much of the disagreement between the two selection rules is a
## property of the estimand rather than of the particular tau.
##
## Horizon choice. tau must be inside the support of the follow-up in BOTH arms of
## every candidate protocol, or the restricted mean is not estimable on the same
## scale across subsets. We therefore report, for each cohort, the largest
## follow-up time observed in the smaller arm and the quantiles of the censoring
## distribution, and we take tau at roughly the point where a clear majority of
## patients are still under observation. The values used in the paper are
## colon 1825 days (5 years) and Rotterdam 2555 days (7 years); this script shows
## what they mean in terms of patients still at risk, and repeats the selection
## comparison at four horizons per cohort.
source("analysis/_setup.R")

at_risk <- function(d, tm, st, trt, taus) {
  for (tau in taus) {
    a <- vapply(sort(unique(d[[trt]])), function(g) {
      x <- d[[tm]][d[[trt]] == g]; mean(x >= tau) }, numeric(1))
    say(sprintf("    tau %5d d : still under observation %s",
                tau, paste(sprintf("arm %s %.2f", sort(unique(d[[trt]])), a), collapse = " | ")))
  }
}

agree <- function(dat, crit, ps, trt, tm, st, taus, R, label, seed) {
  say(sprintf("\n===== %s =====", label))
  say(sprintf("  maximum observed follow-up %.0f d; median %.0f d",
              max(dat[[tm]]), stats::median(dat[[tm]])))
  at_risk(dat, tm, st, trt, taus)
  p <- length(crit); bits <- bitwShiftL(1L, 0:(p - 1)); full <- seq_len(p)
  res <- lapply(taus, function(tau) {
    set.seed(seed); n <- nrow(dat)
    M <- .tp_lapply(seq_len(R), function(r) {
      set.seed(seed * 1000 + r)
      ix <- strat_split(dat, trt, st, 0.5)
      Vf <- tryCatch(tp_enumerate(tp_prepare(dat[ix, , drop=FALSE], crit, trt, tm, st, ps, tau = tau)),
                     error = function(e) NULL)
      if (is.null(Vf) || any(Vf[, "feasible"] == 0)) return(NULL)
      S1 <- which(tp_shapley(Vf, p, 1L) < 0); S2 <- which(tp_shapley(Vf, p, 2L) > 0)
      Vs <- tryCatch(tp_enumerate(tp_prepare(dat[-ix, , drop=FALSE], crit, trt, tm, st, ps, tau = tau)),
                     error = function(e) NULL)
      if (is.null(Vs)) return(NULL)
      ok <- Vs[, "feasible"] == 1
      k1 <- sum(bits[S1]) + 1L; k2 <- sum(bits[S2]) + 1L; kF <- sum(bits[full]) + 1L
      if (!ok[k1] || !ok[k2] || !ok[kF]) return(NULL)
      inter <- length(intersect(S1, S2)); uni <- length(union(S1, S2))
      c(same = as.numeric(setequal(S1, S2)),
        jac  = if (uni) inter/uni else 1,
        ham  = sum(!(seq_len(p) %in% S1) != !(seq_len(p) %in% S2)),
        n1 = unname(exp(Vs[k1, "logN"])), n2 = unname(exp(Vs[k2, "logN"])),
        rm1 = unname(Vs[k1, "rmstD"]), rm2 = unname(Vs[k2, "rmstD"]),
        rmF = unname(Vs[kF, "rmstD"]))
    }, 2L)
    M <- do.call(rbind, M[!vapply(M, is.null, logical(1))])
    say(sprintf("    tau %5d d : same set %.3f | Jaccard %.3f | mean Hamming %.2f | RMST full %+.1f, HR-rule %+.1f, RMST-rule %+.1f",
                tau, mean(M[,"same"]), mean(M[,"jac"]), mean(M[,"ham"]),
                mean(M[,"rmF"]), mean(M[,"rm1"]), mean(M[,"rm2"])))
    c(tau = tau, same = mean(M[,"same"]), jac = mean(M[,"jac"]), ham = mean(M[,"ham"]),
      rmF = mean(M[,"rmF"]), rm1 = mean(M[,"rm1"]), rm2 = mean(M[,"rm2"]), R = nrow(M))
  })
  do.call(rbind, res)
}

out <- list()
## Reviewer round 5, major point 1. The sweep ran at its own seed and split count,
## so its row at the main horizon was a SECOND estimate of a quantity the primary
## analysis already reports, and the two disagreed by Monte Carlo alone. It now uses
## the primary run's seed, split count and stratified split, so the main-horizon row
## reproduces the primary value exactly and the sweep shows only the horizon trend.
out$colon <- agree(colon_data(), colon_criteria, colon_ps, "trt","time","status",
                   c(1095, 1460, 1825, 2190), 500, "colon", seed = 101)
saveRDS(out, "analysis/out/horizon_sweep.rds")
out$rott  <- agree(rott_data(), rott_criteria, rott_ps, "trt","dtime","death",
                   c(1825, 2190, 2555, 2920), 400, "Rotterdam", seed = 101)
saveRDS(out, "analysis/out/horizon_sweep.rds")
say("ALL DONE")
