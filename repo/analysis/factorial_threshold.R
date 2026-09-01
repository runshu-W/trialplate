## Reviewer major point 3. The 3,000 / 6,000-patient threshold came from a
## single generating mechanism. Here it is estimated across a 2^(6-2)
## resolution-IV fractional factorial in the six factors the reviewer names,
## and re-expressed in events and in effective sample size after weighting.
##
## The claim under test is NOT "the threshold is 3,000". It is: the threshold
## in PATIENTS moves a great deal across scenarios, while the threshold in
## FULL-PROTOCOL EVENTS -- the information in the smallest cohort the rule has
## to evaluate -- moves much less. If that holds, the actionable guidance is an
## event count, not a patient count. If it does not, there is no general
## guidance to give and we say so.
source("analysis/_setup.R")

CACHE <- "analysis/out/factorial_threshold.rds"
## replicates are scaled down at the expensive rungs; the bootstrap CI on the
## crossing carries the resulting Monte Carlo error honestly.
R_BIG  <- as.integer(Sys.getenv("FAC_R", "100"))
LADDER <- c(600L, 2000L, 6000L, 18000L)
R_AT   <- c(R_BIG, R_BIG, round(0.7*R_BIG), round(0.5*R_BIG))
N_TEST <- 60000L
TARGET <- 0.80

## ---- the design: 6 factors, 16 runs, generators E = ABC, F = ABD ---------
base <- expand.grid(A = c(-1,1), B = c(-1,1), C = c(-1,1), D = c(-1,1))
DES <- transform(base, E = A*B*C, F = A*B*D)
DES$run <- seq_len(nrow(DES))

lvl <- function(f, lo, hi) ifelse(f < 0, lo, hi)

## ---- generating mechanism parameterised by the design row ----------------
make_scen <- function(row) {
  ## A is 6 vs 8 rather than 6 vs 12. Exhaustive enumeration costs 2^p value-
  ## function evaluations per replicate, so the cost of the whole design grows as
  ## 2^p and a wider contrast was not affordable. This factor is therefore tested
  ## over a narrower range than one would like, and the text says so.
  p     <- lvl(row$A,  6L, 8L)                       # A: number of criteria
  ## B is parameterised as the retention of the FULL protocol, not as a
  ## per-criterion rate. A fixed per-criterion rate would make the full protocol
  ## vastly more restrictive at p = 10 than at p = 6 (0.70^10 = 2.8%, outside
  ## anything a real protocol does) and would entangle factors A and B. The two
  ## levels bracket the real cohorts: colon retains 28.4%, Rotterdam 14.1%.
  retain <- lvl(row$B, 0.30, 0.12)                   # B: full-protocol retention
  keep   <- retain^(1/p)
  nmod  <- lvl(row$C,  2L,  5L)                      # C: modifiers, sparse vs dense
  gmag  <- lvl(row$C, 0.40, 0.16)                    #    strong vs weak
  crate <- lvl(row$D, 0.020, 0.180)                  # D: censoring -> event rate
  palloc<- lvl(row$E, 0.50, 0.25)                    # E: allocation ratio
  conf  <- row$F > 0                                 # F: confounded assignment

  THR <- qnorm(rep(keep, p))
  ## Every scenario must contain at least one DILUTING criterion (gamma > 0):
  ## relaxation can only lower the hazard ratio if some retained criterion
  ## selects patients who benefit less. A protocol whose modifiers all enrich
  ## has no attainable threshold at any sample size; that is a property of the
  ## protocol, not of the estimator, and it is stated in the text rather than
  ## entering the design as a censored run.
  GAM <- numeric(p)
  if (nmod == 2L) { GAM[1] <- -gmag;        GAM[3] <- +gmag * 0.80 }
  else            { GAM[1] <- -gmag;        GAM[2] <- -gmag * 0.75
                    GAM[3] <- +gmag * 0.80; GAM[4] <- -gmag * 0.50
                    GAM[5] <- +gmag * 0.40 }
  gen <- function(n, seed = NULL) {
    if (!is.null(seed)) set.seed(seed)
    Z <- matrix(rnorm(n * p), n, p)
    A <- if (conf) rbinom(n, 1, plogis(qlogis(palloc) + 0.45 * (Z[,1] + Z[,2])))
         else      rbinom(n, 1, palloc)
    E <- sweep(Z, 2, THR, "<=")
    lp <- log(0.75) * A + Z %*% rep(0.55, p) + A * (E %*% GAM)
    t  <- rexp(n, rate = 0.20 * exp(as.numeric(lp)))
    cs <- rexp(n, rate = crate)
    data.frame(t = pmin(t, cs), st = as.integer(t <= cs), A = A, as.data.frame(Z))
  }
  CRIT <- setNames(lapply(seq_len(p), function(k)
    local({ kk <- k; cut <- THR[k]; function(x) x[[paste0("V", kk)]] <= cut })),
    paste0("C", seq_len(p)))
  list(p = p, gen = gen, crit = CRIT, ps = paste0("V", seq_len(p)),
       keep = keep, retain = retain, nmod = nmod, gmag = gmag, crate = crate,
       palloc = palloc, conf = conf)
}

