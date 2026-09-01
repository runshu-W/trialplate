\name{tp_shapley}
\alias{tp_shapley}
\title{Exact Shapley main effects}
\usage{
tp_shapley(V, p, col)
}
\arguments{
  \item{V}{Value matrix from \code{tp_enumerate}.}
  \item{p}{Number of criteria.}
  \item{col}{Outcome column index (1 log HR, 2 RMST difference, 3 log n).}
}
\description{
Shapley value of each criterion for one outcome column, computed exactly rather than by Monte Carlo.
}
\value{
Numeric vector of length p. Satisfies the efficiency axiom exactly.
}
