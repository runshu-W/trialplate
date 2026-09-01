if (requireNamespace("testthat", quietly = TRUE)) {
  library(testthat)
  library(trialplate)
  test_check("trialplate")
} else {
  message("testthat not installed; skipping tests")
}
