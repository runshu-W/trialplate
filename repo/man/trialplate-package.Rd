\name{trialplate-package}
\alias{trialplate-package}
\alias{trialplate}
\docType{package}
\title{Sample-Size Diagnostics for Data-Driven Trial Eligibility Criteria}
\description{
Rules that relax trial eligibility criteria from data make two separate promises:
that more patients become eligible, and that the treatment-effect estimate does
not suffer. This package supplies the machinery to check both out of sample, and
the diagnostics that say in advance whether a given cohort can support the check.

The two promises behave differently. Enrolling more patients does not require the
rule to select the right criteria and is delivered robustly. Improving the
effect estimate does require it, and has a training-size threshold: in a
randomised setting around 3,000 patients in the fitting cohort, and roughly twice
that when treatment assignment is confounded even if the confounding is correctly
adjusted for. Below the threshold the reported improvement is in-sample selection.

A further warning falls out of the same experiments: when confounding is NOT
fully adjusted for, the procedure looks MORE reliable, because the gap it detects
is inflated by bias. Apparent success on real-world data is therefore not
evidence that the adjustment was adequate.

Two diagnostics are computable before any outcome is examined.
\code{\link{tp_leverage}} says whether a criterion pair can exhibit a pairwise
interaction at all; permissive criteria of the kind real protocols use cannot.
\code{\link{tp_implications}} flags criteria that logically imply one another,
whose interaction cell is an arithmetic identity rather than evidence.

Both benefit estimands are carried in parallel throughout, the log hazard ratio
and the difference in restricted mean survival time, because the hazard ratio is
non-collapsible: restricting a cohort moves the marginal hazard ratio even when
every stratum's treatment effect is identical.
}
\references{
Liu R, Rizzo S, Whipple S, et al. Evaluating eligibility criteria of oncology
trials using real-world data and AI. Nature 2021;592:629-33.

Ren Y, Wang Z, Lin L, Zhao S, Chu H. A novel visualization approach for network
meta-analysis: the plate plot and the nmaplateplot R package. Research Synthesis
Methods 2026;17:1045-53.

Grabisch M, Roubens M. An axiomatic approach to the concept of interaction among
players in cooperative games. Int J Game Theory 1999;28:547-65.

Hernan MA. The hazards of hazard ratios. Epidemiology 2010;21:13-5.

Uno H, Claggett B, Tian L, et al. Moving beyond the hazard ratio in quantifying
the between-group difference in survival analysis. J Clin Oncol 2014;32:2380-5.
}
