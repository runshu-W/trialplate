## Reviewer major point 6. The main analysis uses the propensity specification
## the original work implies: a main-effects logistic on the recorded
## covariates, unstabilised IPTW, truncated at 0.05/0.95. On Rotterdam that
## specification does NOT achieve balance (6 of 8 covariates above 0.10 SMD,
## 132/419 propensities at the truncation bound, ESS 37% of nominal). This
## script asks whether a better-behaved specification changes the conclusion.
##
## Four specifications, all re-estimated inside every subset, split and
## bootstrap replicate exactly as the main analysis does:
##   M1 main effects, unstabilised, truncated 0.05/0.95     (the main analysis)
##   M2 M1 + natural splines on the continuous covariates
##   M3 M2 + stabilised weights
##   M4 M3 + asymmetric trimming to the common-support region
source("analysis/_setup.R")
ALLS <- function(E, S) { r <- E[, S[1]]; for (j in S[-1]) r <- r & E[, j]; r }

smd <- function(x, g, ww) {
  m1 <- weighted.mean(x[g==1], ww[g==1]); m0 <- weighted.mean(x[g==0], ww[g==0])
  v1 <- sum(ww[g==1]*(x[g==1]-m1)^2)/sum(ww[g==1]); v0 <- sum(ww[g==0]*(x[g==0]-m0)^2)/sum(ww[g==0])
  if (!is.finite(v1+v0) || (v1+v0) == 0) return(NA_real_)
  (m1-m0)/sqrt((v1+v0)/2)
}

wts <- function(d, ps, tr, spec) {
  cont <- ps[vapply(ps, function(v) length(unique(d[[v]])) > 6, logical(1))]
  fml <- if (spec == "M1") paste("~", paste(ps, collapse="+")) else
    paste("~", paste(c(setdiff(ps, cont),
      sprintf("splines::ns(%s, 3)", cont)), collapse="+"))
  X <- model.matrix(as.formula(fml), d)
  e <- fast_logit(X, tr)
  keep <- rep(TRUE, length(tr))
  if (spec == "M4") {                       # common support: overlap region
    lo <- max(min(e[tr==1]), min(e[tr==0])); hi <- min(max(e[tr==1]), max(e[tr==0]))
    keep <- e >= lo & e <= hi
  }
  et <- pmin(pmax(e, 0.05), 0.95)
  w <- tr/et + (1-tr)/(1-et)
  if (spec %in% c("M3","M4")) { pt <- mean(tr); w <- tr*pt/et + (1-tr)*(1-pt)/(1-et) }
  list(w = w, e = e, keep = keep, n_trunc = sum(e <= 0.05 | e >= 0.95))
}

report <- function(d, crit, ps, trt, tm, st, tau, label) {
  pr <- tp_prepare(d, crit, trt, tm, st, ps, tau = tau)
  fullk <- ALLS(pr$E, seq_len(pr$p))
  dd <- pr$d[fullk, , drop = FALSE]; tr <- pr$trt[fullk]
  cat(sprintf("\n===== %s : full protocol, n = %d, events = %d =====\n",
              label, sum(fullk), sum(pr$status[fullk])))
  cat(sprintf("%-4s %10s %10s %10s %8s %10s\n",
              "spec","max|SMD|",">0.10","ESS","trunc","n kept"))
  for (spec in c("M1","M2","M3","M4")) {
    r <- tryCatch(wts(dd, ps, tr, spec), error = function(e) NULL)
    if (is.null(r)) { cat(sprintf("%-4s   failed\n", spec)); next }
    k <- r$keep; w <- r$w[k]; g <- tr[k]
    X <- model.matrix(as.formula(paste("~", paste(ps, collapse="+"))), dd)[k, , drop=FALSE]
    s <- vapply(colnames(X)[-1], function(v)
      if (stats::sd(X[,v]) == 0) NA_real_ else abs(smd(X[,v], g, w)), numeric(1))
    s <- s[is.finite(s)]
    cat(sprintf("%-4s %10.3f %10d %10.0f %8d %10d\n",
        spec, max(s), sum(s > 0.10), sum(w)^2/sum(w^2), r$n_trunc, sum(k)))
  }
}

sink("analysis/out/ps_sensitivity.txt", split = TRUE)
report(colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825, "colon (randomised)")
report(rott_data(),  rott_criteria,  rott_ps,  "trt","dtime","death", 2555, "Rotterdam (registry)")
sink()
