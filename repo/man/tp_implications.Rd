\name{tp_implications}
\alias{tp_implications}
\title{Detect criteria that logically imply one another}
\usage{
tp_implications(prep)
}
\arguments{
  \item{prep}{A \code{tp_prep} object.}
}
\description{
If criterion i implies criterion j then v(S union {i,j}) equals v(S union {i}) for every S, so the pair's interaction index degenerates to minus the marginal contribution of j. Such cells are arithmetic, not evidence, and must be removed from the test family.
}
\value{
List with \code{implies}, \code{determined} and a \code{pairs} data frame (NULL when no implication is found).
}