prep_of <- function(sc, d) tp_prepare(d, sc$crit, "A", "t", "st", sc$ps,
                                      tau = 8, min_per_arm = 3)

## information actually available to the rule: the FULL protocol is the
## smallest cohort it must evaluate, so its events and weighted ESS are the
## binding constraint.
ALLS <- function(E, S) { r <- E[, S[1]]; for (j in S[-1]) r <- r & E[, j]; r }
info_full <- function(pr) {
  keep <- ALLS(pr$E, seq_len(pr$p))
  tr <- pr$trt[keep]; n <- sum(keep)
  if (n < 5 || length(unique(tr)) < 2) return(c(events = NA, ess = NA, n = n))
  e <- tryCatch(fast_logit(pr$X[keep, , drop = FALSE], tr), error = function(z) rep(mean(tr), n))
  e <- pmin(pmax(e, 0.05), 0.95); w <- tr/e + (1 - tr)/(1 - e)
  c(events = sum(pr$status[keep]), ess = sum(w)^2 / sum(w^2), n = n)
}

## ---- one scenario --------------------------------------------------------
one_scenario <- function(row) {
  sc <- make_scen(row); p <- sc$p; full <- seq_len(p)
  TEST <- prep_of(sc, sc$gen(N_TEST, seed = 90000 + row$run))
  o_full <- tp_value(TEST, full)
  hr_full <- exp(o_full["logHR"]); n_full <- exp(o_full["logN"])

  grid <- lapply(seq_along(LADDER), function(li) {
    ntr <- LADDER[li]
    out <- .tp_lapply(seq_len(R_AT[li]), function(r) {
      d  <- sc$gen(ntr, seed = 700000 + 977 * row$run + 13 * r + ntr)
      pr <- prep_of(sc, d)
      V  <- tryCatch(tp_enumerate(pr), error = function(e) NULL)
      if (is.null(V) || any(V[, "feasible"] == 0)) return(NULL)
      S <- which(tp_shapley(V, p, 1L) < 0)
      a <- tp_value(TEST, S); if (a["feasible"] != 1) return(NULL)
      inf <- info_full(pr)
      c(lower = as.numeric(exp(a["logHR"]) < hr_full),
        more  = as.numeric(exp(a["logN"])  > n_full),
        events = unname(inf["events"]), ess = unname(inf["ess"]))
    }, 2L)
    M <- do.call(rbind, out[!vapply(out, is.null, logical(1))])
    ## a rung on which most replicates hit an infeasible subset carries no
    ## information and is dropped rather than reported as a low probability
    if (is.null(M) || !nrow(M) || nrow(M) < 0.5 * R_AT[li]) return(NULL)
    list(n = ntr, R = nrow(M), p_lower = mean(M[, "lower"]),
         se = sqrt(mean(M[,"lower"]) * (1 - mean(M[,"lower"])) / nrow(M)),
         p_more = mean(M[, "more"]),
         events = median(M[, "events"], na.rm = TRUE),
         ess    = median(M[, "ess"],    na.rm = TRUE),
         draws  = M[, "lower"])
  })
  grid <- grid[!vapply(grid, is.null, logical(1))]
  list(row = row, sc = sc[c("p","keep","retain","nmod","gmag","crate","palloc","conf")],
       hr_full = unname(hr_full), grid = grid)
}

