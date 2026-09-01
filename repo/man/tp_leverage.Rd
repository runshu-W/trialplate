\name{tp_leverage}
\alias{tp_leverage}
\title{Interaction leverage: can a criterion pair show an interaction at all?}
\usage{
tp_leverage(prep)
}
\arguments{
  \item{prep}{A \code{tp_prep} object.}
}
\description{
For the common structure in which extra benefit accrues only to patients meeting BOTH criteria, the four-point difference driving the Shapley interaction is proportional to 1 - p_ij/p_i - p_ij/p_j + p_ij, computable from eligibility rates alone before any outcome is touched. It vanishes as criteria become permissive: two criteria that each keep 85 percent of the cohort have leverage near 0.02 and cannot show an interaction however strong the underlying effect modification. A null interaction therefore does NOT imply no effect modification.
}
\value{
A symmetric p by p matrix, with the marginal eligibility rates attached as the \code{marginal} attribute.
}
