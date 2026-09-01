\name{tp_enumerate}
\alias{tp_enumerate}
\title{Evaluate every criteria subset}
\usage{
tp_enumerate(prep)
}
\arguments{
  \item{prep}{A \code{tp_prep} object.}
}
\description{
Exact enumeration of all 2^p subsets. Feasible for p up to roughly 16.
}
\value{
A 2^p by 5 matrix of value-function rows.
}
