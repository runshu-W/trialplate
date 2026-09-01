\name{tp_prepare}
\alias{tp_prepare}
\title{Prepare a cohort for eligibility-criteria analysis}
\usage{
tp_prepare(data, criteria, trt, time, status, ps_covars, tau = NULL, ridge = 0.1, min_per_arm = 5)
}
\arguments{
  \item{data}{A data frame, one row per patient.}
  \item{criteria}{Named list of functions; each takes the data frame and returns a logical eligibility vector.}
  \item{trt}{Name of the binary treatment column.}
  \item{time}{Name of the follow-up time column.}
  \item{status}{Name of the event indicator column.}
  \item{ps_covars}{Character vector of covariates for the propensity model.}
  \item{tau}{Restriction time for RMST. Defaults to the 90th percentile of observed event times.}
  \item{ridge}{L2 penalty on the treatment coefficient, on the raw scale.}
  \item{min_per_arm}{Minimum patients per arm for a subset to be estimable.}
}
\description{
Sorts the cohort by time once, so that every criteria subset inherits the ordering and never has to be re-sorted, builds the eligibility matrix (a patient with a missing value is NOT filtered out by that criterion, following the Trial Pathfinder convention) and the propensity-score design matrix.
}
\value{
An object of class \code{tp_prep}.
}
