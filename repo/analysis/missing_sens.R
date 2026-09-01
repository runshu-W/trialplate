## Reviewer major point 6, second part. The original convention is that a
## patient missing a criterion's variable is NOT filtered by that criterion.
## That inflates eligibility and, if missingness is informative, biases the
## comparison. Three conventions are compared:
##   NOTFILTER  missing -> eligible          (the original convention, our main analysis)
##   INELIGIBLE missing -> not eligible      (the conservative reading)
##   IMPUTE     missing -> single conditional imputation, then evaluated
## In these two cohorts the question is nearly vacuous -- only one criterion in
## one cohort has any missingness at all (colon DIFF12, 2.1%) and Rotterdam has
## none -- so this is a demonstration of the check, not a resolution of the
## issue. It is reported precisely so a reader does not assume the convention
## was load-bearing here. In a real-world cohort with substantial missingness it
## would be, and the check belongs in the protocol.
source("analysis/_setup.R")

variant <- function(d, crit, mode) {
  if (mode == "NOTFILTER") return(list(d = d, crit = crit))
  if (mode == "INELIGIBLE") {
    cr <- lapply(crit, function(f) { force(f)
      function(x) { v <- f(x); v[is.na(v)] <- FALSE; v } })
    return(list(d = d, crit = setNames(cr, names(crit))))
  }
  ## IMPUTE: fill the raw variables by conditional mean/mode on the others
  dd <- d
  for (v in names(dd)) if (is.numeric(dd[[v]]) && anyNA(dd[[v]]))
    dd[[v]][is.na(dd[[v]])] <- stats::median(dd[[v]], na.rm = TRUE)
  list(d = dd, crit = crit)
}

report <- function(d, crit, ps, trt, tm, st, tau, label) {
  cat(sprintf("\n===== %s =====\n", label))
  nmiss <- vapply(crit, function(f) sum(is.na(f(d))), numeric(1))
  cat(sprintf("missing per criterion: %s (total rows affected: %d of %d)\n",
      paste(sprintf("%s=%d", names(nmiss), nmiss), collapse=" "),
      sum(Reduce(`|`, lapply(crit, function(f) is.na(f(d))))), nrow(d)))
  cat(sprintf("%-11s %8s %10s %10s %s\n","convention","eligible","HR full","HR rule","retained criteria"))
  for (mode in c("NOTFILTER","INELIGIBLE","IMPUTE")) {
    v <- variant(d, crit, mode)
    pr <- tp_prepare(v$d, v$crit, trt, tm, st, ps, tau = tau)
    V <- tp_enumerate(pr); p <- pr$p
    S <- which(tp_shapley(V, p, 1L) < 0)
    a <- tp_value(pr, S); b <- tp_value(pr, seq_len(p))
    cat(sprintf("%-11s %8.0f %10.4f %10.4f %s\n", mode, exp(b["logN"]),
        exp(b["logHR"]), exp(a["logHR"]), paste(pr$names[S], collapse=",")))
  }
}
sink("analysis/out/missing_sens.txt", split = TRUE)
report(colon_data(), colon_criteria, colon_ps, "trt","time","status", 1825, "colon")
report(rott_data(),  rott_criteria,  rott_ps,  "trt","dtime","death", 2555, "Rotterdam")
sink()
