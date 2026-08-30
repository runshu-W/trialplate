\name{tp_interaction}
\alias{tp_interaction}
\title{Exact pairwise Shapley interaction indices}
\usage{
tp_interaction(V, p, col)
}
\arguments{
  \item{V}{Value matrix from \code{tp_enumerate}.}
  \item{p}{Number of criteria.}
  \item{col}{Outcome column index.}
}
\description{
Grabisch-Roubens pairwise interaction index for every criterion pair. Positive values are super-additive, negative values sub-additive.
}
\value{
A symmetric p by p matrix with a zero diagonal.
}
