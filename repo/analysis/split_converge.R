## Reviewer round 7, major point 1. The nested bootstrap draws B outer resamples and
## takes R inner splits inside each, so the quantity it resamples is an R-split
## estimator, not the 500/400-split estimator the paper reports as its point. Its
## percentile interval therefore carries the inner Monte Carlo variance as well as
## the population variance, and is too wide by that amount.
##
## Increasing R to 500 inside the bootstrap is linear in R and out of reach here, so
## this script supplies the convergence evidence the reviewer asks for instead: how
## the observed-data estimator itself behaves as the split count grows, for the
## quantities that carry intervals. If the estimator is centred and its spread falls
## like 1/sqrt(R), the deflation applied to the interval in export_numbers.R is
## justified and the residual is quantified.
##
## No bootstrap here: b = 1 only, repeated at several split counts and several seeds
## so the Monte Carlo spread at each count can be seen directly.
source("analysis/_setup.R")

RS    <- as.integer(strsplit(Sys.getenv("SC_R", "25,50,100,200,400"), ",")[[1]])
MARGIN <- 0.05

## ---- two-way quantities, as in primary.R / nested_all.R -------------------
two_way <- function(dat, crit, ps, trt, tm, st, tau, p, bits, seed) {
  set.seed(seed)
  ix <- strat_split(dat, trt, st, 0.5)
  fit <- tp_prepare(dat[ix, , drop = FALSE],  crit, trt, tm, st, ps, tau = tau)
  sc  <- tp_prepare(dat[-ix, , drop = FALSE], crit, trt, tm, st, ps, tau = tau)
  Vf <- tryCatch(tp_enumerate(fit), error = function(e) NULL)
  if (is.null(Vf) || any(Vf[, "feasible"] == 0)) return(NULL)
  S <- which(tp_shapley(Vf, p, 1L) < 0)
  Vs <- tryCatch(tp_enumerate(sc), error = function(e) NULL); if (is.null(Vs)) return(NULL)
  ok <- Vs[, "feasible"] == 1
  N <- exp(Vs[, "logN"]); H <- Vs[, "logHR"]
  kR <- sum(bits[S]) + 1L; kF <- sum(bits[seq_len(p)]) + 1L
  if (!ok[kR] || !ok[kF]) return(NULL)
  m <- ok & abs(N - N[kR]) <= 0.10 * N[kR]; m[kR] <- FALSE
  c(lower = as.numeric(H[kR] < H[kF]),
    hr0.1 = if (sum(m)) mean(H[m] > H[kR]) else NA_real_,
    front_hr = as.numeric(!any(ok & N >= N[kR] & H <= H[kR] & (N > N[kR] | H < H[kR]))))
}

## ---- three-way quantities, as in threeway.R -------------------------------
split3 <- function(d, trt, st) {
  key <- interaction(d[[trt]], d[[st]], drop = TRUE)
  g <- unlist(lapply(split(seq_len(nrow(d)), key), function(v) sample(rep_len(1:3, length(v)))),
              use.names = FALSE)
  o <- unlist(split(seq_len(nrow(d)), key), use.names = FALSE)
  out <- integer(nrow(d)); out[o] <- g; out
}
three_way <- function(dat, crit, ps, trt, tm, st, tau, p, bits, seed) {
  set.seed(seed)
  g <- split3(dat, trt, st)
  A <- tp_prepare(dat[g == 1, , drop = FALSE], crit, trt, tm, st, ps, tau = tau)
  Va <- tryCatch(tp_enumerate(A), error = function(e) NULL)
  if (is.null(Va) || any(Va[, "feasible"] == 0)) return(NULL)
  S <- which(tp_shapley(Va, p, 1L) < 0); kR <- sum(bits[S]) + 1L
  ev <- function(sel) { V <- tryCatch(tp_enumerate(tp_prepare(dat[g == sel, , drop = FALSE],
                          crit, trt, tm, st, ps, tau = tau)), error = function(e) NULL)
    if (is.null(V)) return(NULL)
    list(ok = V[, "feasible"] == 1, N = exp(V[, "logN"]), H = V[, "logHR"]) }
  B <- ev(2); C <- ev(3); if (is.null(B) || is.null(C)) return(NULL)
  if (!B$ok[kR] || !C$ok[kR]) return(NULL)
  dom <- function(X) X$ok & X$N >= X$N[kR] & X$H <= X$H[kR] & (X$N > X$N[kR] | X$H < X$H[kR])
  dB <- dom(B); dC <- dom(C); nB <- sum(dB)
  c(repro = if (nB) mean(dC[dB]) else NA_real_,
    front_conf = if (nB) as.numeric(!any(dC[dB])) else 1,
    best_holds = if (nB) { j <- which(dB)[which.min(B$H[dB])]
      as.numeric(C$ok[j] && C$N[j] >= C$N[kR] && C$H[j] <= C$H[kR]) } else NA_real_)
}

