\name{tp_fit}
\alias{tp_fit}
\title{One full analysis pass}
\usage{
tp_fit(prep, V = NULL)
}
\arguments{
  \item{prep}{A \code{tp_prep} object.}
  \item{V}{Optionally a precomputed value matrix.}
}
\description{
Enumerates all subsets and returns Shapley main effects and pairwise interactions on all three outcomes, together with the implication map and feasibility counts.
}
\value{
A list with phi_HR, phi_RMST, phi_N, I_HR, I_RMST, I_N, impl and diagnostics.
}
