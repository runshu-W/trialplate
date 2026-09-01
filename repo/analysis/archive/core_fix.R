## FIX: v(S) must be finite for EVERY subset, or the Shapley sum is silently
## truncated and the efficiency axiom breaks. Ridge-penalised Cox keeps the
## treatment coefficient defined in thin strata; genuinely infeasible protocols
## (an empty or event-free arm) are counted and reported, never skipped quietly.
make_value_fn2 <- function(data, elig, trt, time, status, ps_covars,
                           ridge = 0.1, min_per_arm = 5) {
  ps_form <- stats::as.formula(paste("trt__ ~", paste(ps_covars, collapse = " + ")))
  d0 <- data; d0$trt__ <- trt; d0$time__ <- time; d0$status__ <- status
  function(S) {
    keep <- if (length(S) == 0) rep(TRUE, nrow(elig)) else
      Reduce(`&`, lapply(S, function(j) elig[, j]))
    d <- d0[keep, , drop = FALSE]; n <- nrow(d)
    n1 <- sum(d$trt__ == 1); n0 <- n - n1
    ev1 <- sum(d$status__[d$trt__ == 1]); ev0 <- sum(d$status__[d$trt__ == 0])
    if (n1 < min_per_arm || n0 < min_per_arm || ev1 + ev0 < 3)
      return(c(logHR = NA_real_, logN = log(max(n, 1)), feasible = 0))
    e <- tryCatch(suppressWarnings(stats::fitted(stats::glm(ps_form, binomial(), d))),
                  error = function(z) rep(mean(d$trt__), n))
    e <- pmin(pmax(e, 0.05), 0.95); w <- d$trt__/e + (1-d$trt__)/(1-e)
    fit <- tryCatch(suppressWarnings(survival::coxph(
             Surv(time__, status__) ~ ridge(trt__, theta = ridge), data = d,
             weights = w, control = coxph.control(iter.max = 40))),
           error = function(z) NULL)
    if (is.null(fit) || !is.finite(stats::coef(fit)[1]))
      return(c(logHR = NA_real_, logN = log(n), feasible = 0))
    c(logHR = unname(stats::coef(fit)[1]), logN = log(n), feasible = 1)
  }
}
enumerate2 <- function(v_fn, p) {
  V <- matrix(NA_real_, 2^p, 3, dimnames = list(NULL, c("logHR","logN","feasible")))
  for (k in 0:(2^p - 1)) V[k+1L, ] <- v_fn(which(bitwAnd(k, bitwShiftL(1L, 0:(p-1))) > 0))
  V
}
