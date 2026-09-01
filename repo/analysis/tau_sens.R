## Does the conclusion depend on where RMST is truncated?
##
## The selection rule acts on the Shapley value of the LOG HAZARD RATIO, so tau
## cannot touch which criteria get relaxed -- the eligible-count and hazard-ratio
## columns must come out identical at every tau, and if they don't, something is
## wrong. What tau can move is the RMST column, which is how the paper reports
## absolute benefit. Evaluate several tau in ONE pass over the splits rather than
## re-running the whole thing per tau.
source("R/fastfit.R"); source("R/engine.R"); source("R/infer.R"); source("demo/datasets.R")
say <- function(...) { cat(format(Sys.time(),"%H:%M:%S"), ..., "\n"); flush.console() }

rule_eval_taus <- function(prep, taus, R = 400L, frac = 0.5, cores = 2L, seed = 20260829) {
  p <- prep$p; bits <- bitwShiftL(1L, 0:(p - 1)); full <- seq_len(p)
  set.seed(seed + 6L); nn <- nrow(prep$E)
  idx <- lapply(seq_len(R), function(i) sample.int(nn, floor(frac * nn)))
  do.call(rbind, .tp_lapply(idx, function(tr) tryCatch({
    Ptr <- .reindex(prep, tr); Pte <- .reindex(prep, setdiff(seq_len(nn), tr))
    Vtr <- tp_enumerate(Ptr)
    if (any(Vtr[, "feasible"] == 0)) return(NULL)
    keep <- which(tp_shapley(Vtr, p, 1L) < 0)
    out <- c()
    for (tt in taus) {                       # only tau changes between passes
      Q <- Pte; Q$tau <- tt
      o <- tp_value(Q, full); a <- tp_value(Q, keep)
      out <- c(out, setNames(c(unname(exp(a["logN"]) - exp(o["logN"])),
                               unname(exp(a["logHR"]) - exp(o["logHR"])),
                               unname(a["rmstD"] - o["rmstD"])),
                             paste0(c("dn_","dhr_","drm_"), tt)))
    }
    out
  }, error = function(e) NULL), cores))
}

for (cfg in list(
  list(tag="colon", dat=colon_data(), cr=colon_criteria, ps=colon_ps,
       trt="trt", tm="time", st="status", taus=c(1095, 1460, 1825, 2190, 2555), R=400L),
  list(tag="rotterdam", dat=rott_data(), cr=rott_criteria, ps=rott_ps,
       trt="trt", tm="dtime", st="death", taus=c(1825, 2190, 2555, 2920, 3285), R=300L))) {
  prep <- tp_prepare(cfg$dat, cfg$cr, cfg$trt, cfg$tm, cfg$st, cfg$ps, tau = cfg$taus[3])
  M <- rule_eval_taus(prep, cfg$taus, R = cfg$R, cores = 2L)
  M <- M[complete.cases(M), , drop = FALSE]
  say(sprintf("=== %s  (R = %d) ===", cfg$tag, nrow(M)))
  for (tt in cfg$taus) {
    dn  <- M[, paste0("dn_",  tt)]; dhr <- M[, paste0("dhr_", tt)]
    drm <- M[, paste0("drm_", tt)]
    say(sprintf("  tau = %4.1f y | P(more n) %.3f | P(lower HR) %.3f | dRMST %+7.1f d  P(>0) %.3f",
        tt/365.25, mean(dn > 0), mean(dhr < 0), mean(drm), mean(drm > 0)))
  }
  saveRDS(M, sprintf("out/tau_%s.rds", cfg$tag))
}
say("ALL DONE")
