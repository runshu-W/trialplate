## trialplate :: unified engine ------------------------------------------------
## Supersedes core.R / core_fix.R / rmst.R.
## v(S) = ( log HR , RMST difference , log n )  -- two benefit estimands in
## parallel, because the hazard ratio is non-collapsible and the two can
## disagree (see the design note). Plus feasibility and tau-extrapolation flags.
## requires R/fastfit.R to be sourced first

## ---- preparation ----------------------------------------------------------
## Sorts by time ONCE so every subset is already ordered; builds the eligibility
## matrix (NA -> not filtered, Trial Pathfinder convention) and PS design matrix.
tp_prepare <- function(data, criteria, trt, time, status, ps_covars, tau = NULL,
                       ridge = 0.1, min_per_arm = 5) {
  d <- data[order(data[[time]]), , drop = FALSE]
  na_true <- function(x) { x[is.na(x)] <- TRUE; x }
  E <- vapply(criteria, function(f) na_true(f(d)), logical(nrow(d)))
  colnames(E) <- names(criteria)
  X <- stats::model.matrix(stats::as.formula(paste("~", paste(ps_covars, collapse = "+"))), d)
  if (is.null(tau)) tau <- stats::quantile(d[[time]][d[[status]] == 1], 0.90, names = FALSE)
  structure(list(d = d, E = E, X = X, p = ncol(E), names = colnames(E),
                 trt = as.integer(d[[trt]]), time = d[[time]], status = as.integer(d[[status]]),
                 tau = tau, ridge = ridge, min_per_arm = min_per_arm,
                 ps_start = NULL), class = "tp_prep")
}

## ---- logical implication detector -----------------------------------------
## If criterion i implies criterion j then v(S u {i,j}) == v(S u {i}) for every
## S, so the pairwise interaction index degenerates to minus the marginal
## contribution of j. Such cells are arithmetic, not evidence; they must be
## excluded from the test family and drawn differently.
tp_implications <- function(prep) {
  p <- prep$p; E <- prep$E; nm <- prep$names
  M <- matrix(FALSE, p, p, dimnames = list(nm, nm))
  for (i in seq_len(p)) for (j in seq_len(p)) if (i != j) M[i, j] <- all(E[, j] | !E[, i])
  determined <- matrix(FALSE, p, p, dimnames = list(nm, nm))
  for (i in seq_len(p)) for (j in seq_len(p)) if (i != j && (M[i, j] || M[j, i]))
    determined[i, j] <- determined[j, i] <- TRUE
  list(implies = M, determined = determined,
       pairs = if (any(M)) { w <- which(M, arr.ind = TRUE)
         data.frame(from = nm[w[, 1]], to = nm[w[, 2]], row.names = NULL) } else NULL)
}

## ---- value function -------------------------------------------------------
tp_value <- function(prep, S) {
  keep <- if (!length(S)) rep(TRUE, nrow(prep$E)) else
    .rowAlls(prep$E, S)
  n <- sum(keep)
  tr <- prep$trt[keep]; n1 <- sum(tr); n0 <- n - n1
  ti <- prep$time[keep]; st <- prep$status[keep]
  out <- c(logHR = NA_real_, rmstD = NA_real_, logN = log(max(n, 1)),
           feasible = 0, tau_ok = 1)
  if (n1 < prep$min_per_arm || n0 < prep$min_per_arm || sum(st) < 3L) return(out)
  Xs <- prep$X[keep, , drop = FALSE]
  e  <- tryCatch(fast_logit(Xs, tr, start = prep$ps_start), error = function(z) rep(mean(tr), n))
  e  <- pmin(pmax(e, 0.05), 0.95)
  w  <- tr / e + (1 - tr) / (1 - e)
  b  <- fast_cox_bin(ti, st, tr, w, theta = prep$ridge)
  i1 <- tr == 1L
  if (max(ti[i1]) < prep$tau || max(ti[!i1]) < prep$tau) out["tau_ok"] <- 0
  r1 <- fast_rmst(ti[i1],  st[i1],  w[i1],  prep$tau)
  r0 <- fast_rmst(ti[!i1], st[!i1], w[!i1], prep$tau)
  if (!is.finite(b)) return(out)
  out["logHR"] <- b; out["rmstD"] <- r1 - r0; out["feasible"] <- 1
  out
}
.rowAlls <- function(E, S) { r <- E[, S[1]]; for (j in S[-1]) r <- r & E[, j]; r }

