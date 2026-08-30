## Reviewer round 2, major point 4, second part: is the concentrated-vs-diffuse
## result mechanical? Running the first version of this sweep showed that our
## own factorial had confounded two things, and the reviewer's suspicion was
## well founded. In the factorial the diffuse arm held the same TOTAL effect
## modification but, because the per-criterion coefficient was simply divided,
## the DILUTING coefficient -- the signal the rule actually has to detect, since
## relaxation lowers the hazard ratio only by dropping a diluting criterion --
## fell from 0.32 to 0.128 alongside it. "Diffuse" therefore also meant "weaker
## thing to find", and the two cannot be separated in that design.
##
## This sweep separates them. Four configurations, all with the same total
## modification (sum |gamma| = 0.85):
##   A  dilution 0.30 in ONE criterion, enrichment 0.55 in ONE
##   B  dilution 0.30 in ONE criterion, enrichment 0.55 split over TWO
##   C  dilution 0.30 in ONE criterion, enrichment 0.55 split over FOUR
##   D  dilution 0.30 split over TWO criteria (0.15 each), enrichment 0.55 in ONE
## A to C vary how spread the ENRICHMENT is while the detection target is fixed.
## A against D varies how spread the DILUTION is while everything else is fixed.
## If concentration per se is what matters, A-C should differ. If what matters is
## the strength of the strongest diluting criterion, only D should fall away.
source("analysis/_setup.R")

P <- 8L
RETAIN <- 0.20; KEEP <- RETAIN^(1/P); THR <- qnorm(rep(KEEP, P))
SIZES <- c(600L, 2000L, 6000L, 18000L)
R_AT  <- c(120L, 120L, 90L, 60L)
N_TEST <- 60000L

CONFIG <- list(
  A_dil1_enr1 = c(-0.55, +0.30,  0.00,  0.00, 0, 0, 0, 0),
  B_dil1_enr2 = c(-0.30, +0.30, -0.25,  0.00, 0, 0, 0, 0),
  C_dil1_enr4 = c(-0.16, +0.30, -0.14, -0.13, -0.12, 0, 0, 0),
  D_dil2_enr1 = c(-0.55, +0.15, +0.15,  0.00, 0, 0, 0, 0)
)
stopifnot(all(abs(vapply(CONFIG, function(g) sum(abs(g)), numeric(1)) - 0.85) < 1e-9))
MAXDIL <- vapply(CONFIG, function(g) max(g[g > 0]), numeric(1))

gen_of <- function(GAM) function(n, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  Z <- matrix(rnorm(n * P), n, P); A <- rbinom(n, 1, .5)
  E <- sweep(Z, 2, THR, "<=")
  lp <- log(0.75)*A + Z %*% rep(0.55, P) + A * (E %*% GAM)
  t <- rexp(n, rate = 0.20 * exp(as.numeric(lp))); cs <- rexp(n, rate = 0.05)
  data.frame(t = pmin(t, cs), st = as.integer(t <= cs), A = A, as.data.frame(Z))
}
CRIT <- setNames(lapply(seq_len(P), function(k)
  local({ kk <- k; ct <- THR[k]; function(x) x[[paste0("V", kk)]] <= ct })), paste0("C", seq_len(P)))
prep_of <- function(d) tp_prepare(d, CRIT, "A","t","st", paste0("V", seq_len(P)), tau = 8, min_per_arm = 3)

CACHE <- "analysis/out/concentration_sweep.rds"
done <- if (file.exists(CACHE)) readRDS(CACHE) else list()
for (cfg in names(CONFIG)) {
  if (!is.null(done[[cfg]])) { say(sprintf("%-12s cached", cfg)); next }
  GAM <- CONFIG[[cfg]]; gen <- gen_of(GAM)
  TEST <- prep_of(gen(N_TEST, seed = 424242))
  o <- tp_value(TEST, seq_len(P)); hr_full <- exp(o["logHR"]); n_full <- exp(o["logN"])
  rows <- list()
  for (i in seq_along(SIZES)) {
    ntr <- SIZES[i]
    out <- .tp_lapply(seq_len(R_AT[i]), function(r) {
      pr <- prep_of(gen(ntr, seed = 66000 + 911 * i + 7 * r + which(names(CONFIG) == cfg)))
      V <- tryCatch(tp_enumerate(pr), error = function(e) NULL)
      if (is.null(V) || any(V[, "feasible"] == 0)) return(NULL)
      S <- which(tp_shapley(V, P, 1L) < 0)
      a <- tp_value(TEST, S); if (a["feasible"] != 1) return(NULL)
      c(lower = as.numeric(exp(a["logHR"]) < hr_full),
        more  = as.numeric(exp(a["logN"])  > n_full))
    }, 2L)
    M <- do.call(rbind, out[!vapply(out, is.null, logical(1))])
    rows[[as.character(ntr)]] <- c(n = ntr, R = nrow(M),
      p_lower = mean(M[,"lower"]), p_more = mean(M[,"more"]),
      se = sqrt(mean(M[,"lower"])*(1-mean(M[,"lower"]))/nrow(M)))
  }
  done[[cfg]] <- list(gam = GAM, carriers = sum(GAM != 0), max_dilute = MAXDIL[[cfg]],
                      rows = do.call(rbind, rows), hr_full = unname(hr_full))
  saveRDS(done, CACHE)
  z <- done[[cfg]]$rows
  say(sprintf("%-12s carriers=%d maxdil=%.2f | P(lower) at %s = %s",
      cfg, done[[cfg]]$carriers, MAXDIL[[cfg]], paste(SIZES, collapse="/"),
      paste(sprintf("%.2f", z[,"p_lower"]), collapse="/")))
}
say("ALL DONE")
