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

## ---- random-relaxation benchmark ----------------------------------------
rb <- rd("analysis/out/random_benchmark.rds")
if (!is.null(rb)) J$random <- lapply(rb, function(M) list(
  R = nrow(M), k = mean(M[,"k"]),
  p_more_full = mean(M[,"n_rule"] > M[,"n_full"]),
  p_more_rand = mean(M[,"beat_n"],  na.rm=TRUE),
  p_hr_rand   = mean(M[,"beat_hr"], na.rm=TRUE),
  n_full = mean(M[,"n_full"]), n_rule = mean(M[,"n_rule"]), n_rand = mean(M[,"n_rand"],na.rm=TRUE),
  hr_full= mean(M[,"hr_full"]), hr_rule= mean(M[,"hr_rule"]), hr_rand= mean(M[,"hr_rand"],na.rm=TRUE)))

## ---- split dependence ----------------------------------------------------
sd_ <- rd("analysis/out/split_dependence.rds")
if (!is.null(sd_)) J$dependence <- lapply(sd_, function(z) list(
  p_more = z$more$point, p_lower = z$lower$point,
  se_more = z$more$sd_total, se_lower = z$lower$sd_total,
  mc_lower = z$lower$sd_mc, between_lower = z$lower$sd_between,
  mc_more = z$more$sd_mc, between_more = z$more$sd_between,
  naive_lower = z$lower$se_naive, naive_more = z$more$se_naive,
  infl_lower = z$lower$inflation,
  ratio_between_lower = z$lower$sd_between / z$lower$se_naive,
  ci_more = z$more$ci, ci_lower = z$lower$ci,
  B = z$B_OUT, R_IN = z$R_IN))

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
pb <- rd("analysis/out/pareto_benchmark.rds")
if (!is.null(pb)) J$pareto <- lapply(pb, function(M) {
  ci <- function(x) { x <- x[is.finite(x)]
    q <- replicate(2000, mean(sample(x, replace=TRUE)))
    c(est = mean(x), lo = unname(quantile(q,.025)), hi = unname(quantile(q,.975))) }
  list(R = nrow(M), n_match = median(M[,"n_match"]),
       rank_hr = ci(M[,"rank_hr"]), rank_rm = ci(M[,"rank_rm"]),
       front_hr = ci(M[,"on_frontier_hr"]), front_rm = ci(M[,"on_frontier_rm"]),
       n_dom = median(M[,"n_dominating"])) })
rbci <- rd("analysis/out/random_benchmark.rds")
if (!is.null(rbci)) J$random_ci <- lapply(rbci, function(M) {
  ci <- function(x) { x <- x[is.finite(x)]
    q <- replicate(3000, mean(sample(x, replace=TRUE)))
    c(est = mean(x), lo = unname(quantile(q,.025)), hi = unname(quantile(q,.975))) }
  list(hr = ci(M[,"beat_hr"]), cnt = ci(M[,"beat_n"])) })

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

## ---- round-3 additions ---------------------------------------------------
nst <- function(lab) {
  z <- rd(sprintf("analysis/out/nested_%s.rds", lab)); if (is.null(z)) return(NULL)
  M <- z$M; point <- M[1, ]; boot <- M[-1, , drop = FALSE]
  g <- function(nm) { if (!(nm %in% colnames(boot))) return(NULL)
    x <- boot[, nm]; x <- x[is.finite(x)]
    vt <- stats::var(x); ph <- mean(x); vm <- ph*(1-ph)/z$R_IN
    list(point = unname(point[nm]), sd_total = sqrt(vt), sd_mc = sqrt(vm),
         sd_outer = sqrt(max(vt - vm, 0)), ci = unname(stats::quantile(x, c(.025,.975)))) }
  out <- list(B = z$B_OUT, R = z$R_IN, bands = z$BANDS, margin = z$MARGIN,
              more = g("more"), lower = g("lower"),
              front_hr = g("front_hr"), front_rm = g("front_rm"), front_hrM = g("front_hrM"),
              n_dom = unname(point["n_dom"]), n_domM = unname(point["n_domM"]))
  for (b in z$BANDS) { out[[paste0("hr", b)]] <- g(paste0("rank_hr_", b))
                       out[[paste0("rm", b)]] <- g(paste0("rank_rm_", b))
                       out[[paste0("nm", b)]] <- unname(point[paste0("nmatch_", b)])
                       out[[paste0("sk", b)]] <- unname(point[paste0("skew_", b)]) }
  out
}
J$nested <- list(colon = nst("colon"), rott = nst("rott"))

fo <- rd("analysis/out/frontier_optimism.rds")
if (!is.null(fo)) { m <- function(x) mean(x[is.finite(x)])
  J$frontier_opt <- list(R = nrow(fo),
    dom_emp = median(fo[,"n_domA"]), dom_pop = median(fo[,"n_domP"]),
    front_emp = m(fo[,"front_emp"]), front_pop = m(fo[,"front_pop"]),
    repro = m(fo[,"repro_B"]), true_frac = m(fo[,"true_frac"])) }

rr <- rd("analysis/out/rmst_rule.rds")
if (!is.null(rr)) J$rmst_rule <- lapply(rr, function(M) { m <- function(x) mean(x[is.finite(x)])
  list(same = m(M[,"same_set"]), n_full = m(M[,"n_full"]), n_hr = m(M[,"n_hr"]), n_rm = m(M[,"n_rm"]),
       hr_lowerHR = m(M[,"hrrule_lowerHR"]), hr_moreRM = m(M[,"hrrule_moreRM"]),
       rm_lowerHR = m(M[,"rmrule_lowerHR"]), rm_moreRM = m(M[,"rmrule_moreRM"]),
       hrHR = m(M[,"hr_of_hrrule"]), rmHR = m(M[,"hr_of_rmrule"]), fullHR = m(M[,"hr_full"]),
       hrRM = m(M[,"rm_of_hrrule"]), rmRM = m(M[,"rm_of_rmrule"]), fullRM = m(M[,"rm_full"])) })

sn <- rd("analysis/out/snr_check.rds")
if (!is.null(sn)) J$snr <- as.data.frame(sn)

cw <- rd("analysis/out/colon_weighting_oos.rds")
if (!is.null(cw)) { m <- function(x) mean(x[is.finite(x)])
  J$colon_wt <- setNames(lapply(c("ps","known","none"), function(s) list(
    lower = m(cw[, paste0(s,"_lower")]), more = m(cw[, paste0(s,"_more")]),
    hr = m(cw[, paste0(s,"_hr")]), nkeep = m(cw[, paste0(s,"_nkeep")]))),
    c("ps","known","none")) }

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
writeLines(tojson(J), "analysis/out/numbers.json")
say(sprintf("exported %d blocks", length(J)))
