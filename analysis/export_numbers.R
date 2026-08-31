## Every number quoted in the manuscript is exported here from the analysis
## outputs, and the manuscript build reads this file. Nothing is transcribed by
## hand, so a changed result cannot silently leave a stale number in the text.
## (Reviewer major point 9, reproducibility.)
source("analysis/_setup.R")
J <- list()
rd <- function(f) if (file.exists(f)) readRDS(f) else NULL

## ---- factorial thresholds -----------------------------------------------
fa <- rd("analysis/out/factorial_threshold.rds")
if (!is.null(fa)) {
  ## A run is RIGHT-censored when the probability never reaches 0.80 within the
  ## ladder, and LEFT-censored when it is already above 0.80 at the smallest
  ## rung. Left-censored runs are not evidence of an easy problem: they arise
  ## where the full protocol retains so few events that its own estimate is the
  ## noisy one, so the relaxed protocol wins for reasons unrelated to selection.
  ## Both kinds are excluded from the spread statistics and counted separately.
  rows <- lapply(fa, function(r) {
    if (is.null(r$thr)) return(NULL)
    pg <- r$thr$p_grid; ng <- r$thr$n_grid
    left  <- length(pg) && all(pg >= 0.80)
    right <- is.na(r$thr$n_star)
    data.frame(run = r$row$run, p = r$sc$p, retain = r$sc$retain, nmod = r$sc$nmod,
      gmag = r$sc$gmag, crate = r$sc$crate, alloc = r$sc$palloc, conf = r$sc$conf,
      n_star = if (left || right) NA_real_ else r$thr$n_star,
      n_lo = if (left || right) NA_real_ else r$thr$n_lo,
      n_hi = if (left || right) NA_real_ else r$thr$n_hi,
      ev_star  = if (left || right) NA_real_ else r$thr$ev_star,
      ess_star = if (left || right) NA_real_ else r$thr$ess_star,
      cens = if (left) "left" else if (right) "right" else "none",
      ev_full = if (length(r$thr$ev_grid)) r$thr$ev_grid[1] else NA_real_,
      stringsAsFactors = FALSE)
  })
  D <- do.call(rbind, rows[!vapply(rows, is.null, logical(1))])
  J$factorial <- list(
    table = D, n_runs = nrow(D),
    n_complete = sum(is.finite(D$n_star)),
    n_right = sum(D$cens == "right"), n_left = sum(D$cens == "left"),
    ladder_top = 18000, ladder_bottom = 600,
    n_min = min(D$n_star, na.rm=TRUE), n_max = max(D$n_star, na.rm=TRUE),
    n_med = median(D$n_star, na.rm=TRUE),
    n_fold = max(D$n_star, na.rm=TRUE)/min(D$n_star, na.rm=TRUE),
    ev_min = min(D$ev_star, na.rm=TRUE), ev_max = max(D$ev_star, na.rm=TRUE),
    ev_med = median(D$ev_star, na.rm=TRUE),
    ev_fold = max(D$ev_star, na.rm=TRUE)/min(D$ev_star, na.rm=TRUE),
    ess_min = min(D$ess_star, na.rm=TRUE), ess_max = max(D$ess_star, na.rm=TRUE),
    ess_fold = max(D$ess_star, na.rm=TRUE)/min(D$ess_star, na.rm=TRUE),
    cv_n  = sd(D$n_star, na.rm=TRUE)/mean(D$n_star, na.rm=TRUE),
    cv_ev = sd(D$ev_star, na.rm=TRUE)/mean(D$ev_star, na.rm=TRUE),
    cv_ess= sd(D$ess_star,na.rm=TRUE)/mean(D$ess_star,na.rm=TRUE))
  ## Completion by factor level. The dominant pattern is not the size of the
  ## threshold but whether one exists inside any realistic cohort at all, so we
  ## report, for each factor level, how many of its 8 runs located a crossing.
  bylev <- function(col) {
    u <- sort(unique(D[[col]]))
    setNames(lapply(u, function(v) {
      k <- D[[col]] == v
      list(level = v, n = sum(k), complete = sum(k & is.finite(D$n_star)),
           right = sum(k & D$cens == "right"),
           med_n = if (any(k & is.finite(D$n_star))) median(D$n_star[k], na.rm = TRUE) else NA_real_)
    }), paste0(col, "_", u))
  }
  J$factorial$by <- c(bylev("p"), bylev("retain"), bylev("nmod"),
                      bylev("crate"), bylev("alloc"), bylev("conf"))
  ## main effect of each factor on log n* and log events*
  if (nrow(D) >= 8) {
    lz <- function(y) { m <- lm(log(y) ~ factor(p)+factor(retain)+factor(nmod)+
                                  factor(crate)+factor(alloc)+factor(conf), data=D); coef(m)[-1] }
    J$factorial$eff_n  <- tryCatch(lz(D$n_star),  error=function(e) NULL)
    J$factorial$eff_ev <- tryCatch(lz(D$ev_star), error=function(e) NULL)
  }
}

