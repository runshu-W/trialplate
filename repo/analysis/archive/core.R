## trialplate :: core engine -------------------------------------------------
## Dual-objective Shapley main effects + pairwise interactions for
## clinical-trial eligibility criteria, estimated by exact enumeration.
suppressPackageStartupMessages(library(survival))

## ---- 1. eligibility encoding ---------------------------------------------
## Each criterion is a function(data) -> logical vector.
## Trial Pathfinder convention: patients with MISSING data on a criterion are
## NOT filtered out by that criterion (NA -> TRUE).
na_true <- function(x) { x[is.na(x)] <- TRUE; x }

make_eligibility <- function(data, criteria) {
  M <- vapply(criteria, function(f) na_true(f(data)), logical(nrow(data)))
  colnames(M) <- names(criteria); M
}

## ---- 2. value function v(S) ----------------------------------------------
## Returns c(logHR, logN) for the cohort selected by criteria subset S.
## Treatment effect is estimated with IPTW-weighted Cox (mirrors Trial Pathfinder).
make_value_fn <- function(data, elig, trt, time, status, ps_covars,
                          min_n = 40, min_events = 10, min_per_arm = 10) {
  ps_form <- stats::as.formula(paste("trt__ ~", paste(ps_covars, collapse = " + ")))
  d0 <- data
  d0$trt__ <- trt; d0$time__ <- time; d0$status__ <- status

  function(S) {
    keep <- if (length(S) == 0) rep(TRUE, nrow(elig)) else
      Reduce(`&`, lapply(S, function(j) elig[, j]))
    d <- d0[keep, , drop = FALSE]
    n <- nrow(d)
    tab <- table(d$trt__)
    if (n < min_n || length(tab) < 2 || min(tab) < min_per_arm ||
        sum(d$status__) < min_events) return(c(logHR = NA_real_, logN = log(max(n, 1))))
    ## IPTW
    e <- tryCatch(stats::fitted(stats::glm(ps_form, family = binomial(), data = d)),
                  error = function(z) rep(mean(d$trt__), n), warning = function(z)
                    suppressWarnings(stats::fitted(stats::glm(ps_form, family = binomial(), data = d))))
    e <- pmin(pmax(e, 0.05), 0.95)                       # trim extreme weights
    w <- d$trt__ / e + (1 - d$trt__) / (1 - e)
    fit <- tryCatch(survival::coxph(Surv(time__, status__) ~ trt__, data = d, weights = w,
                                    robust = FALSE, control = coxph.control(iter.max = 25)),
                    error = function(z) NULL)
    if (is.null(fit)) return(c(logHR = NA_real_, logN = log(n)))
    c(logHR = unname(stats::coef(fit)[1]), logN = log(n))
  }
}

## ---- 3. exact enumeration over all 2^p subsets ---------------------------
## p <= ~16 is comfortable; above that switch to Monte Carlo.
enumerate_values <- function(v_fn, p) {
  keys <- 0:(2^p - 1)
  V <- matrix(NA_real_, nrow = length(keys), ncol = 2,
              dimnames = list(NULL, c("logHR", "logN")))
  for (k in keys) {
    S <- which(bitwAnd(k, bitwShiftL(1L, 0:(p - 1))) > 0)
    V[k + 1L, ] <- v_fn(S)
  }
  V
}
idx <- function(S, p) sum(bitwShiftL(1L, S - 1L)) + 1L

## ---- 4. Shapley main effects (exact) -------------------------------------
shapley_main <- function(V, p, outcome = 1L) {
  lf <- lfactorial(0:p)
  phi <- numeric(p)
  for (i in seq_len(p)) {
    others <- setdiff(seq_len(p), i)
    tot <- 0
    for (k in 0:(2^(p - 1) - 1)) {
      S <- others[which(bitwAnd(k, bitwShiftL(1L, 0:(p - 2))) > 0)]
      s <- length(S)
      w <- exp(lf[s + 1] + lf[p - s] - lf[p + 1])          # s!(p-s-1)!/p!
      d <- V[idx(c(S, i), p), outcome] - V[idx(S, p), outcome]
      if (is.finite(d)) tot <- tot + w * d
    }
    phi[i] <- tot
  }
  phi
}

## ---- 5. Shapley pairwise interaction index (Grabisch-Roubens, exact) -----
shapley_interaction <- function(V, p, outcome = 1L) {
  lf <- lfactorial(0:p)
  I <- matrix(0, p, p)
  for (i in 1:(p - 1)) for (j in (i + 1):p) {
    others <- setdiff(seq_len(p), c(i, j)); m <- length(others)
    tot <- 0
    for (k in 0:(2^m - 1)) {
      S <- others[which(bitwAnd(k, bitwShiftL(1L, 0:max(m - 1, 0))) > 0)]
      s <- length(S)
      w <- exp(lf[s + 1] + lf[p - s - 1] - lf[p])          # s!(p-s-2)!/(p-1)!
      d <- V[idx(c(S, i, j), p), outcome] - V[idx(c(S, i), p), outcome] -
           V[idx(c(S, j), p), outcome] + V[idx(S, p), outcome]
      if (is.finite(d)) tot <- tot + w * d
    }
    I[i, j] <- I[j, i] <- tot
  }
  I
}

## ---- 6. one full analysis pass -------------------------------------------
trialplate_fit <- function(data, criteria, trt, time, status, ps_covars) {
  elig <- make_eligibility(data, criteria); p <- ncol(elig)
  v <- make_value_fn(data, elig, data[[trt]], data[[time]], data[[status]], ps_covars)
  V <- enumerate_values(v, p)
  list(p = p, names = colnames(elig), V = V,
       phi_HR = shapley_main(V, p, 1L), phi_N = shapley_main(V, p, 2L),
       I_HR = shapley_interaction(V, p, 1L), I_N = shapley_interaction(V, p, 2L),
       v_empty = V[1, ], v_full = V[2^p, ],
       n_full = exp(V[2^p, 2]), n_empty = exp(V[1, 2]))
}
