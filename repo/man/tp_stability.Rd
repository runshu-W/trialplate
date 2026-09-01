\name{tp_stability}
\alias{tp_stability}
\title{Is the protocol choice stable at all?}
\usage{
tp_stability(M, pairs = 20000L, seed = 20260829)
}
\arguments{
  \item{M}{Matrix returned by \code{tp_boot_frontier}.}
  \item{pairs}{Number of random resample pairs to compare.}
  \item{seed}{Random seed.}
}
\description{
Comparing the protocol chosen on one estimand with the protocol chosen on another is only informative if each estimand can reproduce its own choice. This contrasts between-estimand agreement within one resample against within-estimand agreement across two resamples.
}
\value{
Named numeric vector of agreement probabilities and distinct-pick counts.
}