## ---- recovery metrics ----------------------------------------------------
rc <- rd("analysis/out/recovery_metrics.rds")
if (!is.null(rc)) {
  if (is.list(rc) && !is.null(rc$tab)) {
    J$recovery <- as.data.frame(rc$tab)
    J$recovery_full_regret <- rc$full_regret       # the reference the rule must beat
    J$recovery_limit_optimal <- rc$rule_limit_is_optimal
  } else J$recovery <- as.data.frame(rc)
}

## ---- round-2 additions ---------------------------------------------------
fr <- rd("analysis/out/factorial_reanalysis.rds")
if (!is.null(fr)) {
  rows <- fr$rows
  fx <- lapply(sort(unique(rows$n)), function(nn) {
    z <- rows[rows$n == nn, ]
    a <- z$p_lower[z$nmod == 2]; b <- z$p_lower[z$nmod == 5]
    list(n = nn, conc_med = median(a), conc_lo = min(a), conc_hi = max(a),
         diff_med = median(b), diff_lo = min(b), diff_hi = max(b),
         sd_all = sd(z$p_lower))
  })
  names(fx) <- paste0("n", sort(unique(rows$n)))
  ## spread of the success probability when scenarios are binned by each currency
  spread <- function(v) { q <- stats::quantile(v, c(0,.25,.5,.75,1), na.rm=TRUE)
    z <- cut(v, unique(q), include.lowest=TRUE)
    mean(tapply(rows$p_lower, z, stats::sd), na.rm=TRUE) }
  J$fixedn <- list(cells = fx,
    spread_patients = spread(rows$n), spread_events = spread(rows$events),
    spread_ess = spread(rows$ess))
}
cs <- rd("analysis/out/concentration_sweep.rds")
if (!is.null(cs)) J$concentration <- lapply(cs, function(z) list(
  carriers = z$carriers, rows = as.data.frame(z$rows)))
cv <- rd("analysis/out/sim_coverage.rds")
if (!is.null(cv)) {
  n1 <- length(cv$cov_bca_planted); n2 <- length(cv$cov_bca_null)
  m <- function(x) mean(x, na.rm = TRUE)
  J$coverage <- list(reps = min(n1, n2),
    bca_planted = m(cv$cov_bca_planted), bca_null = m(cv$cov_bca_null),
    pct_planted = m(cv$cov_pct_planted), pct_null = m(cv$cov_pct_null),
    se_planted = sqrt(m(cv$cov_bca_planted)*(1-m(cv$cov_bca_planted))/n1),
    se_null    = sqrt(m(cv$cov_bca_null)*(1-m(cv$cov_bca_null))/n2))
}

## ---- PRIMARY point estimates: the single source ---------------------------
## Reviewer round 4, point 1: every point estimate quoted anywhere comes from
## here, at the full split count. The nested bootstrap supplies uncertainty only.
prm <- function(lab) {
  z <- rd(sprintf("analysis/out/primary_%s.rds", lab)); if (is.null(z)) return(NULL)
  M <- z$M
  m <- function(k) if (k %in% colnames(M)) mean(M[, k], na.rm = TRUE) else NA_real_
  o <- list(R = z$R, tau = z$tau, time_var = z$time_var, status_var = z$status_var,
            margin = z$MARGIN, bands = z$BANDS,
            n_full = m("n_full"), n_rule = m("n_rule"), hr_full = m("hr_full"),
            hr_rule = m("hr_rule"), rm_full = m("rm_full"), rm_rule = m("rm_rule"),
            more = m("more"), lower = m("lower"), greater = m("greater"),
            front_hr = m("front_hr"), front_rm = m("front_rm"), front_hrM = m("front_hrM"),
            n_dom = m("n_dom"), n_domM = m("n_domM"),
            same_set = m("same_set"), n_rmrule = m("n_rmrule"),
            rmrule_lower = m("rmrule_lower"), rmrule_greater = m("rmrule_greater"),
            se_n = sd(M[,"n_rule"] - M[,"n_full"])/sqrt(nrow(M)),
            ## the naive across-split standard error, which the Results contrasts
            ## with the outer-sampling component from the nested bootstrap
            se_lower = sd(M[,"lower"])/sqrt(nrow(M)),
            se_hr = sd(M[,"hr_rule"] - M[,"hr_full"])/sqrt(nrow(M)),
            d_n = m("n_rule") - m("n_full"), d_hr = m("hr_rule") - m("hr_full"),
            d_rm = m("rm_rule") - m("rm_full"),
            removed_any = m("removed_any"), removed_binding = m("removed_binding"),
            n_removed = m("n_removed"))
  for (b in z$BANDS) { o[[paste0("hr",b)]] <- m(paste0("hr",b))
                       o[[paste0("rm",b)]] <- m(paste0("rm",b))
                       o[[paste0("nm",b)]] <- m(paste0("nm",b))
                       o[[paste0("sk",b)]] <- m(paste0("sk",b)) }
  o
}
J$primary <- list(colon = prm("colon"), rott = prm("rott"))

