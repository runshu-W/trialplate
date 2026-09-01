\name{tp_rule_eval}
\alias{tp_rule_eval}
\title{Out-of-sample test of a published selection rule}
\usage{
tp_rule_eval(prep, R = 400L, frac = 0.5, cores = 2L, seed = 20260829)
}
\arguments{
  \item{prep}{A \code{tp_prep} object.}
  \item{R}{Number of splits.}
  \item{frac}{Fraction used for fitting.}
  \item{cores}{Worker count.}
  \item{seed}{Random seed.}
}
\description{
Fits the rule "keep every criterion whose Shapley value on the log hazard ratio is negative, relax the rest" on one split and scores the resulting protocol against the original full protocol on the other, reporting eligible count, hazard ratio and RMST difference together.
}
\value{
A matrix, one row per split, holding both protocols' out-of-sample values.
}
