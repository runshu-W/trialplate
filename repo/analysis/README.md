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

### Added in the third revision

| script | what it answers | reviewer point |
|---|---|---|
| `nested_all.R` | one nested resample carrying every out-of-sample quantity, so the matched and frontier statistics get patient-level uncertainty; four matching tolerances; margin-based dominance | R3 major 2, 3 |
| `frontier_optimism.R` | how optimistic the empirical held-out frontier is, against a known population | R3 major 1 |
| `rmst_rule.R` | a rule selecting on the RMST Shapley value instead of the log hazard ratio | R3 major 7 |
| `conc_targets.R` | are the arrangements comparable? full-protocol HR, oracle HR, gap, eligible fraction | R3 major 6 |
| `snr_check.R` | is a criterion-specific signal-to-noise ratio the better governing quantity? | R3 major 5 |
| `colon_weighting_oos.R` | the three weighting schemes carried through the full out-of-sample evaluation | R3 minor 1 |

### Added in the sixth revision

The fifth review's fixes were sound but incomplete in a specific way: we applied a
standard to most of the paper and then exempted the numbers we had just promoted to
the abstract.

| file | what it does |
|---|---|
| `threeway_nested.R` | wraps the whole fit / select / test pipeline in the outer bootstrap over patient identifiers, with the three-way split itself taken over unique ids. The confirmatory three-way quantities had been point estimates over repeated splits with no patient-level uncertainty, while the Methods claimed otherwise. |

`nested_all.R` also records the published rule's absolute-benefit indicator, which
was missing, and forms the PAIRED difference between the two rules inside each split.
Two intervals each formed against the full protocol cannot say which rule is better,
because the rules share patients and splits; the paired difference can, and it puts
both estimands' advantage at not established.

`export_numbers.R` gained an integer schema. The provenance check over the manuscript
sources cannot see bare integers, so 18 counts a reader relies on — both cohort sizes,
the criterion and subset counts, both horizons, every split and resample count, the
simulation replicate counts and the number of factorial scenarios — are asserted
individually and the build stops if any changes. It also logs the gap between the
three-way point estimate and the bootstrap's own observed-data replicate, which is
large (up to 0.14) and is reported in the paper rather than hidden by the tolerance.

Claims corrected in this round: the title and the Conclusions no longer say no
unconditional data requirement EXISTS, only that none could be determined from cohort
size, event count or effective sample size across the mechanisms simulated; the paper
now names all four interval procedures it uses instead of claiming two, and
acknowledges that the Monte Carlo one uses a multiplier; the across-scenario spread is
given as a range across sizes rather than as one value "at every fixed sample size",
which was false at two of the four sizes.

### Added in the fifth revision

The fifth review found that the fourth cover letter's central claim — that every
figure in the paper is generated from one result file — was false. Two superseded
result objects were still being read, and 84 figures were typed into prose by hand.
The remedy is a guard rather than another promise.

| file | what it does |
|---|---|
| `../manuscript/check_numbers.js` | scans every double-quoted string in all five document sources and fails the build on any decimal or percentage that is not a whitelisted design constant. Runs as the first step of `build.js`. |
| `confound_limits.R` | the three population gap limits for the confounding arms, which had been typed into `figures.R` **and** the Results from a parameterisation no longer in the repository |
| `out/superseded/` | five retired result objects, with a note on why each was retired. `export_numbers.R` refuses to run if any of them reappears in `out/`. |

Secondary runs that used to report their own estimate of a quantity the primary
analysis already covers — the weighting sensitivity and the horizon sweep — now use
the primary run's seed, split count and stratified split (`strat_split()` moved into
`_setup.R` so every script shares one function). `export_numbers.R` asserts that the
overlapping cells agree exactly.

Things the guard found that a reader would not have: a figure caption claiming a 32%
inflation where the current model gives 8.6%; a leverage over-prediction stated as
10–30% where it is 11–44%; Supplement Tables S1, S1b, S1c and S2b typed by hand; and
Figure 3 plotting the pre-correction Rotterdam values while reading its intervals
from a retired object. The guard does not test bare integers; those were checked by
hand for this revision.

### Added in the fourth revision

| script | what it answers | reviewer point |
|---|---|---|
| `primary.R` | **the single source of every observed-cohort point estimate quoted anywhere in the paper**: out-of-sample comparison, matched statistics at four tolerances, frontier and dominance counts, RMST-rule variant, all in one pass per cohort | R4 major 1 |
| `threeway.R` | fit on one third, find dominators on a second, re-evaluate them on an untouched third — the optimism of the held-out frontier measured inside the real cohorts | R4 major 3 |
| `horizon_sweep.R` | why these restricted-mean horizons, and how criterion-set agreement and the absolute-benefit ordering move with the horizon | R4 major 6 |
| `snr_curve.R` | success against a criterion-specific signal-to-noise ratio across arrangements and fitting sizes | R4 major 4 |