## ---- round-3 additions ---------------------------------------------------
nst <- function(lab) {
  z <- rd(sprintf("analysis/out/nested_%s.rds", lab)); if (is.null(z)) return(NULL)
  M <- z$M; point <- M[1, ]; boot <- M[-1, , drop = FALSE]
  ## round 4, major 5: inner Monte Carlo variance from the sample variance of the
  ## per-split values inside each resample, not from p(1-p)/R
  Vb <- if (!is.null(z$V)) z$V[-1, , drop = FALSE] else NULL
  Kb <- if (!is.null(z$K)) z$K[-1, , drop = FALSE] else NULL
  g <- function(nm) { if (!(nm %in% colnames(boot))) return(NULL)
    x <- boot[, nm]; x <- x[is.finite(x)]
    vt <- stats::var(x)
    vm <- if (!is.null(Vb) && nm %in% colnames(Vb)) {
            u <- Vb[, nm] / pmax(Kb[, nm], 1); mean(u[is.finite(u)])
          } else { ph <- mean(x); ph*(1-ph)/z$R_IN }
    ## endpoint movement between half and the full outer count
    h <- floor(length(x)/2)
    mv <- if (h >= 25) max(abs(stats::quantile(x[seq_len(h)], c(.025,.975)) -
                              stats::quantile(x, c(.025,.975)))) else NA_real_
    list(point = unname(point[nm]), sd_total = sqrt(vt), sd_mc = sqrt(vm),
         sd_outer = sqrt(max(vt - vm, 0)), conv = unname(mv),
         ci = unname(stats::quantile(x, c(.025,.975)))) }
  out <- list(B = z$B_OUT, R = z$R_IN, bands = z$BANDS, margin = z$MARGIN,
              more = g("more"), lower = g("lower"),
              front_hr = g("front_hr"), front_rm = g("front_rm"), front_hrM = g("front_hrM"),
              rm_same = g("rm_same"), rmrule_more = g("rmrule_more"),
              rmrule_lower = g("rmrule_lower"), rmrule_greater = g("rmrule_greater"),
              n_dom = unname(point["n_dom"]), n_domM = unname(point["n_domM"]))
  for (b in z$BANDS) { out[[paste0("hr", b)]] <- g(paste0("rank_hr_", b))
                       out[[paste0("rm", b)]] <- g(paste0("rank_rm_", b))
                       out[[paste0("nm", b)]] <- unname(point[paste0("nmatch_", b)])
                       out[[paste0("sk", b)]] <- unname(point[paste0("skew_", b)]) }
  out
}
J$nested <- list(colon = nst("colon"), rott = nst("rott"))

## ---- round-4 additions ---------------------------------------------------
tw <- rd("analysis/out/threeway.rds")
if (!is.null(tw)) {
  g <- function(M, nm, fn = mean) { if (!(nm %in% colnames(M))) return(NA_real_)
                                    x <- M[, nm]; unname(fn(x[is.finite(x)])) }
  one <- function(M) list(R = nrow(M),
    ## (a) selection third, empirical and optimistic
    dom_sel = g(M, "n_domB", stats::median), front_sel = g(M, "front_B"),
    ## (b) confirmatory: the pre-selected set re-evaluated on untouched patients
    n_survive = g(M, "n_survive", stats::median), repro = g(M, "repro"),
    front_conf = g(M, "front_conf"), reproM = g(M, "reproM"),
    dom_selM = g(M, "n_domBM", stats::median), best_holds = g(M, "best_holds"),
    ## (c) descriptive: a fresh scan of all 512 on the test third
    dom_test = g(M, "n_domC", stats::median), front_test = g(M, "front_C"))
  J$threeway <- list(colon = one(tw$colon), rott = one(tw$rott))
}

hz <- rd("analysis/out/horizon_sweep.rds")
if (!is.null(hz)) {
  tolist <- function(T) lapply(seq_len(nrow(T)), function(i) as.list(T[i, ]))
  J$horizon <- list(colon = tolist(hz$colon), rott = tolist(hz$rott),
                    tau_colon = 1825, tau_rott = 2555,
                    risk_colon = local({ d <- colon_data()
                      min(vapply(sort(unique(d$trt)), function(g)
                        mean(d$time[d$trt == g] >= 1825), numeric(1))) }),
                    risk_rott = local({ d <- rott_data()
                      min(vapply(sort(unique(d$trt)), function(g)
                        mean(d$dtime[d$trt == g] >= 2555), numeric(1))) }))
}

