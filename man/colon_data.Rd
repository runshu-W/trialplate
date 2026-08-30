\name{colon_data}
\alias{colon_data}
\alias{colon_criteria}
\alias{colon_criteria_nested}
\alias{colon_ps}
\alias{rott_data}
\alias{rott_criteria}
\alias{rott_ps}
\title{Two fully public cohorts and their criteria sets}
\usage{
colon_data()
rott_data()
}
\description{
\code{colon_data} returns the adjuvant colon-cancer trial from \code{survival},
restricted to the Lev+5FU and observation arms (n = 619): a randomised cohort,
which makes the mapping from criteria to hazard ratio free of confounding and so
a clean bench for validating the estimators. \code{rott_data} returns the
Rotterdam breast-cancer registry (n = 2982) with chemotherapy as the treatment,
the observational companion.

\code{colon_criteria} and \code{rott_criteria} are nine plausible criteria each,
constructed from the available covariates for methodological illustration; they
are not the trials' actual protocol text. Both sets are chosen to contain no
logical implications. \code{colon_criteria_nested} adds one deliberately nested
criterion and exists only to demonstrate \code{\link{tp_implications}}.
}
\value{
\code{colon_data} and \code{rott_data} return data frames. The criteria objects
are named lists of eligibility functions; the \code{_ps} objects are character
vectors of propensity-model covariates.
}
