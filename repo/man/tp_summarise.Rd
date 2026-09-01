\name{tp_summarise}
\alias{tp_summarise}
\title{Assemble intervals, adjusted p-values and ranking scores}
\usage{
tp_summarise(fit, boot, jack, level = 0.95, exclude = NULL)
}
\arguments{
  \item{fit}{A \code{tp_fit} result.}
  \item{boot}{A \code{tp_boot} result.}
  \item{jack}{A \code{tp_jack} result.}
  \item{level}{Interval level.}
  \item{exclude}{Optional logical matrix of cells to drop from the test family.}
}
\description{
BCa intervals from the bootstrap and grouped jackknife; significance bands come from interval inversion (the smallest alpha at which the interval excludes zero) rather than a home-made p-value, and are then Benjamini-Hochberg adjusted across the pair family with logically determined cells removed first.
}
\value{
A list with one entry per outcome holding estimates, intervals, p and q values and CRS scores.
}