sc <- rd("analysis/out/snr_curve.rds")
if (!is.null(sc)) {
  ## Reviewer round 5, major point 4. The pooled correlation is driven by both the
  ## arrangement and the fitting size, and within an arrangement the ratio rises with
  ## the size by construction, so a high within-arrangement correlation says little
  ## more than "success rises with n". The informative comparison is BETWEEN
  ## arrangements at a fixed size. All three are exported and all three are reported.
  Tm <- sc$T
  sp <- function(a, b) if (length(unique(a)) < 2 || length(unique(b)) < 2) NA_real_ else
                       suppressWarnings(stats::cor(a, b, method = "spearman"))
  big <- Tm[, "n"] == max(Tm[, "n"])
  af  <- factor(Tm[, "arr"])
  adj <- sp(stats::residuals(stats::lm(Tm[, "win"] ~ af)),
            stats::residuals(stats::lm(Tm[, "snr"] ~ af)))
  J$snr_curve <- list(cells = lapply(seq_len(nrow(Tm)), function(i) as.list(Tm[i, ])),
                      sp_snr = sc$sp_snr, sp_n = sc$sp_n, nrep = sc$nrep, sizes = sc$sizes,
                      sp_between = sp(Tm[big, "win"], Tm[big, "snr"]),
                      sp_within  = adj,
                      n_flat = sum(vapply(sort(unique(Tm[, "arr"])), function(a)
                        as.numeric(length(unique(Tm[Tm[, "arr"] == a, "win"])) < 2), numeric(1))),
                      n_arr = length(unique(Tm[, "arr"])))
}

fo <- rd("analysis/out/frontier_optimism.rds")
if (!is.null(fo)) { m <- function(x) mean(x[is.finite(x)])
  J$frontier_opt <- list(R = nrow(fo),
    dom_emp = median(fo[,"n_domA"]), dom_pop = median(fo[,"n_domP"]),
    front_emp = m(fo[,"front_emp"]), front_pop = m(fo[,"front_pop"]),
    repro = m(fo[,"repro_B"]), true_frac = m(fo[,"true_frac"])) }

cw <- rd("analysis/out/colon_weighting_oos.rds")
if (!is.null(cw)) { m <- function(x) mean(x[is.finite(x)])
  J$colon_wt <- setNames(lapply(c("ps","known","none"), function(s) list(
    lower = m(cw[, paste0(s,"_lower")]), more = m(cw[, paste0(s,"_more")]),
    hr = m(cw[, paste0(s,"_hr")]), nkeep = m(cw[, paste0(s,"_nkeep")]))),
    c("ps","known","none")) }

## ---- round-5: blocks that existed only as literals in the manuscript ------
## Reviewer round 5, major point 1. A provenance check over the manuscript sources
## found 84 figures typed into prose rather than read from here. The results they
## quote were all computed, but the numbers had been transcribed by hand, which is
## the same failure mode that produced the endpoint inconsistency. Everything the
## text quotes is exported below and the check now runs as part of the build.

ct <- rd("analysis/out/confound_table.rds")
if (!is.null(ct)) {
  gv <- function(arm, n, col) { r <- ct[ct$arm == arm & ct$n == n, col]
                                if (length(r)) unname(r[1]) else NULL }
  arms <- unique(ct$arm)
  J$confound <- list(
    arms = arms, sizes = sort(unique(ct$n)),
    rows = lapply(seq_len(nrow(ct)), function(i) as.list(ct[i, ])),
    rand_5167 = gv(arms[1], 5167, "p"), adj_5167 = gv(arms[2], 5167, "p"),
    unmeas_5167 = gv(arms[3], 5167, "p"),
    rand_300 = gv(arms[1], 300, "p"), rand_20000 = gv(arms[1], 20000, "p"),
    rand_1000 = gv(arms[1], 1000, "p"), rand_3000 = gv(arms[1], 3000, "p"),
    elig_300 = gv(arms[1], 300, "pn"), elig_20000 = gv(arms[1], 20000, "pn"),
    rec_rand_5167 = gv(arms[1], 5167, "rec"), rec_unmeas_5167 = gv(arms[3], 5167, "rec"),
    rec_adj_5167 = gv(arms[2], 5167, "rec"))
}

ss <- rd("analysis/out/sim_sweep.rds")
if (!is.null(ss)) {
  ss <- as.data.frame(ss)
  J$noncollapse <- list(
    rows = lapply(seq_len(nrow(ss)), function(i) as.list(ss[i, ])),
    bz_min = min(ss$bZ), bz_max = max(ss$bZ),
    cond_hr = unique(ss$conditional_HR)[1],
    phi_hr_zero = ss$phi_logHR[which.min(ss$bZ)],
    phi_hr_max  = ss$phi_logHR[which.max(ss$bZ)],
    hr_all_zero = ss$HR_all[which.min(ss$bZ)], hr_all_max = ss$HR_all[which.max(ss$bZ)],
    rm_all_weak = ss$RM_all[2], rm_sub_weak = ss$RM_sub[2],
    rm_all_strong = ss$RM_all[nrow(ss)], rm_sub_strong = ss$RM_sub[nrow(ss)])
}

