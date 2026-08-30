library(testthat); library(survival); library(trialplate)

prep  <- tp_prepare(colon_data(), colon_criteria, "trt","time","status", colon_ps, tau = 1825)
fit   <- tp_fit(prep)

test_that("fast Cox kernel reproduces survival::coxph with Breslow ties", {
  set.seed(3); d <- prep$d; w <- runif(nrow(d), .4, 2.2)
  a <- fast_cox_bin(prep$time, prep$status, prep$trt, w, theta = 0)
  b <- coef(coxph(Surv(prep$time, prep$status) ~ prep$trt, weights = w, ties = "breslow"))[1]
  expect_equal(a, unname(b), tolerance = 1e-9)
})

test_that("fast Cox kernel reproduces coxph ridge(scale = FALSE)", {
  set.seed(4); w <- runif(length(prep$time), .4, 2.2)
  a <- fast_cox_bin(prep$time, prep$status, prep$trt, w, theta = 0.5)
  b <- coef(coxph(Surv(prep$time, prep$status) ~ ridge(prep$trt, theta = .5, scale = FALSE),
                  weights = w, ties = "breslow"))[1]
  expect_equal(a, unname(b), tolerance = 1e-8)
})

test_that("fast weighted RMST reproduces survfit rmean", {
  set.seed(5); w <- runif(length(prep$time), .4, 2.2); i1 <- prep$trt == 1
  sf <- survfit(Surv(prep$time[i1], prep$status[i1]) ~ 1, weights = w[i1])
  expect_equal(fast_rmst(prep$time[i1], prep$status[i1], w[i1], 1825),
               unname(summary(sf, rmean = 1825)$table[["rmean"]]), tolerance = 1e-6)
})

test_that("every subset is feasible, so the Shapley sums are complete", {
  expect_equal(fit$n_infeasible, 0)
})

test_that("efficiency axiom holds exactly for all three outcomes", {
  for (o in names(OUTCOMES)) {
    k <- OUTCOMES[[o]]
    expect_equal(sum(fit[[paste0("phi_", o)]]),
                 unname(fit$v_full[k] - fit$v_empty[k]), tolerance = 1e-10,
                 label = paste("efficiency for", o))
  }
})

test_that("interaction matrices are symmetric with a zero diagonal", {
  for (o in names(OUTCOMES)) {
    I <- fit[[paste0("I_", o)]]
    expect_equal(I, t(I), tolerance = 1e-12)
    expect_true(all(diag(I) == 0))
  }
})

test_that("exact enumeration matches permutation Monte Carlo Shapley", {
  set.seed(11); p <- fit$p; V <- fit$V; B <- 4000
  acc <- matrix(0, p, 3)
  for (b in seq_len(B)) {
    S <- integer(0); prev <- V[.idx(S, p), 1:3]
    for (i in sample(p)) { S <- c(S, i); cur <- V[.idx(S, p), 1:3]
      acc[i, ] <- acc[i, ] + (cur - prev); prev <- cur }
  }
  mc <- acc / B
  expect_equal(mc[, 1], fit$phi_HR,   tolerance = 0.01)
  expect_equal(mc[, 3], fit$phi_N,    tolerance = 0.01)
})

test_that("the primary criteria set contains no logical implications", {
  expect_null(fit$impl$pairs)
  expect_true(!any(fit$impl$determined))
})

test_that("the implication detector finds a deliberately nested criterion, and that cell is an identity", {
  pn <- tp_prepare(colon_data(), colon_criteria_nested, "trt","time","status", colon_ps, tau = 1825)
  im <- tp_implications(pn)
  expect_true(!is.null(im$pairs))
  expect_true(any(im$pairs$from == "NOD4" & im$pairs$to == "ND10"))
  ## v(S u {i,j}) == v(S u {j}) must hold for EVERY S when j implies i
  V <- tp_enumerate(pn); p <- pn$p
  i <- match("ND10", pn$names); j <- match("NOD4", pn$names)
  oth <- setdiff(seq_len(p), c(i, j)); m <- length(oth); worst <- 0
  for (k in 0:(2^m - 1)) {
    S <- oth[which(bitwAnd(k, bitwShiftL(1L, 0:(m-1))) > 0)]
    worst <- max(worst, abs(V[.idx(c(S,i,j), p), "logN"] - V[.idx(c(S,j), p), "logN"]))
  }
  expect_equal(worst, 0)
})

