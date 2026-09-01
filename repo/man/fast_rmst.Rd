\name{fast_rmst}
\alias{fast_rmst}
\title{Weighted restricted mean survival time}
\usage{
fast_rmst(time, status, w, tau)
}
\arguments{
  \item{time}{Ascending follow-up times.}
  \item{status}{Event indicator.}
  \item{w}{Case weights.}
  \item{tau}{Restriction time.}
}
\description{
Area under a weighted Kaplan-Meier curve up to tau. Agrees exactly with the \code{rmean} entry of \code{summary(survfit(...))}. Time must already be in ascending order.
}
\value{
The restricted mean, a single number.
}