## Interaction leverage needs only the eligibility indicators, so it is computed
## here from the cohort directly rather than transcribed from a figure script.
plate <- function(dat, crit, ps, trt, tm, st, tau, path) {
  pr <- tryCatch(tp_prepare(dat, crit, trt, tm, st, ps, tau = tau), error = function(e) NULL)
  if (is.null(pr)) return(NULL)
  L <- tp_leverage(pr)
  im <- tryCatch(tp_implications(pr), error = function(e) NULL)
  det <- if (is.list(im)) im$determined else im
  off <- upper.tri(L)
  keep <- if (is.null(det)) off else off & !det
  lev <- abs(L[keep])
  z <- rd(path)
  list(p = ncol(L), npair = sum(off),
       lev_med = unname(stats::median(lev)), lev_max = unname(max(lev)),
       n_above_10 = sum(lev > 0.10), n_below_05 = sum(lev < 0.05),
       perm_hr = if (!is.null(z) && !is.null(z$perm)) unname(z$perm$p["HR"]) else NULL,
       perm_rm = if (!is.null(z) && !is.null(z$perm)) unname(z$perm$p["RMST"]) else NULL,
       B = if (!is.null(z) && !is.null(z$sm)) z$sm$B else NULL,
       K = if (!is.null(z) && !is.null(z$sm)) z$sm$K else NULL)
}
J$plate <- list(
  colon = plate(colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825,
                "analysis/out/colon_full.rds"),
  rott  = plate(rott_data(),  rott_criteria,  rott_ps,  "trt","dtime","death", 2555,
                "analysis/out/rott_fit.rds"))


ts <- rd("analysis/out/sim_trainsize.rds")
if (!is.null(ts)) {
  J$trainsize <- list(
    rows = lapply(names(ts), function(k) list(n = ts[[k]]$n_train, R = ts[[k]]$R,
      p_lower = ts[[k]]$p_lower_hr, p_more = ts[[k]]$p_more_n,
      p_exact = ts[[k]]$p_exact_rule, kept = ts[[k]]$mean_kept)),
    sizes = vapply(ts, function(z) z$n_train, numeric(1)))
}
rt <- rd("analysis/out/sim_rule_truth.rds")
if (!is.null(rt)) J$pop_rule <- list(
  hr_full = exp(unname(rt$V0row_full["logHR"])), hr_rule = exp(unname(rt$V0row_rule["logHR"])),
  n_full  = exp(unname(rt$V0row_full["logN"])),  n_rule  = exp(unname(rt$V0row_rule["logN"])),
  rm_full = unname(rt$V0row_full["rmstD"]),      rm_rule = unname(rt$V0row_rule["rmstD"]),
  n_kept = length(rt$keep0), p = length(rt$phi0))

cl <- rd("analysis/out/confound_limits.rds")
if (!is.null(cl)) J$confound_limits <- list(
  rows = lapply(seq_len(nrow(cl)), function(i) as.list(cl[i, ])),
  arms = c("randomised", "confounded, adjusted", "confounded, one unmeasured"),
  gap_rand = unname(cl[1, "gap"]), gap_adj = unname(cl[2, "gap"]), gap_unmeas = unname(cl[3, "gap"]),
  hr_rand = unname(cl[1, "hr_full"]), hr_adj = unname(cl[2, "hr_full"]),
  hr_unmeas = unname(cl[3, "hr_full"]),
  inflation = unname(cl[3, "gap"] / cl[1, "gap"] - 1))

## The factorial's "concentrated vs spread" contrast also changes the size of the
## diluting coefficient, because the per-criterion coefficients are set from one
## magnitude. Both values are derived here from the design constants in Text S1
## rather than being quoted from memory in the text.
J$factorial$dil_conc <- 0.40 * 0.80          # nmod = 2 arm: gmag 0.40, enricher 0.80 * gmag
J$factorial$dil_diff <- 0.16 * 0.80          # nmod = 5 arm: gmag 0.16, same multiplier

## Differences between arrangements at each fitting size, with Monte Carlo intervals,
## so the text does not have to quote them from the sweep printout.
cs2 <- rd("analysis/out/concentration_sweep.rds")
if (!is.null(cs2)) {
  base <- cs2[["A_dil1_enr1"]]
  J$conc_diff <- lapply(setdiff(names(cs2), "A_dil1_enr1"), function(k) {
    z <- cs2[[k]]
    R1 <- as.data.frame(z$rows); R0 <- as.data.frame(base$rows)
    list(cfg = k, rows = lapply(seq_len(nrow(R1)), function(i) {
      d  <- R1$p_lower[i] - R0$p_lower[i]
      se <- sqrt(R1$se[i]^2 + R0$se[i]^2)
      list(n = R1$n[i], diff = d, lo = d - 1.96*se, hi = d + 1.96*se) }))
  })
  names(J$conc_diff) <- setdiff(names(cs2), "A_dil1_enr1")
}

ctg <- rd("analysis/out/conc_targets.rds")
if (!is.null(ctg)) J$conc_targets <- list(
  rows = lapply(names(ctg), function(k) ctg[[k]]),
  hr_full = ctg[[1]]$hr_full,
  hr_oracle_conc = ctg[[1]]$hr_oracle, gap_conc = ctg[[1]]$gap,
  hr_oracle_split = ctg[[length(ctg)]]$hr_oracle, gap_split = ctg[[length(ctg)]]$gap,
  n_eval = 120000)

ph <- rd("analysis/out/ph_tests.rds")
if (!is.null(ph)) J$ph <- lapply(ph, function(z) z)

