## Reviewer round 4, major point 3. The frontier comparison in the observed
## cohorts builds the frontier and judges the rule against it on the SAME
## held-out half, so the comparator is the best of 512 noisy estimates evaluated
## where it was selected. Simulation (frontier_optimism.R) shows how large that
## optimism is when the population is known; this script measures the same thing
## inside the real cohorts, with no generating model, by splitting each cohort
## three ways:
##
##   A  fit    -- the Shapley scores and hence the rule's criterion set
##   B  select -- enumerate all subsets, record those that dominate the rule
##   C  test   -- re-evaluate exactly those subsets on untouched patients
##
## The quantities of interest are: how many apparent dominators on B still
## dominate on C, and whether the rule is off the frontier on B but on it on C.
## An honest reading of the main-text frontier numbers needs this ratio.
source("analysis/_setup.R")

MARGIN <- 0.05

split3 <- function(d, trt, st) {
  key <- interaction(d[[trt]], d[[st]], drop = TRUE)
  g <- unlist(lapply(split(seq_len(nrow(d)), key), function(v)
    sample(rep_len(1:3, length(v)))), use.names = FALSE)
  o <- unlist(split(seq_len(nrow(d)), key), use.names = FALSE)
  out <- integer(nrow(d)); out[o] <- g; out
}

run <- function(dat, crit, ps, trt, tm, st, tau, R, label, seed = 41) {
  set.seed(seed); p <- length(crit); full <- seq_len(p)
  bits <- bitwShiftL(1L, 0:(p - 1))
  res <- .tp_lapply(seq_len(R), function(r) {
    set.seed(seed * 1000 + r)
    g <- split3(dat, trt, st)
    A <- tp_prepare(dat[g == 1, , drop = FALSE], crit, trt, tm, st, ps, tau = tau)
    Va <- tryCatch(tp_enumerate(A), error = function(e) NULL)
    if (is.null(Va) || any(Va[, "feasible"] == 0)) return(NULL)
    S <- which(tp_shapley(Va, p, 1L) < 0); kR <- sum(bits[S]) + 1L
    ev <- function(sel) {
      V <- tryCatch(tp_enumerate(tp_prepare(dat[g == sel, , drop = FALSE],
                                            crit, trt, tm, st, ps, tau = tau)),
                    error = function(e) NULL)
      if (is.null(V)) return(NULL)
      list(ok = V[, "feasible"] == 1, N = exp(V[, "logN"]),
           H = V[, "logHR"], RM = V[, "rmstD"])
    }
    B <- ev(2); C <- ev(3); if (is.null(B) || is.null(C)) return(NULL)
    if (!B$ok[kR] || !C$ok[kR]) return(NULL)
    domset <- function(X) {
      X$ok & X$N >= X$N[kR] & X$H <= X$H[kR] & (X$N > X$N[kR] | X$H < X$H[kR])
    }
    dB <- domset(B); dC <- domset(C)
    nB <- sum(dB)
    ## of the subsets that dominate on B, how many also dominate on C?
    repro <- if (nB) mean(dC[dB]) else NA_real_
    ## a margin applied on B only, to see whether it selects dominators that last
    dBM <- B$ok & B$N >= B$N[kR] & B$H <= B$H[kR] - MARGIN
    reproM <- if (sum(dBM)) mean(dC[dBM]) else NA_real_
    c(n_domB = nB, n_domC = sum(dC),
      front_B = as.numeric(!any(dB)), front_C = as.numeric(!any(dC)),
      repro = repro, reproM = reproM, n_domBM = sum(dBM),
      ## the rule looks beaten on B; does the single best B-dominator still beat
      ## the rule on C?
      best_holds = if (nB) {
        j <- which(dB)[which.min(B$H[dB])]
        as.numeric(C$ok[j] && C$N[j] >= C$N[kR] && C$H[j] <= C$H[kR])
      } else NA_real_)
  }, 2L)
  M <- do.call(rbind, res[!vapply(res, is.null, logical(1))])
  m <- function(nm) { x <- M[, nm]; mean(x[is.finite(x)]) }
  md <- function(nm) { x <- M[, nm]; stats::median(x[is.finite(x)]) }
  say(sprintf("\n===== %s : %d three-way splits (tau = %d) =====", label, nrow(M), tau))
  say(sprintf("  dominating subsets, median: selection third %.0f | test third %.0f",
              md("n_domB"), md("n_domC")))
  say(sprintf("  rule on the frontier: selection third %.3f | test third %.3f",
              m("front_B"), m("front_C")))
  say(sprintf("  of subsets dominating on the selection third, %.3f still dominate on the test third",
              m("repro")))
  say(sprintf("  with a %.2f margin required on the selection third: %.3f (median %.0f qualify)",
              MARGIN, m("reproM"), md("n_domBM")))
  say(sprintf("  the single lowest-HR dominator carries over in %.3f of splits", m("best_holds")))
  M
}

out <- list()
out$colon <- run(colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825, 400, "colon")
saveRDS(out, "analysis/out/threeway.rds")
out$rott  <- run(rott_data(),  rott_criteria,  rott_ps,  "trt","dtime","death", 2555, 300, "Rotterdam")
saveRDS(out, "analysis/out/threeway.rds")
say("ALL DONE")
