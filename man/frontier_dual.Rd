\name{frontier_dual}
\alias{frontier_dual}
\title{The two relaxation frontiers}
\usage{
frontier_dual(fit, main = "")
}
\arguments{
  \item{fit}{A \code{tp_fit} result.}
  \item{main}{Overall title.}
}
\description{
Plots every protocol on the eligible-count plane twice, once scored by hazard ratio and once by RMST difference, marking each frontier's own optimum and the other's.
}
\value{
Invisibly, the selected protocols and the plotted values.
}