## The "roughly 0.34 in standard deviation at every fixed sample size" quoted in the
## Discussion is the mean across-scenario SD over the fixed sizes; computed, not typed.
if (!is.null(J$fixedn$cells)) {
  sds <- vapply(J$fixedn$cells, function(z) z$sd_all, numeric(1))
  J$fixedn$sd_mean <- mean(sds)
  J$fixedn$sd_min <- min(sds); J$fixedn$sd_max <- max(sds)
}

## Cohort descriptive facts that the Methods and Supplement quoted as literals:
## the largest off-diagonal eligibility correlation, the only criterion with any
## missingness, and the worst standardised mean difference after weighting.
## Computed here from the cohorts so they cannot drift from the tables.
cohort_facts <- function(dat, crit, ps, trt, tm, st, tau) {
  E <- vapply(crit, function(f) as.numeric(f(dat)), numeric(nrow(dat)))
  miss <- vapply(seq_along(crit), function(j) mean(is.na(E[, j])), numeric(1))
  Ec <- E; Ec[is.na(Ec)] <- 0
  R <- suppressWarnings(stats::cor(Ec))
  diag(R) <- 0; R[!is.finite(R)] <- 0
  k <- which(abs(R) == max(abs(R)), arr.ind = TRUE)[1, ]
  pr <- tryCatch(tp_prepare(dat, crit, trt, tm, st, ps, tau = tau), error = function(e) NULL)
  smd <- NA_real_
  if (!is.null(pr) && !is.null(pr$X)) {
    e <- tryCatch(fast_logit(pr$X, pr$trt), error = function(z) rep(mean(pr$trt), nrow(pr$X)))
    e <- pmin(pmax(e, .05), .95); w <- pr$trt/e + (1-pr$trt)/(1-e)
    smd <- max(vapply(seq_len(ncol(pr$X)), function(j) {
      x <- pr$X[, j]; i1 <- pr$trt == 1
      m1 <- stats::weighted.mean(x[i1], w[i1]); m0 <- stats::weighted.mean(x[!i1], w[!i1])
      sdp <- sqrt((stats::var(x[i1]) + stats::var(x[!i1]))/2)
      if (!is.finite(sdp) || sdp == 0) 0 else abs(m1 - m0)/sdp }, numeric(1)))
  }
  list(max_cor = unname(R[k[1], k[2]]),
       max_cor_pair = paste(names(crit)[k[1]], "with", names(crit)[k[2]]),
       n_missing = sum(miss > 0), max_missing = max(miss),
       max_missing_name = names(crit)[which.max(miss)], max_smd = smd)
}
J$cohort_facts <- list(
  colon = tryCatch(cohort_facts(colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825),
                   error = function(e) NULL),
  rott  = tryCatch(cohort_facts(rott_data(), rott_criteria, rott_ps, "trt","dtime","death", 2555),
                   error = function(e) NULL))

## Monte Carlo standard error of the fixed-size success probabilities in Table 2.
if (!is.null(J$factorial$table)) {
  ft <- J$factorial$table
  J$fixedn$mc_se_max <- max(vapply(J$fixedn$cells, function(z)
    sqrt(0.25 / 50), numeric(1)))   # worst case at the smallest replicate count
}

psx <- rd("analysis/out/ps_specs.rds")
if (!is.null(psx)) J$ps_specs <- lapply(psx, function(z) z)

## Reviewer round 5. The Results quoted the median located threshold at reliability
## targets of 0.70 and 0.90 as two integers with no source; no current script
## computed them. They are computed here from the stored ladder, by the same
## log-linear interpolation used for the 0.80 target, so all three targets come
## from one place.
ftr <- rd("analysis/out/factorial_threshold.rds")
if (!is.null(ftr)) {
  cross_at <- function(g, target) {
    n <- vapply(g, `[[`, numeric(1), "n"); p <- vapply(g, `[[`, numeric(1), "p_lower")
    o <- order(n); n <- n[o]; p <- p[o]
    i <- which(p >= target)[1]
    if (is.na(i)) return(NA_real_)          # never crosses: right-censored
    if (i == 1L) return(NA_real_)           # already above at the smallest rung
    x0 <- log(n[i-1]); x1 <- log(n[i]); y0 <- p[i-1]; y1 <- p[i]
    if (y1 == y0) return(n[i])
    exp(x0 + (target - y0) * (x1 - x0)/(y1 - y0))
  }
  ## Reviewer round 5: Table S2b was a typed literal, including two columns
  ## (the concentrated/diffuse split and the censoring counts) that had no source
  ## anywhere. Everything the table reports is computed here.
  nmod_of <- function(z) { v <- if (!is.null(z$sc$nmod)) z$sc$nmod else z$row$nmod
                           if (is.null(v)) NA_integer_ else as.integer(v[1]) }
  top <- max(vapply(ftr, function(z) max(vapply(z$grid, `[[`, numeric(1), "n")), numeric(1)))
  bot <- min(vapply(ftr, function(z) min(vapply(z$grid, `[[`, numeric(1), "n")), numeric(1)))
  J$targets <- lapply(c(0.70, 0.80, 0.90), function(tg) {
    v  <- vapply(ftr, function(z) cross_at(z$grid, tg), numeric(1))
    nm <- vapply(ftr, nmod_of, integer(1))
    pl <- lapply(ftr, function(z) vapply(z$grid, `[[`, numeric(1), "p_lower"))
    ## right-censored: never reaches the target on the ladder.
    ## left-censored: already at or above the target at the smallest rung.
    left  <- vapply(pl, function(p) as.numeric(p[1] >= tg), numeric(1))
    right <- vapply(pl, function(p) as.numeric(max(p) < tg), numeric(1))
    conc <- nm == min(nm, na.rm = TRUE); diff_ <- !conc
    list(target = tg, n_located = sum(is.finite(v)), n_runs = length(v),
         n_right = sum(right == 1), n_left = sum(left == 1),
         conc_located = sum(is.finite(v) & conc), conc_n = sum(conc),
         diff_located = sum(is.finite(v) & diff_), diff_n = sum(diff_),
         ladder_top = top, ladder_bottom = bot,
         med = if (any(is.finite(v))) unname(stats::median(v[is.finite(v)])) else NA_real_)
  })
  names(J$targets) <- c("t70", "t80", "t90")
}

