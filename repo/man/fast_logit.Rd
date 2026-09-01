\name{fast_logit}
\alias{fast_logit}
\title{IRLS logistic regression for the propensity score}
\usage{
fast_logit(X, y, maxit = 25, tol = 1e-08, start = NULL)
}
\arguments{
  \item{X}{Design matrix including the intercept column.}
  \item{y}{Binary response.}
  \item{maxit}{Maximum iterations.}
  \item{tol}{Convergence tolerance.}
  \item{start}{Optional starting coefficients.}
}
\description{
A lean iteratively reweighted least squares fit with a tiny ridge for separation and an optional warm start. Agrees with \code{glm.fit} to about 1e-8.
}
\value{
Fitted probabilities.
}
