## Loads trialplate from the installed package when it is available, and
## otherwise straight out of R/, so these scripts run before installation.
if (requireNamespace("trialplate", quietly = TRUE)) {
  library(trialplate)
} else {
  for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
}
dir.create("analysis/out", showWarnings = FALSE, recursive = TRUE)
say <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); utils::flush.console() }

## The one stratified split used by every observed-cohort analysis, so that two
## scripts given the same seed and split count produce the same splits.
strat_split <- function(d, trt, st, frac) {
  key <- interaction(d[[trt]], d[[st]], drop = TRUE)
  unlist(lapply(split(seq_len(nrow(d)), key), function(ix)
    if (length(ix) < 2) ix else sample(ix, max(1, floor(frac * length(ix))))))
}