## the two evaluation-set sizes, which belong to two different simulations and were
## quoted in the main text and the supplement without being distinguished
J$sim_sizes <- list(conc_targets_eval = 120000L, arrangement_scoring = 60000L,
                    trainsize_scoring = 100000L, coverage_n = 1500L)

lff <- rd("analysis/out/leverage_forms_fit.rds")
if (!is.null(lff)) {
  e <- vapply(lff, function(z) z$rel_err, numeric(1))
  fm <- vapply(lff, function(z) z$form, character(1))
  J$leverage_fit <- list(
    rows = lapply(lff, function(z) z),
    and_max = max(abs(e[fm == "AND"])),
    other_min = min(e[fm != "AND"]), other_max = max(e[fm != "AND"]))
}

ctr <- rd("analysis/out/cohort_table_rows.rds")
if (!is.null(ctr)) J$criteria <- list(rows = ctr$rows, head = ctr$head)

## Table S1c reports the MEDIAN over all subsets of each size, not every subset,
## so the aggregation happens here rather than in the document.
ovr <- rd("analysis/out/overlap_vs_restriction.rds")
if (!is.null(ovr)) J$overlap <- lapply(ovr, function(M) {
  M <- as.data.frame(M)
  sizes <- sort(unique(M$size))
  lapply(sizes, function(sz) { z <- M[M$size == sz, , drop = FALSE]
    md <- function(v) unname(stats::median(v[is.finite(v)]))
    list(size = sz, n_subsets = nrow(z), n = md(z$n), ess_frac = md(z$ess_frac),
         trunc = md(z$trunc), maxsmd = md(z$maxsmd), events = md(z$events)) }) })

## ---- static facts computed here -----------------------------------------
J$efficiency <- local({
  pr <- tp_prepare(colon_data(), colon_criteria, "trt","time","status", colon_ps, tau=1825)
  V <- tp_enumerate(pr); p <- 9L
  pl <- tp_shapley(V,p,1L); Vh <- V; Vh[,1] <- exp(V[,1]); ph <- tp_shapley(Vh,p,1L)
  list(err_log = abs(sum(pl) - (V[2^p,1]-V[1,1])),
       err_hr  = abs(sum(ph) - (Vh[2^p,1]-Vh[1,1])),
       tot_log = V[2^p,1]-V[1,1], tot_hr = Vh[2^p,1]-Vh[1,1],
       same_set = setequal(which(pl<0), which(ph<0)),
       infeasible = sum(V[,"feasible"]==0), nsub = nrow(V))
})
J$leverage_forms <- local({
  a <- function(q) (1-q)^2
  list(q = c(.45,.70,.85,.90), and = a(c(.45,.70,.85,.90)),
       or = -a(c(.45,.70,.85,.90)), xor = -2*a(c(.45,.70,.85,.90)))
})
## minimal JSON writer: jsonlite is not available in the build container and
## the structure here is only lists, atomic vectors and data frames.
esc <- function(x) gsub('"', '\\\\"', x, fixed = TRUE)
tojson <- function(x) {
  if (is.null(x)) return("null")
  if (is.data.frame(x))
    return(paste0("[", paste(vapply(seq_len(nrow(x)), function(i)
      paste0("{", paste(sprintf('"%s":%s', names(x),
        vapply(x[i, ], tojson, character(1))), collapse=","), "}"),
      character(1)), collapse=","), "]"))
  if (is.list(x)) {
    nm <- names(x); if (is.null(nm)) return(paste0("[", paste(vapply(x, tojson, character(1)), collapse=","), "]"))
    return(paste0("{", paste(sprintf('"%s":%s', nm, vapply(x, tojson, character(1))), collapse=","), "}"))
  }
  if (is.logical(x) && length(x)==1) return(if (is.na(x)) "null" else tolower(as.character(x)))
  if (is.character(x)) { v <- ifelse(is.na(x), "null", paste0('"', esc(x), '"'))
                         return(if (length(v)==1) v else paste0("[", paste(v, collapse=","), "]")) }
  v <- ifelse(is.finite(x), formatC(x, digits = 8, format = "g"), "null")
  if (length(v) == 1) v else paste0("[", paste(v, collapse=","), "]")
}
## ---- consistency assertions ---------------------------------------------
## Reviewer round 4, point 1: fail loudly rather than let two documents drift.
chk <- function(cond, msg) if (!isTRUE(cond)) stop("consistency check failed: ", msg)

