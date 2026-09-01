\name{plate_criteria}
\alias{plate_criteria}
\title{The criteria plate plot}
\usage{
plate_criteria(sm, fit, leverage = NULL, lev_min = 0.05, order_by = "HR", hide_ns = FALSE, top_k = NULL, rmax = 0.4, title = "", sub = "")
}
\arguments{
  \item{sm}{A \code{tp_summarise} result.}
  \item{fit}{A \code{tp_fit} result.}
  \item{leverage}{Optional leverage matrix from \code{tp_leverage}.}
  \item{lev_min}{Leverage below which a cell is hatched as structurally uninformative.}
  \item{order_by}{Outcome used to order criteria.}
  \item{hide_ns}{Drop plates whose adjusted q exceeds 0.05.}
  \item{top_k}{Show only this many criteria.}
  \item{rmax}{Maximum plate radius.}
  \item{title}{Plot title.}
  \item{sub}{Plot subtitle.}
}
\description{
A compact square matrix carrying pairwise interactions on two benefit estimands (upper triangle log hazard ratio, lower triangle RMST difference), per-criterion main effects on the diagonal shaded by patient cost, and hatching for cells that are arithmetic identities or that lack the leverage to show an interaction. Visual grammar after Ren et al. (2026).
}
\value{
Invisibly, the criterion order and the two radius scales.
}