The fourth review began from a main-text / supplement inconsistency that the third
response had explained away as Monte Carlo noise. It was not. Eleven scripts had
been written with the Rotterdam endpoint as `("rtime", "death")` at `tau = 1825` —
the relapse-free TIME paired with the DEATH indicator, which is not a valid pair and
systematically shortens event times — while `rule_eval.R`, behind Table 1, correctly
used `("dtime", "death")` at `tau = 2555`. All eleven are corrected.

Two guards now make this class of error fail the build rather than reach a reviewer.
`primary.R` produces every point estimate in one place, and `export_numbers.R`
asserts on the exported numbers (endpoint names, both horizons, agreement between the
primary and nested estimates of the same quantity) *and* scans the source of every
analysis script, refusing to export if any line pairs `"rtime"` with `"death"` or
calls a Rotterdam dataset at the colon horizon. The nested bootstrap now supplies
uncertainty only and never a point estimate.

`nested_all.R` also changed in this revision: the inner Monte Carlo variance is
estimated from the sample variance of the per-split values within each resample
rather than assumed to be `p(1-p)/R`, which was correct only for the statistics that
are 0/1 within a split, and interval-endpoint convergence is reported for every
quantity rather than one.

`split_dependence.R` is superseded by `nested_all.R`, which carries the same two
promises plus everything else through one loop.

Two claims from the first version did not survive review and are corrected in the
code as well as the text. Shapley efficiency is exact on the hazard-ratio scale as
well as the log scale — the package now asserts both — and low interaction leverage
is attenuation rather than structural invisibility, which only logical implication
produces. Two more did not survive the second review: the claim that events and
effective sample size travel worse than patients (a selection-biased summary over
the six scenarios where a threshold was observable) and the description of the
governing factor as "concentration" (which confounded how spread the modification
is with how strong the diluting coefficient is).

### Added in the seventh revision

The seventh review made one criticism that was sharper than anything before it: the
nested bootstrap draws `B` outer resamples and takes `R` inner splits inside each, so
what it resamples is an `R`-split estimator, while the paper's point estimates come
from 400 or 500 splits. Its percentile interval therefore carries the inner Monte
Carlo variance on top of the population variance and is too wide by that amount.

| file | what it answers | reviewer point |
|---|---|---|
| `split_converge.R` | how the split-count estimator behaves as the split count grows: per-split spread, the implied Monte Carlo SD at each `R`, and the observed spread and mean of independent `R`-split estimates formed from disjoint blocks of one long run | R7 major 1 |
| `comparator_ties.R` | how often a comparator ties the rule exactly, since all comparisons are strict and a tie counts against the rule | R7 minor 6 |

Two things about `split_converge.R` are deliberate and easy to get wrong. It uses each
design's own point-estimate seed and split count (`primary.R` seed 101 over 500,
`threeway.R` seed 41 over 400, both as `set.seed(seed * 1000 + r)`), so the table is a
prefix of the reported run and its largest column reproduces the reported point rather
than contradicting it. And it reports the disjoint-block statistics alongside
`s / sqrt(R)`, because the latter is an identity once `s` is fixed and is therefore
evidence for nothing on its own; the block statistics are an observed spread and an
observed mean, and it is the block means' flatness in `R` that shows the split count
changes the estimator's variance and not its expectation.

`export_numbers.R` gained the deflated percentile interval — each outer replicate is
shrunk toward the mean by `sqrt((v_tot - v_mc) / v_tot)` before the percentiles are
taken — with an `estimable` flag, because for a quantity that is nearly constant
across resamples the estimated inner variance can exceed the total spread and the
deflated interval would be a degenerate point. It also gained the Monte Carlo standard
error of the percentile endpoints themselves, obtained by resampling the outer
replicates, and a cluster bootstrap over the sixteen factorial scenarios for the
difference between information currencies.

`cohort_tables.R` now stores the full correlation matrix of the eligibility indicators
rather than only printing it, so the supplement can show it (Table S1f).

Claims corrected in this round, most of them found by our own audit rather than by the
review: the currency difference had been reported as the bootstrap MEAN rather than the
observed difference, and because the quartile edges are recut inside each replicate the
two disagree in sign; "spreading the enrichment never hurts" is established at one
fitting size only; the effective-sample-size fraction "is flat in the number of
criteria" is a monotone decline, small but not absent; the Methods and Results
disagreed on how many interval procedures the paper uses; the eligibility curve is not
monotone in the fitting size and its minimum is not at the smallest rung; and the
factor by which correctly adjusted confounding raises the sample requirement depends on
the reliability target, so the target is now named.

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
