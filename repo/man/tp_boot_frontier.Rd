\name{tp_boot_frontier}
\alias{tp_boot_frontier}
\title{Bootstrap the two relaxation frontiers}
\usage{
tp_boot_frontier(prep, fit, B = 400L, cores = 2L, seed = 20260829)
}
\arguments{
  \item{prep}{A \code{tp_prep} object.}
  \item{fit}{A \code{tp_fit} result.}
  \item{B}{Number of resamples.}
  \item{cores}{Worker count.}
  \item{seed}{Random seed.}
}
\description{
Resamples patients, rebuilds the hazard-ratio and RMST frontiers, and records which protocol each selects. Use \code{tp_stability} on the result before interpreting any disagreement.
}
\value{
A matrix, one row per resample.
}
