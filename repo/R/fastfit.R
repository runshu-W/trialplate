## trialplate :: fast estimation kernel ---------------------------------------
## v(S) is evaluated 2^p times per fit and 2^p x B times per bootstrap, so the
## per-subset cost sets the whole project's compute budget. coxph()/glm() carry
## large formula-parsing and model-frame overhead that is pure waste here: the
## model is always "one binary covariate, IPT weights". These kernels solve the
## same equations directly.
##
## Key trick: the FULL dataset is sorted by time ONCE. Logical subsetting keeps
## ascending order, so no subset ever has to be re-sorted.

## Weighted Cox partial likelihood, single binary covariate, Breslow ties,
## optional ridge penalty. Newton-Raphson on the score.
## For binary x, x^2 == x, hence S2 == S1 and the information simplifies.
fast_cox_bin <- function(time, status, x, w, theta = 0.1, maxit = 50, tol = 1e-10) {
  n <- length(time); if (n < 2L) return(NA_real_)
  ev <- status == 1L; if (!any(ev)) return(NA_real_)
  dup <- duplicated(time)                 # time is already ascending
  grp <- cumsum(!dup); gstart <- which(!dup)
  gi  <- gstart[grp]                      # index of first row sharing this time
  wev <- w[ev]; xev <- x[ev]; giev <- gi[ev]
  num0 <- sum(wev * xev)
  b <- 0
  for (it in seq_len(maxit)) {
    ew <- w * exp(b * x)
    S0 <- rev(cumsum(rev(ew)))            # risk set: all rows with time >= t
    S1 <- rev(cumsum(rev(ew * x)))
    r  <- S1[giev] / S0[giev]
    U  <- num0 - sum(wev * r) - theta * b
    I  <- sum(wev * (r - r * r)) + theta
    if (!is.finite(I) || I <= 1e-12) return(NA_real_)
    step <- U / I
    if (!is.finite(step)) return(NA_real_)
    step <- max(min(step, 5), -5)         # damp wild steps in thin strata
    b <- b + step
    if (abs(step) < tol) break
  }
  b
}

## Weighted Kaplan-Meier restricted mean to tau, single arm.
fast_rmst <- function(time, status, w, tau) {
  n <- length(time); if (!n) return(tau)
  if (!any(status == 1L & time <= tau)) return(tau)
  ew  <- rev(cumsum(rev(w)))              # at-risk weight, time ascending
  gstart <- which(!duplicated(time))
  gend   <- c(gstart[-1] - 1L, n)
  cs  <- cumsum(w * (status == 1L))
  dw  <- cs[gend] - c(0, cs[gstart[-1] - 1L])   # weighted deaths per distinct time
  ut  <- time[gstart]
  nr  <- ew[gstart]
  k   <- ut <= tau & dw > 0
  if (!any(k)) return(tau)
  ut <- ut[k]; surv <- cumprod(pmax(0, 1 - dw[k] / nr[k]))
  ## area = sum over intervals of S(t) * width, S left-continuous
  edges <- c(ut, tau); prev <- c(0, ut)
  sum(c(1, surv)[seq_along(edges)] * (edges - prev))
}

## Fast IRLS logistic regression for the propensity score (warm-startable).
fast_logit <- function(X, y, maxit = 25, tol = 1e-8, start = NULL) {
  p <- ncol(X)
  b <- if (is.null(start) || length(start) != p) {
    v <- rep(0, p); v[1] <- log(mean(y) / (1 - mean(y)) + 1e-12); v } else start
  for (it in seq_len(maxit)) {
    eta <- drop(X %*% b); mu <- 1 / (1 + exp(-eta))
    v <- pmax(mu * (1 - mu), 1e-8)
    z <- eta + (y - mu) / v
    Xs <- X * sqrt(v)
    A <- crossprod(Xs); diag(A) <- diag(A) + 1e-6   # tiny ridge for separation
    nb <- tryCatch(drop(solve(A, crossprod(X, v * z))), error = function(e) NULL)
    if (is.null(nb)) break
    d <- max(abs(nb - b)); b <- nb
    if (d < tol) break
  }
  drop(1 / (1 + exp(-(X %*% b))))
}
