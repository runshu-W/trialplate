## Reviewer round 4, major point 1. The main text and the supplement reported
## different point estimates of the same quantities. The reviewer attributed this
## to Monte Carlo noise between analyses run at different split counts. The real
## cause was worse: Table 1 was produced with the Rotterdam endpoint (dtime,
## death) at tau = 2555, while every analysis added in the later revisions used
## (rtime, death) at tau = 1825 — pairing the relapse-free TIME with the DEATH
## indicator, which is not a valid pair and systematically shortens event times.
## All scripts now use (dtime, death) with tau = 2555 for Rotterdam and (time,
## status) with tau = 1825 for colon, and this script is the single source of
## every observed-cohort point estimate so the two documents cannot diverge again.
##
## One loop, one results file. Everything the main text and the supplement quote
## as a point estimate comes from here, at the full split count. The nested
## bootstrap supplies uncertainty only.
source("analysis/_setup.R")

BANDS <- c(0.02, 0.05, 0.10, 0.15)
MARGIN <- 0.05                 # on the LOG hazard ratio; see the text

strat_split <- function(d, trt, st, frac) {
  key <- interaction(d[[trt]], d[[st]], drop = TRUE)
  unlist(lapply(split(seq_len(nrow(d)), key), function(ix)
    if (length(ix) < 2) ix else sample(ix, max(1, floor(frac * length(ix))))))
}

run <- function(dat, crit, ps, trt, tm, st, tau, R, label, seed = 101) {
  set.seed(seed); n <- nrow(dat); p <- length(crit); full <- seq_len(p)
  bits <- bitwShiftL(1L, 0:(p - 1))
  res <- .tp_lapply(seq_len(R), function(r) {
    set.seed(seed * 1000 + r)
    ix <- strat_split(dat, trt, st, 0.5)
    fit <- tp_prepare(dat[ix, , drop=FALSE],  crit, trt, tm, st, ps, tau = tau)
    sc  <- tp_prepare(dat[-ix, , drop=FALSE], crit, trt, tm, st, ps, tau = tau)
    Vf <- tryCatch(tp_enumerate(fit), error = function(e) NULL)
    if (is.null(Vf) || any(Vf[, "feasible"] == 0)) return(NULL)
    S_hr <- which(tp_shapley(Vf, p, 1L) < 0)
    S_rm <- which(tp_shapley(Vf, p, 2L) > 0)
    Vs <- tryCatch(tp_enumerate(sc), error = function(e) NULL); if (is.null(Vs)) return(NULL)
    ok <- Vs[, "feasible"] == 1
    N <- exp(Vs[, "logN"]); H <- Vs[, "logHR"]; RM <- Vs[, "rmstD"]
    kR <- sum(bits[S_hr])+1L; kM <- sum(bits[S_rm])+1L; kF <- sum(bits[full])+1L
    if (!ok[kR] || !ok[kF] || !ok[kM]) return(NULL)
    nR <- N[kR]; hR <- H[kR]; rR <- RM[kR]
    o <- c(n_full=N[kF], n_rule=nR, hr_full=exp(H[kF]), hr_rule=exp(hR),
           rm_full=RM[kF], rm_rule=rR,
           more = as.numeric(nR > N[kF]), lower = as.numeric(hR < H[kF]),
           greater = as.numeric(rR > RM[kF]))
    for (b in BANDS) {
      m <- ok & abs(N - nR) <= b*nR; m[kR] <- FALSE
      o[paste0("hr",b)] <- if (sum(m)) mean(H[m] > hR) else NA_real_
      o[paste0("rm",b)] <- if (sum(m)) mean(RM[m] < rR) else NA_real_
      o[paste0("nm",b)] <- sum(m)
      o[paste0("sk",b)] <- if (sum(m)) mean((N[m]-nR)/nR) else NA_real_
    }
    dom  <- ok & N >= nR & H <= hR & (N > nR | H < hR)
    domM <- ok & N >= nR & H <= hR - MARGIN
    domR <- ok & N >= nR & RM >= rR & (N > nR | RM > rR)
    o["front_hr"]  <- as.numeric(!any(dom)); o["front_rm"] <- as.numeric(!any(domR))
    o["front_hrM"] <- as.numeric(!any(domM))
    o["n_dom"] <- sum(dom); o["n_domM"] <- sum(domM)
    ## the RMST-selected variant, from the same fitting half
    o["same_set"]  <- as.numeric(setequal(S_hr, S_rm))
    o["n_rmrule"]  <- N[kM]
    o["rmrule_lower"]   <- as.numeric(H[kM] < H[kF])
    o["rmrule_greater"] <- as.numeric(RM[kM] > RM[kF])
    o["hr_rmrule"] <- exp(H[kM]); o["rm_rmrule"] <- RM[kM]
    o
  }, 2L)
  M <- do.call(rbind, res[!vapply(res, is.null, logical(1))])
  saveRDS(list(M = M, R = nrow(M), R_requested = R, BANDS = BANDS, MARGIN = MARGIN,
               tau = tau, time_var = tm, status_var = st),
          sprintf("analysis/out/primary_%s.rds", label))
  m <- function(k) mean(M[, k], na.rm = TRUE)
  say(sprintf("\n===== %s : %d splits, endpoint (%s, %s), tau = %d =====",
              label, nrow(M), tm, st, tau))
  say(sprintf("  full protocol  : n %.0f | HR %.4f | RMST %+.1f", m("n_full"), m("hr_full"), m("rm_full")))
  say(sprintf("  rule protocol  : n %.0f | HR %.4f | RMST %+.1f", m("n_rule"), m("hr_rule"), m("rm_rule")))
  say(sprintf("  P(more) %.3f | P(lower HR) %.3f | P(greater RMST) %.3f",
              m("more"), m("lower"), m("greater")))
  say(sprintf("  matched HR  %s", paste(sprintf("%.0f%%:%.3f", 100*BANDS,
      vapply(BANDS, function(b) m(paste0("hr",b)), numeric(1))), collapse="  ")))
  say(sprintf("  matched RMST %s", paste(sprintf("%.0f%%:%.3f", 100*BANDS,
      vapply(BANDS, function(b) m(paste0("rm",b)), numeric(1))), collapse="  ")))
  say(sprintf("  frontier HR %.3f | RMST %.3f | margin %.3f | dominating %.0f (margin %.0f)",
      m("front_hr"), m("front_rm"), m("front_hrM"), m("n_dom"), m("n_domM")))
  say(sprintf("  RMST-rule: same set %.3f | n %.0f | P(lower HR) %.3f | P(greater RMST) %.3f",
      m("same_set"), m("n_rmrule"), m("rmrule_lower"), m("rmrule_greater")))
  invisible(M)
}

run(colon_data(), colon_criteria, colon_ps, "trt","time","status",  1825, 500L, "colon")
run(rott_data(),  rott_criteria,  rott_ps,  "trt","dtime","death",  2555, 400L, "rott")
say("ALL DONE")
