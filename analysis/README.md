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
| `split_eval.R`, `split_sim.R` | out-of-sample estimand comparison and its sample-size curve | 15 min |

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
5. `sim_coverage.R`, `control_stability.R` — the checks that keep the above honest
