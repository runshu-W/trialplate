## Loads trialplate from the installed package when it is available, and
## otherwise straight out of R/, so these scripts run before installation.
if (requireNamespace("trialplate", quietly = TRUE)) {
  library(trialplate)
} else {
  for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
}
dir.create("analysis/out", showWarnings = FALSE, recursive = TRUE)
say <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); utils::flush.console() }
