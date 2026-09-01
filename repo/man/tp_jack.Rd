\name{tp_jack}
\alias{tp_jack}
\title{Grouped jackknife for the BCa acceleration constant}
\usage{
tp_jack(prep, K = 50L, cores = 2L, seed = 20260829)
}
\arguments{
  \item{prep}{A \code{tp_prep} object.}
  \item{K}{Number of groups.}
  \item{cores}{Worker count.}
  \item{seed}{Random seed.}
}
\description{
A leave-one-out jackknife would need n enumerations; K groups need K.
}
\value{
A list of per-group summaries.
}