test_that("a criterion nobody fails is a null player: phi is exactly zero", {
  cr <- c(colon_criteria[1:4], list(ALLPASS = function(x) rep(TRUE, nrow(x))))
  p2 <- tp_prepare(colon_data(), cr, "trt","time","status", colon_ps, tau = 1825)
  f2 <- tp_fit(p2); k <- match("ALLPASS", f2$names)
  expect_equal(f2$phi_HR[k],   0, tolerance = 1e-12)
  expect_equal(f2$phi_RMST[k], 0, tolerance = 1e-12)
  expect_equal(f2$phi_N[k],    0, tolerance = 1e-12)
})

test_that("bootstrap is reproducible from the seed", {
  a <- tp_boot(prep, B = 6L, cores = 1L, seed = 99)
  b <- tp_boot(prep, B = 6L, cores = 1L, seed = 99)
  expect_equal(vapply(a, function(r) r$phi[,1], numeric(prep$p)),
               vapply(b, function(r) r$phi[,1], numeric(prep$p)))
})

test_that("BCa p-value is consistent with its own interval", {
  set.seed(7); tb <- rnorm(1200, 0.5, 0.2); tj <- rnorm(50, 0.5, 0.2)
  pp <- .bca_p(0.5, tb, tj)
  expect_true(pp < 0.05)
  expect_true(prod(.bca_bounds(0.5, tb, tj, pp * 1.02)) > 0)   # excludes 0 just above p
  expect_true(prod(.bca_bounds(0.5, tb, tj, pp * 0.90)) < 0)   # contains 0 just below
})

## ---- interaction leverage --------------------------------------------------
test_that("leverage matches its definition computed directly", {
  L <- tp_leverage(prep); E <- prep$E; nm <- prep$names
  i <- 1; j <- 4
  pi_ <- mean(E[, i]); pj <- mean(E[, j]); pij <- mean(E[, i] & E[, j])
  expect_equal(L[i, j], 1 - pij/pi_ - pij/pj + pij, tolerance = 1e-12)
  expect_equal(L, t(L), tolerance = 1e-12)
})

test_that("a criterion nobody fails has zero leverage against everything", {
  cr <- c(colon_criteria[1:4], list(ALLPASS = function(x) rep(TRUE, nrow(x))))
  p2 <- tp_prepare(colon_data(), cr, "trt","time","status", colon_ps, tau = 1825)
  L <- tp_leverage(p2); k <- match("ALLPASS", p2$names)
  expect_equal(L[k, -k], rep(0, ncol(L) - 1), tolerance = 1e-12)
})

test_that("leverage predicts the planted interaction in the simulation", {
  ## the planted-interaction generator lives with the paper scripts, not the
  ## package; recreate the minimal version here so the assertion is self-contained
  P <- 8L; GAMMA <- -0.60; C12 <- qnorm(0.45); CREST <- qnorm(0.85)
  gen <- function(n, seed = NULL) {
    if (!is.null(seed)) set.seed(seed)
    Z <- matrix(rnorm(n * P), n, P); A <- rbinom(n, 1, .5)
    E1 <- Z[, 1] <= C12; E2 <- Z[, 2] <= C12
    lp <- log(0.80)*A + Z %*% rep(0.28, P) + GAMMA * A * E1 * E2
    t <- rexp(n, rate = 0.22 * exp(as.numeric(lp))); cens <- rexp(n, rate = 0.05)
    data.frame(t = pmin(t, cens), st = as.integer(t <= cens), A = A, as.data.frame(Z))
  }
  CRIT <- setNames(lapply(seq_len(P), function(k)
    local({ kk <- k; cut <- if (k <= 2) C12 else CREST
            function(x) x[[paste0("V", kk)]] <= cut })), paste0("C", seq_len(P)))
  d  <- gen(1e5, seed = 1)
  pr <- tp_prepare(d, CRIT, "A","t","st", paste0("V", 1:8), tau = 6, min_per_arm = 3)
  L  <- tp_leverage(pr)
  V  <- tp_enumerate(pr); I <- tp_interaction(V, 8L, 1L)
  ## first-order prediction L * GAMMA should land within 25% of the realised value
  expect_true(abs(I[1,2] / (L[1,2] * GAMMA) - 1) < 0.25)
  ## and the planted pair must dominate the 27 pairs with no planted effect
  expect_true(abs(I[1,2]) > 10 * median(abs(I[upper.tri(I)][-1])))
})

test_that("real protocol criteria have low leverage - the null interaction is structural", {
  L <- tp_leverage(prep); up <- upper.tri(L)
  expect_true(max(L[up]) < 0.15)      # permissive criteria cannot show much interaction
})