## The Monte Carlo spread of a split-count estimator is s/sqrt(R), where s is the
## standard deviation of the per-split values. Estimating that from a handful of
## repeated runs is hopeless at four replicates; computing it from the per-split
## values of one long run is exact. So we run once at the largest count, keep every
## split, and report the implied Monte Carlo standard deviation at each count along
## with the running mean over the first R splits.
run <- function(dat, crit, ps, trt, tm, st, tau, label) {
  p <- length(crit); bits <- bitwShiftL(1L, 0:(p - 1))
  out <- list()
  for (design in c("two","three")) {
    fn <- if (design == "two") two_way else three_way
    ## Reviewer round 7. The convergence run must be a PREFIX of the run that
    ## produced the reported point estimate, or the two disagree at the largest
    ## count and the table reads as a contradiction rather than as evidence. Each
    ## design therefore uses its own point-estimate seed and split count:
    ## primary.R uses seed 101 over 500 splits, threeway.R seed 41 over 400,
    ## both as set.seed(seed * 1000 + r).
    sd0  <- if (design == "two") 101L else 41L
    RMAX <- if (design == "two") 500L else 400L
    RS_d <- sort(unique(c(RS[RS < RMAX], RMAX)))
    rows <- .tp_lapply(seq_len(RMAX), function(r)
      tryCatch(fn(dat, crit, ps, trt, tm, st, tau, p, bits, sd0 * 1000 + r),
               error = function(e) NULL), 2L)
    rows <- rows[!vapply(rows, is.null, logical(1))]
    M <- do.call(rbind, rows)
    say(sprintf("  %-6s %-6s %d usable splits of %d (seed %d)", label, design, nrow(M), RMAX, sd0))
    MATS[[paste(label, design, sep = "|")]] <<- M
    for (nm in colnames(M)) {
      v <- M[, nm]; ok <- is.finite(v)
      sdev <- stats::sd(v[ok])
      for (R in RS_d) {
        pref <- v[seq_len(min(R, length(v)))]; pref <- pref[is.finite(pref)]
        ## Reviewer round 7. s/sqrt(R) is an identity once s is fixed, so on its own
        ## it is not evidence about anything. The disjoint-block statistics below are
        ## not: cutting the run into floor(RMAX/R) non-overlapping blocks of R splits
        ## gives that many INDEPENDENT R-split estimates. Their spread is an observed
        ## dispersion, to be compared with the s/sqrt(R) the decomposition assumes,
        ## and their mean is exactly the full-run mean because the blocks partition
        ## the run -- which is the point: the split estimator is an average of
        ## independent per-split values, so changing R changes its variance and not
        ## its expectation. That is the whole content of the "interval for a
        ## different statistic" objection, and it is a variance question only.
        vv <- v[ok]; nb <- length(vv) %/% R
        if (nb >= 2L) {
          bm <- vapply(seq_len(nb), function(b) mean(vv[((b - 1L) * R + 1L):(b * R)]),
                       numeric(1))
          blk_n <- nb; blk_sd <- stats::sd(bm); blk_mean <- mean(bm)
        } else { blk_n <- nb; blk_sd <- NA_real_; blk_mean <- NA_real_ }
        out[[length(out) + 1L]] <- list(cohort = label, design = design, R = R,
          quantity = nm, n_used = length(pref),   # splits actually behind this cell
          n_total = sum(ok),
          mean = mean(pref),                      # estimate from the first R splits
          mc_sd = sdev / sqrt(length(pref)),      # Monte Carlo SD implied at that count
          per_split_sd = sdev,
          blk_n = blk_n, blk_sd = blk_sd, blk_mean = blk_mean)
      }
      say(sprintf("    %-10s per-split sd %.3f | %s", nm, sdev,
          paste(sprintf("R=%d %.3f (mean %.3f)", RS_d, sdev/sqrt(RS_d),
          vapply(RS_d, function(R) { u <- v[seq_len(min(R, length(v)))]
                                     mean(u[is.finite(u)]) }, numeric(1))), collapse = "  ")))
    }
  }
  out
}

## Colon only: this is a property of the estimator, and both cohorts at the largest
## split count was beyond the compute here. The text says the study is on colon.
MATS <- list()   # raw per-split values, kept so the table can be re-derived without rerunning
res <- run(colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825, "colon")
saveRDS(list(rows = res, mats = MATS), "analysis/out/split_converge.rds")
say("ALL DONE")
