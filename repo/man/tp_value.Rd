\name{tp_value}
\alias{tp_value}
\title{Value function for one criteria subset}
\usage{
tp_value(prep, S)
}
\arguments{
  \item{prep}{A \code{tp_prep} object.}
  \item{S}{Integer vector of criterion indices.}
}
\description{
Returns the two benefit estimands and the eligible count for the cohort selected by a subset of criteria: the IPT-weighted log hazard ratio, the difference in restricted mean survival time, and log n, plus feasibility and tau-extrapolation flags.
}
\value{
Named numeric vector: logHR, rmstD, logN, feasible, tau_ok.
}
