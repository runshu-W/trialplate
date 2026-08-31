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

## ---- PRIMARY point estimates: the single source ---------------------------
## Reviewer round 4, point 1: every point estimate quoted anywhere comes from
## here, at the full split count. The nested bootstrap supplies uncertainty only.
prm <- function(lab) {
  z <- rd(sprintf("analysis/out/primary_%s.rds", lab)); if (is.null(z)) return(NULL)
  M <- z$M; m <- function(k) mean(M[, k], na.rm = TRUE)
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
            se_hr = sd(M[,"hr_rule"] - M[,"hr_full"])/sqrt(nrow(M)),
            d_n = m("n_rule") - m("n_full"), d_hr = m("hr_rule") - m("hr_full"),
            d_rm = m("rm_rule") - m("rm_full"))
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
  g <- function(M, nm, fn = mean) { x <- M[, nm]; unname(fn(x[is.finite(x)])) }
  one <- function(M) list(R = nrow(M),
    dom_sel = g(M, "n_domB", stats::median), dom_test = g(M, "n_domC", stats::median),
    front_sel = g(M, "front_B"), front_test = g(M, "front_C"),
    repro = g(M, "repro"), reproM = g(M, "reproM"),
    dom_selM = g(M, "n_domBM", stats::median), best_holds = g(M, "best_holds"))
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
  J$snr_curve <- list(cells = lapply(seq_len(nrow(sc$T)), function(i) as.list(sc$T[i, ])),
                      sp_snr = sc$sp_snr, sp_n = sc$sp_n, nrep = sc$nrep, sizes = sc$sizes)
}

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
}
writeLines(tojson(J), "analysis/out/numbers.json")
say(sprintf("exported %d blocks", length(J)))
