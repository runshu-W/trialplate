## W6  Does confounding raise the training-size threshold?
## The rotterdam cohort sits systematically BELOW the randomised curve at both
## splits (0.497 / 0.527 against 0.603 / 0.698). The natural explanation is that
## observational data carries noise the randomised simulation does not model.
## Test it directly with three arms sharing ONE outcome model, so the target the
## rule is trying to find is identical and only the treatment-assignment
## mechanism (and what the analyst can adjust for) changes:
##   A  randomised            A ~ Bern(0.5)                    [the W5 curve]
##   B  confounded, adjusted  A depends on Z1..Z3, PS uses all Z
##   C  confounded, one confounder UNMEASURED: PS omits Z1
source("analysis/_setup.R")

P <- 8L
CUT <- c(0.85, 0.75, 0.70, 0.90, 0.80, 0.85, 0.75, 0.90); THR <- qnorm(CUT)
GAM <- c(-0.35, -0.25, +0.30, 0, 0, 0, 0, 0)
ALPHA <- c(0.6, 0.5, 0.4, 0, 0, 0, 0, 0)          # confounding by indication
gen <- function(n, arm, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  Z <- matrix(rnorm(n * P), n, P)
  A <- if (arm == "A") rbinom(n, 1, .5)
       else rbinom(n, 1, 1/(1 + exp(-as.numeric(Z %*% ALPHA))))
  E <- sweep(Z, 2, THR, "<=")
  lp <- log(0.75)*A + Z %*% rep(0.55, P) + A * (E %*% GAM)
  t <- rexp(n, rate = 0.20 * exp(as.numeric(lp))); cens <- rexp(n, rate = 0.05)
  data.frame(t = pmin(t, cens), st = as.integer(t <= cens), A = A, as.data.frame(Z))
}
CRIT <- setNames(lapply(seq_len(P), function(k)
  local({ kk <- k; cut <- THR[k]; function(x) x[[paste0("V", kk)]] <= cut })), paste0("C", seq_len(P)))
PSOF <- list(A = paste0("V", 1:P), B = paste0("V", 1:P), C = paste0("V", 2:P))  # C omits V1
prep_of <- function(d, arm) tp_prepare(d, CRIT, "A","t","st", PSOF[[arm]], tau = 8, min_per_arm = 3)
bits <- bitwShiftL(1L, 0:(P-1)); kidx <- function(S) sum(bits[S]) + 1L; full <- seq_len(P)

R <- as.integer(Sys.getenv("CNF_R", "250"))
NS <- c(1000L, 3000L, 5167L, 20000L)
res <- list()
for (arm in c("B","C")) {
  say(sprintf("=== arm %s : population truth (N = 3e5) ===", arm))
  V0 <- tp_enumerate(prep_of(gen(3e5, arm, seed = 1), arm))
  keep0 <- which(tp_shapley(V0, P, 1L) < 0)
  say(sprintf("  rule keeps %s | full HR %.4f -> rule HR %.4f (%s)",
      paste(sprintf("C%d", keep0), collapse=","), exp(V0[kidx(full),"logHR"]),
      exp(V0[kidx(keep0),"logHR"]),
      if (V0[kidx(keep0),"logHR"] < V0[kidx(full),"logHR"]) "LOWERS" else "does NOT lower"))
  TEST <- prep_of(gen(1e5, arm, seed = 999), arm); o <- tp_value(TEST, full)
  for (ntr in NS) {
    out <- .tp_lapply(seq_len(R), function(r) tryCatch({
      pr <- prep_of(gen(ntr, arm, seed = 7000 + 41*r + ntr), arm)
      V <- tp_enumerate(pr); if (any(V[,"feasible"] == 0)) return(NULL)
      S <- which(tp_shapley(V, P, 1L) < 0); a <- tp_value(TEST, S)
      c(hr = unname(exp(a["logHR"])), n = unname(exp(a["logN"])),
        match = as.numeric(setequal(S, keep0)))
    }, error = function(e) NULL), 2L)
    M <- do.call(rbind, out[!vapply(out, is.null, logical(1))])
    res[[paste(arm, ntr)]] <- list(arm = arm, n_train = ntr, R = nrow(M),
      p_lower_hr = mean(M[,"hr"] < exp(o["logHR"])), p_more_n = mean(M[,"n"] > exp(o["logN"])),
      p_match = mean(M[,"match"]))
    r <- res[[paste(arm, ntr)]]
    say(sprintf("  arm %s  n_train %6d  R=%3d | P(lower HR) = %.3f | P(more n) = %.3f | recovers rule %.3f",
        arm, ntr, r$R, r$p_lower_hr, r$p_more_n, r$p_match))
    saveRDS(res, "analysis/out/sim_confound.rds")
  }
}
say("ALL DONE")
