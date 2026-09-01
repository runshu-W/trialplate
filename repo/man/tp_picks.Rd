\name{tp_picks}
\alias{tp_picks}
\title{Protocols selected by each estimand}
\usage{
tp_picks(V, n_floor)
}
\arguments{
  \item{V}{Value matrix from \code{tp_enumerate}.}
  \item{n_floor}{Minimum eligible patients.}
}
\description{
Given a value matrix, returns the protocol minimising the hazard ratio and the one maximising the RMST difference, subject to a floor on eligible patients.
}
\value{
Named numeric vector including the identity of both selected subsets.
}