## ---- invert the curve for the crossing, with a bootstrap CI --------------
cross <- function(nv, pv, target = TARGET) {
  if (all(pv >= target)) return(min(nv))
  if (all(pv <  target)) return(NA_real_)
  i <- which(pv >= target)[1]; if (i == 1) return(nv[1])
  x1 <- log(nv[i-1]); x2 <- log(nv[i]); y1 <- pv[i-1]; y2 <- pv[i]
  if (y2 == y1) return(nv[i])
  exp(x1 + (target - y1) * (x2 - x1) / (y2 - y1))
}
threshold <- function(res, B = 400) {
  nv <- vapply(res$grid, `[[`, numeric(1), "n")
  pv <- vapply(res$grid, `[[`, numeric(1), "p_lower")
  ev <- vapply(res$grid, `[[`, numeric(1), "events")
  es <- vapply(res$grid, `[[`, numeric(1), "ess")
  o  <- order(nv); nv <- nv[o]; pv <- pv[o]; ev <- ev[o]; es <- es[o]
  n_star <- cross(nv, pv)
  interp <- function(x, y, at) if (is.na(at)) NA_real_ else
    approx(log(x), y, xout = log(at), rule = 2)$y
  bs <- replicate(B, {
    pb <- vapply(res$grid[o], function(g) mean(sample(g$draws, replace = TRUE)), numeric(1))
    cross(nv, pb)
  })
  list(n_star = n_star,
       n_lo = unname(quantile(bs, .025, na.rm = TRUE)),
       n_hi = unname(quantile(bs, .975, na.rm = TRUE)),
       ev_star = interp(nv, ev, n_star),
       ess_star = interp(nv, es, n_star),
       ev_lo = interp(nv, ev, quantile(bs,.025,na.rm=TRUE)),
       ev_hi = interp(nv, ev, quantile(bs,.975,na.rm=TRUE)),
       n_grid = nv, p_grid = pv, ev_grid = ev, ess_grid = es,
       censored = is.na(n_star))
}

## ---- drive ---------------------------------------------------------------
done <- if (file.exists(CACHE)) readRDS(CACHE) else list()
for (k in seq_len(nrow(DES))) {
  key <- paste0("run", k)
  if (!is.null(done[[key]])) { say(sprintf("run %2d cached", k)); next }
  t0 <- Sys.time()
  r <- one_scenario(DES[k, ])
  r$thr <- threshold(r)
  done[[key]] <- r; saveRDS(done, CACHE)
  say(sprintf("run %2d | p=%2d ret=%.2f nmod=%d g=%.2f cens=%.3f alloc=%.2f conf=%s | n* = %s [%s, %s]  events* = %s  ESS* = %s | %.1f min",
      k, r$sc$p, r$sc$retain, r$sc$nmod, r$sc$gmag, r$sc$crate, r$sc$palloc, r$sc$conf,
      ifelse(is.na(r$thr$n_star), ">25000", sprintf("%.0f", r$thr$n_star)),
      ifelse(is.na(r$thr$n_lo), "-", sprintf("%.0f", r$thr$n_lo)),
      ifelse(is.na(r$thr$n_hi), "-", sprintf("%.0f", r$thr$n_hi)),
      ifelse(is.na(r$thr$ev_star), "-", sprintf("%.0f", r$thr$ev_star)),
      ifelse(is.na(r$thr$ess_star), "-", sprintf("%.0f", r$thr$ess_star)),
      as.numeric(difftime(Sys.time(), t0, units = "mins"))))
}
say("ALL DONE")
