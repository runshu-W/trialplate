\name{tp_perm}
\alias{tp_perm}
\title{Global permutation test on the whole interaction matrix}
\usage{
tp_perm(prep, fit, P = 500L, cores = 2L, seed = 20260829)
}
\arguments{
  \item{prep}{A \code{tp_prep} object.}
  \item{fit}{A \code{tp_fit} result.}
  \item{P}{Number of permutations.}
  \item{cores}{Worker count.}
  \item{seed}{Random seed.}
}
\description{
One degree of freedom instead of many marginal tests: is the interaction matrix distinguishable from what treatment-label noise produces? Defined only for the benefit estimands, since permuting treatment cannot change eligible counts.
}
\value{
List with the observed statistics, the null distribution and permutation p-values.
}
