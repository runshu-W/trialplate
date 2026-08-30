# Analysis scripts

These reproduce the paper. They are **not** part of the R package — the package
holds the estimators and diagnostics, these scripts hold the study design.

Run from the repository root. `_setup.R` loads `trialplate` if installed and
otherwise sources `R/` directly, so nothing needs installing first. Outputs go to
`analysis/out/`, which is gitignored; regenerate rather than commit them.

| script | what it produces | roughly |
|---|---|---|
| `run_colon.R` | fit, B = 2000 bootstrap, K = 50 jackknife, P = 500 permutation | 20 min, 2 cores |
| `run_rotterdam.R` | the same on the registry cohort | 80 min, 2 cores |
| `rule_eval.R` | **the main result** — out-of-sample test of the published rule | 8 min |
| `frac_sens.R` | the same at a 0.7 fitting fraction | 12 min |
| `sim_trainsize.R` | the training-size threshold curve, fixed 100k test set | 18 min |
| `sim_confound.R` | the three confounding arms | 25 min |
| `sim_sweep.R` | non-collapsibility as a dose–response | 3 min |
| `sim_power.R` | power to detect a planted interaction | 15 min |
| `sim_coverage.R` | BCa interval coverage against known truth | 35 min |
| `control_stability.R` | is the protocol choice stable at all? | 10 min |
| `tau_sens.R` | does the RMST horizon change the answer? | 12 min |
| `scale_check.R` | does HR vs log HR change which criteria are selected? | 12 min |
| `scale_ruleeval.R` | does that choice move the headline numbers? | 25 min |
| `split_eval.R`, `split_sim.R` | out-of-sample estimand comparison and its sample-size curve | 15 min |
| `fig_design.R` | Figure 1, the study-design schematic — pure graphics, no data | instant |

### Added in the major revision

| script | what it answers | reviewer point |
|---|---|---|
| `random_benchmark.R` | is the eligibility gain anything more than removing k criteria at random? | major 1 |
| `factorial_threshold.R` | how much does the threshold move across a 2^(6-2) factorial, in patients / events / ESS? | major 3 |
| `split_dependence.R` | nested resampling: population uncertainty vs across-split uncertainty | major 4 |
| `cohort_tables.R` | criteria table, balance, overlap, effective sample size | major 6, minor 4 |
| `ps_sensitivity.R` | four propensity specifications; none repairs Rotterdam | major 6 |
| `overlap_vs_restriction.R` | does restriction itself degrade overlap? (no) | major 6 |
| `missing_sens.R` | three missingness conventions | major 6 |
| `leverage_forms.R` | leverage coefficient for AND / OR / XOR interaction forms | major 8 |
| `recovery_metrics.R` | Hamming, Jaccard, false retention/relaxation, regret | minor 2 |
| `figures.R` | Figures 2–5 with Monte Carlo bars and an Okabe–Ito palette | minor 5, 8 |
| `export_numbers.R` | writes `out/numbers.json`, which the manuscript build reads | major 9 |

### Added in the second revision

| script | what it answers | reviewer point |
|---|---|---|
| `pareto_benchmark.R` | scores all 512 subsets out of sample: matched on eligible count, and the attainable frontier | R2 major 2 |
| `factorial_reanalysis.R` | success at fixed size across all 16 scenarios; interval-censored regression; currency comparison without conditioning | R2 major 3 |
| `concentration_sweep.R` | separates how spread the modification is from how strong the diluting signal is | R2 major 4 |
| `ph_and_weights.R` | proportional-hazards test; weighting a randomised trial three ways | R2 major 7, minors |
| `fig_overlap.R` | Figure S3, propensity distributions inside the full protocol | R2 major 7 |

`split_dependence.R` was rewritten: the previous version bootstrapped the cohort and
split the resampled ROWS, so duplicate copies of one patient could fall on opposite
sides of the inner split. It now splits unique patient identifiers and asserts that
the halves share none. Correcting the leak narrowed the intervals.

Two claims from the first version did not survive review and are corrected in the
code as well as the text. Shapley efficiency is exact on the hazard-ratio scale as
well as the log scale — the package now asserts both — and low interaction leverage
is attenuation rather than structural invisibility, which only logical implication
produces. Two more did not survive the second review: the claim that events and
effective sample size travel worse than patients (a selection-biased summary over
the six scenarios where a threshold was observable) and the description of the
governing factor as "concentration" (which confounded how spread the modification
is with how strong the diluting coefficient is).

`sim_dgp.R` holds the generating process for the planted-interaction simulations.
Its header records why the first version of that design planted no detectable
signal — the reason turned into the interaction-leverage result, so it is kept.

`archive/` is the superseded first-pass implementation, retained for provenance.
Nothing in the current analysis depends on it.

## Order of the argument

1. `rule_eval.R` — the published rule keeps one promise and not the other
2. `sim_trainsize.R` — the failure is a fitting-cohort-size threshold, not the rule
3. `sim_confound.R` — confounding moves the threshold, and unmeasured confounding hides itself
4. `sim_sweep.R` — why the hazard ratio is the fragile leg
5. `sim_coverage.R`, `control_stability.R`, `tau_sens.R` — the checks that keep the above honest

`tau_sens.R` doubles as an implementation check: the rule selects on the log hazard
ratio, so the truncation horizon cannot reach the selection. If the eligible-count
or hazard-ratio columns move with tau, something is wrong. They don't.

`scale_check.R` and `scale_ruleeval.R` close the one gap between this
implementation and the published one. The original states the rule as "Shapley
value less than 0" and reports hazard ratios, but does not say whether the
decomposition runs on HR or log HR. We use log HR (the additive scale of a
ratio, which is what the Shapley axioms assume). The two scales select an
identical criterion set on each full cohort, agree in 86.3% / 82.7% of
half-samples, and move neither headline probability.
