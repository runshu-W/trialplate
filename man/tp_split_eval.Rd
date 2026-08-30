\name{tp_split_eval}
\alias{tp_split_eval}
\title{Out-of-sample comparison of two selection estimands}
\usage{
tp_split_eval(prep, fit, R = 400L, frac = 0.5, cores = 2L, seed = 20260829)
}
\arguments{
  \item{prep}{A \code{tp_prep} object.}
  \item{fit}{A \code{tp_fit} result.}
  \item{R}{Number of splits.}
  \item{frac}{Fraction of patients used for selection.}
  \item{cores}{Worker count.}
  \item{seed}{Random seed.}
}
\description{
Selecting a protocol and scoring it in the same sample is rigged: the protocol that maximises an estimand there wins on that estimand by construction. This selects on one split and scores on the other.
}
\value{
A matrix, one row per split.
}
