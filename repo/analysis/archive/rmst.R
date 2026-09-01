## trialplate :: collapsible estimand -----------------------------------------
## The hazard ratio is NON-COLLAPSIBLE: restricting to a subgroup changes the
## marginal HR even with no confounding and no effect modification. So a change
## in HR after applying a criterion is NOT by itself evidence that the criterion
## selects patients who benefit more. RMST difference is collapsible (the
## marginal RMST difference is a weighted average of subgroup differences), so
## re-running the whole pipeline on it separates real signal from artefact.
.wkm_rmst <- function(time, status, w, tau) {          # IPTW-weighted KM, area to tau
  o <- order(time); time <- time[o]; status <- status[o]; w <- w[o]
  atrisk <- rev(cumsum(rev(w)))
  ev <- status == 1 & time <= tau
  ut <- unique(time[ev]); if (!length(ut)) return(tau)
  S <- 1; prev <- 0; area <- 0
  for (t in ut) {
    d <- sum(w[time == t & status == 1]); n <- atrisk[which(time == t)[1]]
    area <- area + S * (t - prev); prev <- t
    S <- S * max(0, 1 - d / n)
  }
  area + S * (tau - prev)
}

make_value_fn_rmst <- function(data, elig, trt, time, status, ps_covars, tau,
                               min_n = 40, min_events = 10, min_per_arm = 10) {
  ps_form <- stats::as.formula(paste("trt__ ~", paste(ps_covars, collapse = " + ")))
  d0 <- data; d0$trt__ <- trt; d0$time__ <- time; d0$status__ <- status
  function(S) {
    keep <- if (length(S) == 0) rep(TRUE, nrow(elig)) else
      Reduce(`&`, lapply(S, function(j) elig[, j]))
    d <- d0[keep, , drop = FALSE]; n <- nrow(d); tab <- table(d$trt__)
    if (n < min_n || length(tab) < 2 || min(tab) < min_per_arm ||
        sum(d$status__) < min_events) return(c(rmstD = NA_real_, logN = log(max(n,1))))
    e <- tryCatch(suppressWarnings(stats::fitted(stats::glm(ps_form, binomial(), d))),
                  error = function(z) rep(mean(d$trt__), n))
    e <- pmin(pmax(e, 0.05), 0.95); w <- d$trt__/e + (1-d$trt__)/(1-e)
    i1 <- d$trt__ == 1
    r1 <- .wkm_rmst(d$time__[i1],  d$status__[i1],  w[i1],  tau)
    r0 <- .wkm_rmst(d$time__[!i1], d$status__[!i1], w[!i1], tau)
    c(rmstD = r1 - r0, logN = log(n))
  }
}
