## Reviewer round 7, minor point 6. The matched comparison excludes the rule's own
## subset (m[kR] <- FALSE in primary.R) and uses strict inequalities, so a comparator
## that exactly ties the rule counts against it. We claimed ties were negligible
## without measuring them. This measures them.
source("analysis/_setup.R")
run <- function(dat, crit, ps, trt, tm, st, tau, R, label, seed = 101) {
  set.seed(seed); n <- nrow(dat); p <- length(crit); bits <- bitwShiftL(1L, 0:(p-1))
  res <- .tp_lapply(seq_len(R), function(r) {
    set.seed(seed*1000 + r)
    ix <- strat_split(dat, trt, st, 0.5)
    Vf <- tryCatch(tp_enumerate(tp_prepare(dat[ix,,drop=FALSE], crit,trt,tm,st,ps,tau=tau)),
                   error=function(e) NULL)
    if (is.null(Vf) || any(Vf[,"feasible"]==0)) return(NULL)
    S <- which(tp_shapley(Vf,p,1L) < 0)
    Vs <- tryCatch(tp_enumerate(tp_prepare(dat[-ix,,drop=FALSE], crit,trt,tm,st,ps,tau=tau)),
                   error=function(e) NULL)
    if (is.null(Vs)) return(NULL)
    ok <- Vs[,"feasible"]==1; N <- exp(Vs[,"logN"]); H <- Vs[,"logHR"]; RM <- Vs[,"rmstD"]
    kR <- sum(bits[S])+1L; if (!ok[kR]) return(NULL)
    m <- ok & abs(N-N[kR]) <= 0.10*N[kR]; m[kR] <- FALSE
    if (!sum(m)) return(NULL)
    c(n_comp = sum(m), ties_hr = sum(H[m]==H[kR]), ties_rm = sum(RM[m]==RM[kR]))
  }, 2L)
  M <- do.call(rbind, res[!vapply(res,is.null,logical(1))])
  o <- list(cohort = label, splits = nrow(M), comparators = mean(M[,"n_comp"]),
            tie_frac_hr = sum(M[,"ties_hr"])/sum(M[,"n_comp"]),
            tie_frac_rm = sum(M[,"ties_rm"])/sum(M[,"n_comp"]),
            splits_with_tie_hr = mean(M[,"ties_hr"] > 0))
  say(sprintf("%s: %d splits | %.1f comparators | HR ties %.5f of comparators | RMST ties %.5f | splits with any HR tie %.3f",
              label, o$splits, o$comparators, o$tie_frac_hr, o$tie_frac_rm, o$splits_with_tie_hr))
  o
}
out <- list(colon = run(colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825, 120, "colon"))
saveRDS(out, "analysis/out/comparator_ties.rds")
out$rott <- run(rott_data(), rott_criteria, rott_ps, "trt","dtime","death", 2555, 100, "rott")
saveRDS(out, "analysis/out/comparator_ties.rds")
say("ALL DONE")
