\name{tp_boot}
\alias{tp_boot}
\title{Nonparametric bootstrap over patients}
\usage{
tp_boot(prep, B = 2000, cores = 2L, seed = 20260829)
}
\arguments{
  \item{prep}{A \code{tp_prep} object.}
  \item{B}{Number of resamples.}
  \item{cores}{Worker count.}
  \item{seed}{Random seed.}
}
\description{
Resamples patients and recomputes the Shapley summaries. Indices are drawn serially before dispatch, so results are reproducible from the seed regardless of the parallel backend.
}
\value{
A list of per-replicate summaries.
}
