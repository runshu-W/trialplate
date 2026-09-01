## trialplate :: nonparametric bootstrap -------------------------------------
## Gives (a) CIs and two-sided p-values for phi and I, and
##       (b) CRS = Criterion Relaxation Score, the SUCRA analogue built from
##           the bootstrap rank distribution of each criterion.
suppressPackageStartupMessages(library(parallel))

trialplate_boot <- function(data, criteria, trt, time, status, ps_covars,
                            B = 200, seed = 20260829, cores = max(1, detectCores())) {
  set.seed(seed); n <- nrow(data)
  idxs <- lapply(seq_len(B), function(b) sample.int(n, n, replace = TRUE))
  reps <- mclapply(idxs, function(ii) {
    tryCatch(trialplate_fit(data[ii, , drop = FALSE], criteria, trt, time, status, ps_covars),
             error = function(e) NULL)
  }, mc.cores = cores)
  reps[!vapply(reps, is.null, logical(1))]
}

## two-sided bootstrap p-value: 2 * min(P(x<=0), P(x>=0))
bp <- function(x) { x <- x[is.finite(x)]; if (!length(x)) return(NA_real_)
  2 * min(mean(x <= 0), mean(x >= 0)) }

summarise_boot <- function(fit, reps, level = 0.95) {
  a <- (1 - level) / 2; p <- fit$p; B <- length(reps)
  gm <- function(f) vapply(reps, f, numeric(p))            # p x B
  gI <- function(f) array(vapply(reps, f, numeric(p * p)), c(p, p, B))
  out <- list()
  for (o in c("HR", "N")) {
    ph <- gm(function(r) r[[paste0("phi_", o)]])
    Im <- gI(function(r) r[[paste0("I_",   o)]])
    out[[o]] <- list(
      phi     = fit[[paste0("phi_", o)]],
      phi_lo  = apply(ph, 1, quantile, a,     na.rm = TRUE),
      phi_hi  = apply(ph, 1, quantile, 1 - a, na.rm = TRUE),
      phi_p   = apply(ph, 1, bp),
      I       = fit[[paste0("I_", o)]],
      I_lo    = apply(Im, c(1, 2), quantile, a,     na.rm = TRUE),
      I_hi    = apply(Im, c(1, 2), quantile, 1 - a, na.rm = TRUE),
      I_p     = apply(Im, c(1, 2), bp),
      ## CRS: SUCRA analogue. Rank 1 = strongest case for relaxing this
      ## criterion (largest phi_HR = most harmful to the effect; most negative
      ## phi_N = most costly in patients). CRS in [0,100], higher = relax first.
      CRS = { R <- apply(if (o == "HR") ph else -ph, 2, function(v) rank(-v, na.last = "keep"))
              100 * (p - rowMeans(R, na.rm = TRUE)) / (p - 1) },
      B = B)
  }
  out$names <- fit$names; out
}