## ---- exact enumeration over all 2^p subsets -------------------------------
tp_enumerate <- function(prep) {
  p <- prep$p
  ## warm-start the propensity model from the full cohort: subsets are subsets
  ## of the same population, so the coefficients are close.
  V <- matrix(NA_real_, 2^p, 5,
              dimnames = list(NULL, c("logHR","rmstD","logN","feasible","tau_ok")))
  bits <- bitwShiftL(1L, 0:(p - 1))
  for (k in 0:(2^p - 1)) V[k + 1L, ] <- tp_value(prep, which(bitwAnd(k, bits) > 0))
  V
}
.idx <- function(S, p) sum(bitwShiftL(1L, S - 1L)) + 1L

## ---- exact Shapley main effects and pairwise interactions -----------------
tp_shapley <- function(V, p, col) {
  lf <- lfactorial(0:p); phi <- numeric(p)
  for (i in seq_len(p)) {
    others <- setdiff(seq_len(p), i); tot <- 0
    for (k in 0:(2^(p - 1) - 1)) {
      S <- others[which(bitwAnd(k, bitwShiftL(1L, 0:(p - 2))) > 0)]; s <- length(S)
      tot <- tot + exp(lf[s + 1] + lf[p - s] - lf[p + 1]) *
        (V[.idx(c(S, i), p), col] - V[.idx(S, p), col])
    }
    phi[i] <- tot
  }
  phi
}
tp_interaction <- function(V, p, col) {
  lf <- lfactorial(0:p); I <- matrix(0, p, p)
  for (i in 1:(p - 1)) for (j in (i + 1):p) {
    others <- setdiff(seq_len(p), c(i, j)); m <- length(others); tot <- 0
    for (k in 0:(2^m - 1)) {
      S <- others[which(bitwAnd(k, bitwShiftL(1L, 0:max(m - 1, 0))) > 0)]; s <- length(S)
      tot <- tot + exp(lf[s + 1] + lf[p - s - 1] - lf[p]) *
        (V[.idx(c(S, i, j), p), col] - V[.idx(c(S, i), p), col] -
         V[.idx(c(S, j), p), col] + V[.idx(S, p), col])
    }
    I[i, j] <- I[j, i] <- tot
  }
  I
}

## ---- one full pass --------------------------------------------------------
OUTCOMES <- c(HR = 1L, RMST = 2L, N = 3L)
tp_fit <- function(prep, V = NULL) {
  p <- prep$p; if (is.null(V)) V <- tp_enumerate(prep)
  nf <- sum(V[, "feasible"] == 0); nt <- sum(V[, "tau_ok"] == 0)
  if (nf > 0) warning(sprintf("%d/%d subsets infeasible - Shapley sums are incomplete; drop a criterion or lower min_per_arm", nf, nrow(V)))
  res <- list(p = p, names = prep$names, V = V, tau = prep$tau,
              n_infeasible = nf, n_tau_extrapolated = nt,
              impl = tp_implications(prep))
  for (o in names(OUTCOMES)) {
    res[[paste0("phi_", o)]] <- tp_shapley(V, p, OUTCOMES[[o]])
    res[[paste0("I_",   o)]] <- tp_interaction(V, p, OUTCOMES[[o]])
  }
  res$v_empty <- V[1, ]; res$v_full <- V[2^p, ]
  res
}

## ---- interaction leverage: a design-stage diagnostic -----------------------
## For the common "extra benefit only for patients meeting BOTH criteria"
## structure, the four-point difference that drives the Shapley interaction is
## proportional to
##        L_ij = 1 - p_ij/p_i - p_ij/p_j + p_ij
## where p_i, p_j are marginal eligibility rates and p_ij the joint rate. L is
## computable BEFORE any outcome is touched. It vanishes as the criteria become
## permissive: two criteria that each keep 85% of the cohort have L ~ 0.02, so
## they cannot show an interaction however strong the underlying effect
## modification is. A null interaction therefore does NOT imply no effect
## modification - check the leverage first.
tp_leverage <- function(prep) {
  E <- prep$E; p <- prep$p; nm <- prep$names; n <- nrow(E)
  pm <- colMeans(E)
  L <- matrix(0, p, p, dimnames = list(nm, nm))
  for (i in 1:(p-1)) for (j in (i+1):p) {
    pij <- mean(E[, i] & E[, j])
    L[i, j] <- L[j, i] <- 1 - pij/pm[i] - pij/pm[j] + pij
  }
  attr(L, "marginal") <- pm
  L
}
