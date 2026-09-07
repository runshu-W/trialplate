## Verification script for the outer-bootstrap claims made in the Methods, in
## Supplementary Tables S3, S3c and S1g, and in the responses to the ninth and tenth
## reviews. It reads the stored result objects and the analysis sources, and CHECKS
## rather than asserts, so an editor can confirm the claims without rerunning any
## analysis. Run from the repository root:  Rscript analysis/check_outer.R
##
## An earlier draft of this script printed two of its four statements as fixed text.
## Both are now derived: the nominal replicate count is read out of the analysis
## script and compared with the number of rows actually stored, which is what would
## reveal a discarded replicate; and the two lines of source that decide the
## observed-data replicate and the Monte Carlo denominator are located and printed.

src_int <- function(file, pattern) {          # read a default out of the source
  ln <- grep(pattern, readLines(file, warn = FALSE), value = TRUE)
  if (!length(ln)) return(NA_integer_)
  as.integer(sub('.*"([0-9]+)".*', "\\1", ln[1]))
}
src_line <- function(file, pattern) {
  ln <- readLines(file, warn = FALSE); i <- grep(pattern, ln, fixed = TRUE)
  if (!length(i)) return(NULL)
  sprintf("%s:%d: %s", file, i[1], trimws(ln[i[1]]))
}

JOBS <- list(
  list(rds = "analysis/out/nested_colon.rds",           src = "analysis/nested_all.R",
       pat = 'B_OUT <- as.integer\\(Sys.getenv\\("BOUT"'),
  list(rds = "analysis/out/nested_rott.rds",            src = "analysis/nested_all.R",
       pat = 'B_OUT <- as.integer\\(Sys.getenv\\("BOUT"'),
  list(rds = "analysis/out/threeway_nested_colon.rds",  src = "analysis/threeway_nested.R",
       pat = 'B_OUT <- as.integer\\(Sys.getenv\\("TW_B"'),
  list(rds = "analysis/out/threeway_nested_rott.rds",   src = "analysis/threeway_nested.R",
       pat = 'B_OUT <- as.integer\\(Sys.getenv\\("TW_B"'))

ok <- TRUE
for (j in JOBS) {
  if (!file.exists(j$rds)) { cat("MISSING", j$rds, "\n"); ok <- FALSE; next }
  z <- readRDS(j$rds); M <- z$M; Kb <- z$K[-1, , drop = FALSE]
  nominal <- src_int(j$src, j$pat)
  nf <- sum(!is.finite(M))
  cat(sprintf("\n%s\n  rows stored %d; nominal replicate count in %s: %s\n",
              j$rds, nrow(M), j$src, ifelse(is.na(nominal), "not found", nominal)))
  if (is.na(nominal)) { cat("  *** could not read the nominal count; cannot rule out a discarded replicate ***\n"); ok <- FALSE }
  else if (nrow(M) != nominal) { cat(sprintf("  *** %d replicate(s) DISCARDED ***\n", nominal - nrow(M))); ok <- FALSE }
  else cat("  no replicate was discarded: every attempted replicate is stored\n")
  cat(sprintf("  non-finite cells in the result matrix: %d   %s\n", nf,
              if (nf == 0) "(no replicate failed)" else "*** FAILURE ***"))
  cat(sprintf("  the first row is the observed-data evaluation, so %d bootstrap resamples form the ranges\n",
              nrow(M) - 1L))
  cat(sprintf("  usable inner splits (bootstrap resamples only): smallest %d of %d; statistics always at the nominal count %d of %d; statistics undefined in a whole resample %d\n",
              min(Kb), z$R_IN, sum(apply(Kb, 2, min) == z$R_IN), ncol(Kb), sum(Kb == 0)))
  short <- colnames(Kb)[apply(Kb, 2, min) < z$R_IN]
  for (nm in short)
    cat(sprintf("    %-16s min %2d  median %2d  max %2d  resamples below nominal %3d of %3d\n",
                nm, min(Kb[, nm]), stats::median(Kb[, nm]), max(Kb[, nm]),
                sum(Kb[, nm] < z$R_IN), nrow(Kb)))
  if (nf > 0 || any(Kb == 0)) ok <- FALSE
}

## The source lines behind the statements above. These are collected with list()
## rather than c(): c() silently drops NULL, so a missing line would vanish from the
## sequence and the failure branch could never run -- the script would report a pass
## while having checked one thing fewer. A reviewer of the tenth revision caught that
## in an earlier draft of this file.
WANT <- list(
  list(file = "analysis/nested_all.R",      pat = "if (b == 1L) dat else",
       what = "the first replicate is the observed cohort, two-way"),
  list(file = "analysis/threeway_nested.R", pat = "if (b == 1L) dat else",
       what = "the first replicate is the observed cohort, three-way"),
  list(file = "analysis/nested_all.R",      pat = "Vb[, nm] / pmax(Kb[, nm], 1)",
       what = "Monte Carlo denominator is the usable count, analysis"),
  list(file = "analysis/export_numbers.R",  pat = "Vb[, nm] / pmax(Kb[, nm], 1)",
       what = "Monte Carlo denominator is the usable count, export"))

cat("\nThe source lines behind the statements above:\n")
for (w in WANT) {
  l <- src_line(w$file, w$pat)
  if (is.null(l)) { cat(sprintf("   *** NOT FOUND: %s (%s in %s) ***\n", w$what, w$pat, w$file)); ok <- FALSE }
  else cat("  ", l, "\n")
}

## A deliberate negative test, so the failure branch above is known to work rather
## than assumed to. If this ever prints "detected: no", the search is broken and
## nothing else this script reports about the sources can be trusted.
neg <- src_line("analysis/nested_all.R", "this line does not exist in the source")
cat(sprintf("  self-test, searching for a line that cannot be there: detected: %s\n",
            if (is.null(neg)) "yes" else "no"))
if (!is.null(neg)) ok <- FALSE

## The Monte Carlo term computed both ways, so the choice of denominator is visible
## rather than described.
z <- readRDS(JOBS[[1]]$rds); Vb <- z$V[-1, , drop = FALSE]; Kb <- z$K[-1, , drop = FALSE]
nm <- "rank_hr_0.02"
cat(sprintf("\nMonte Carlo term for %s in %s\n  dividing by each resample's own usable count: %.6f\n  dividing by the nominal count:                %.6f\n",
            nm, JOBS[[1]]$rds,
            mean((Vb[, nm] / pmax(Kb[, nm], 1))[is.finite(Vb[, nm])]),
            mean((Vb[, nm] / z$R_IN)[is.finite(Vb[, nm])])))

cat(if (ok) "\nALL CHECKS PASSED\n" else "\nCHECKS FAILED\n")
if (!ok) quit(status = 1L)