## Reviewer round 4, major point 1. The failure that produced the main-text /
## supplement divergence was a mismatched Rotterdam endpoint sitting in eleven
## scripts at once. A check on the exported numbers alone would not have caught
## it, so we also check the SOURCE: no analysis script may pair the relapse-free
## time with the death indicator, and any script naming a Rotterdam tau must name
## 2555. This runs on every export and stops the build.
scan_scripts <- function() {
  fs <- list.files("analysis", pattern = "[.]R$", full.names = TRUE)
  bad <- character(0)
  for (f in fs) {
    ln <- readLines(f, warn = FALSE)
    ln <- ln[!grepl("^\\s*#", ln)]                      # ignore comments
    i1 <- grep('"rtime"\\s*,\\s*"death"', ln)
    if (length(i1)) bad <- c(bad, sprintf("%s:%d rtime paired with death", basename(f), i1))
    ## a Rotterdam call and a colon horizon on the same line
    i2 <- grep("rott_(data|ps|criteria)", ln)
    i2 <- i2[grepl("1825", ln[i2])]
    if (length(i2)) bad <- c(bad, sprintf("%s:%d Rotterdam call at tau = 1825", basename(f), i2))
  }
  bad
}
## Reviewer round 5, major point 1. Five result objects were superseded during this
## revision but were still being read by the supplement and by Results section 2,
## which is how two sets of estimates for the same quantity reached the reviewer.
## They now live in analysis/out/superseded/ and this build refuses to start if any
## of them is back in the read path.
RETIRED <- c("split_dependence", "rmst_rule", "pareto_benchmark",
             "random_benchmark", "snr_check")
back <- RETIRED[file.exists(file.path("analysis/out", paste0(RETIRED, ".rds")))]
if (length(back))
  stop("superseded result objects are back in the read path:\n  ",
       paste(back, collapse = "\n  "),
       "\nMove them to analysis/out/superseded/ or delete the code that writes them there.")
say("superseded-object check passed (", length(RETIRED), " objects retired)")

bad <- scan_scripts()
if (length(bad)) stop("endpoint check failed:\n  ", paste(bad, collapse = "\n  "))
say("endpoint source check passed over ", length(list.files("analysis", pattern = "[.]R$")), " scripts")
if (!is.null(J$primary$colon)) {
  chk(J$primary$colon$time_var == "time" && J$primary$colon$status_var == "status",
      "colon endpoint must be (time, status)")
  chk(J$primary$rott$time_var == "dtime" && J$primary$rott$status_var == "death",
      "Rotterdam endpoint must be (dtime, death), not (rtime, death)")
  chk(J$primary$rott$tau == 2555 && J$primary$colon$tau == 1825, "tau values")
  if (!is.null(J$nested$colon))
    chk(abs(J$primary$colon$lower - J$nested$colon$lower$point) < 0.25,
        "primary and nested colon P(lower) differ by more than 0.25")
## Reviewer round 5, major point 1. Two secondary runs used to report their own
## estimate of a quantity the primary analysis already reports. They now share the
## primary run's seed, split count and split function, so the overlapping cell must
## agree exactly; if it does not, the runs have drifted apart again.
if (!is.null(J$colon_wt) && !is.null(J$primary$colon))
  chk(abs(J$colon_wt$ps$lower - J$primary$colon$lower) < 1e-9,
      sprintf("weighting sensitivity ps arm (%.4f) must reproduce the primary colon P(lower) (%.4f)",
              J$colon_wt$ps$lower, J$primary$colon$lower))
if (!is.null(J$horizon) && !is.null(J$primary$colon)) {
  hz_main <- function(rows, tau0) { for (r in rows) if (isTRUE(r$tau == tau0)) return(r); NULL }
  hc <- hz_main(J$horizon$colon, J$primary$colon$tau)
  hr_ <- hz_main(J$horizon$rott,  J$primary$rott$tau)
  if (!is.null(hc)) chk(abs(hc$same - J$primary$colon$same_set) < 1e-9,
    sprintf("horizon sweep colon row at tau=%d (%.4f) must reproduce the primary agreement rate (%.4f)",
            J$primary$colon$tau, hc$same, J$primary$colon$same_set))
  if (!is.null(hr_)) chk(abs(hr_$same - J$primary$rott$same_set) < 1e-9,
    sprintf("horizon sweep Rotterdam row at tau=%d (%.4f) must reproduce the primary agreement rate (%.4f)",
            J$primary$rott$tau, hr_$same, J$primary$rott$same_set))
}

}
writeLines(tojson(J), "analysis/out/numbers.json")
say(sprintf("exported %d blocks", length(J)))
