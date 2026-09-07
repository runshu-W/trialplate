# trialplate

**Sample-size diagnostics for data-driven trial eligibility criteria.**

Rules that relax clinical-trial eligibility criteria using real-world data make two
separate promises: that more patients become eligible, and that the estimated
treatment effect does not suffer. This package validates both out of sample, and
supplies the diagnostics that say in advance whether a cohort can support the check.

The two promises behave differently, and the difference is the point.

| | more patients | lower hazard ratio |
|---|---|---|
| fitting cohort = 300 | 0.950 | 0.273 |
| fitting cohort = 3 000 | 0.973 | 0.800 |
| fitting cohort = 5 167 | 0.990 | **0.937** |
| fitting cohort = 20 000 | 1.000 | 0.997 |

*Probability that each promise is kept when the protocol is scored on patients that
had no part in choosing it. Scoring set fixed at 100 000; 300 replicates per row.*

Enrolling more patients does not require the rule to select the right criteria —
relaxing almost any criterion admits more people — so that promise survives a mostly
wrong selection. Improving the effect estimate does require it, and so has a
threshold. Confounded assignment that is *correctly adjusted for* raises the requirement by a
factor that depends on the reliability asked for: the randomised arm reaches 0.80 at
3000 fitting patients and the adjusted arm at about 5167, a factor of about 1.7, while
the randomised arm's 0.937 at 5167 is not reached by the adjusted arm anywhere in the
simulated range. Confounded assignment with a confounder left **unmeasured** returns
the curve to randomised levels (0.936 against 0.937 at 5167) while inflating the
estimand being detected by 8.6% and cutting correct selection from 0.280 to 0.116, so
apparent success on real-world data is not evidence that adjustment was adequate.

## Install

```r
# install.packages("remotes")
remotes::install_github("USER/trialplate")
```

## Use

```r
library(trialplate)

prep <- tp_prepare(colon_data(), colon_criteria, "trt", "time", "status",
                   colon_ps, tau = 1825)

## Before reading any interaction, ask whether one could exist.
## Leverage needs no outcome data at all.
L <- tp_leverage(prep)
max(L[upper.tri(L)])            # 0.086 — no pair can show an interaction here

## Does one criterion imply another? Then its interaction cell is arithmetic.
tp_implications(prep)$pairs     # NULL for this criteria set

## Test the published selection rule out of sample.
M <- tp_rule_eval(prep, R = 500, cores = 2)
g <- function(k) M[, grep(k, colnames(M), fixed = TRUE)[1]]
c(more_patients = mean(g("n_hr")  - g("n_full")  > 0),   # 0.982
  lower_hazard  = mean(g("hr_hr") - g("hr_full") < 0))   # 0.270
```

Both benefit estimands are carried throughout — the log hazard ratio and the
difference in restricted mean survival time — because the hazard ratio is
non-collapsible: restricting a cohort moves it even when every stratum's treatment
effect is identical.

## What is here

```
R/            the package: estimation kernels, Shapley engine, inference, plots
man/          23 .Rd files, generated from the actual signatures
tests/        16 correctness assertions
vignettes/    a worked example
analysis/     the scripts behind the paper — not part of the package
figures/      the figures those scripts produce
manuscript/   the manuscript and the docx-js script that builds it
              (refs.js holds the reference list; the build fails if any listed
              reference is never cited in the text)
explainer/    a three-page plain-language account, in Chinese
response/     point-by-point response to the reviewer, and the supplement
```

### Reproducing the analyses

Every script runs on `survival::colon` and `survival::rotterdam`. No data
application, no licence, no institutional access. Run them from the repository root:

```sh
Rscript analysis/run_colon.R       # fit, bootstrap, jackknife, permutation test
Rscript analysis/rule_eval.R       # out-of-sample test of the published rule
Rscript analysis/sim_trainsize.R   # the training-size threshold curve
Rscript analysis/sim_confound.R    # the three confounding arms
Rscript analysis/sim_coverage.R    # BCa interval coverage against known truth
```

`analysis/_setup.R` loads the installed package if present and otherwise sources
`R/` directly, so the scripts work before installation. Outputs land in
`analysis/out/`, which is gitignored.

## Why it is fast enough

The 2^p enumeration is evaluated once per bootstrap replicate, so per-subset cost
governs what is feasible. The model is always one binary covariate with weights, so
the weighted Cox partial likelihood is solved by Newton–Raphson directly and the
weighted restricted mean is computed from the Kaplan–Meier estimator directly,
skipping formula parsing and model-frame construction. The full cohort is sorted by
time once, so logical subsetting preserves the ordering and no subset is ever
re-sorted.

| kernel | `survival` / `stats` | here | agreement |
|---|---|---|---|
| weighted Cox, one binary covariate | 4.194 ms | **0.230 ms** | 9.4 × 10⁻¹³ |
| weighted RMST | 0.490 ms | **0.083 ms** | exact |
| propensity IRLS | 1.273 ms | 0.937 ms | 1.8 × 10⁻⁸ |
| full enumeration, both estimands | 12.8 s | **1.55 s** | efficiency axiom exact |

## Two diagnostics that need no outcome data

**Interaction leverage.** For the structure in which extra benefit accrues only to
patients meeting *both* criteria, the four-point difference driving the Shapley
interaction is proportional to

```
L(i,j) = 1 − p(ij)/p(i) − p(ij)/p(j) + p(ij)
```

computable from eligibility rates alone. It collapses as criteria become permissive:
two independent criteria each retaining 85% of a cohort have leverage 0.0225, against
0.3025 for two retaining 45%. Real protocol criteria are permissive, so a pairwise
interaction analysis on them is heavily attenuated — and you can know that before you
start. The attenuation is by a *known factor*, not a structural invisibility: the
signal still depends on the effect size and the sample size, and a large enough study
can recover it. The one case that is uninformative at any sample size is a logical
implication between two criteria, where the interaction is an arithmetic identity.
**A null interaction is therefore not evidence that no effect modification exists.**

**Logical implication.** If criterion *i* implies criterion *j*, then
v(S ∪ {i,j}) = v(S ∪ {i}) for every S, so the pair's interaction cell is an
arithmetic identity rather than evidence. `tp_implications()` finds these; they are
excluded from the test family and hatched in the plot.

## Status and caveats

- The eligibility criteria in `colon_criteria` and `rott_criteria` are plausible sets
  built from the available covariates for methodological illustration. **They are not
  the trials' protocol text.**
- The selection rule is implemented from the published description. If you have
  access to the original implementation, check it against `tp_rule_eval()` before
  relying on the comparison.
- The leverage expression is derived for the "both criteria required" structure.
  Other interaction forms have different coefficients.
- Interval coverage of the bias-corrected and accelerated bootstrap was checked
  against known truth over 420 replicates: 0.950 for a null interaction, 0.933 for a
  planted one (Monte Carlo standard errors 0.011 and 0.012). Treat intervals for
  large interactions as mildly anticonservative. This applies to the BCa intervals on
  interactions and Shapley values only — the out-of-sample quantities carry
  patient-resampled *ranges*, which are not confidence intervals and whose coverage
  has not been evaluated at all; see the Methods of the manuscript.
- The observed-cohort point estimates the paper's claims rest on come from
  `analysis/primary.R` and are written to one result file that the manuscript reads at
  build time; the nested bootstrap supplies spread only, never a point estimate. Other
  tables come from their own scripts, named in each caption.
- `analysis/check_outer.R` verifies, from the stored result objects and the analysis
  sources alone, that no outer replicate failed or was discarded, that the first
  replicate of each nested run is the observed cohort rather than a resample, and the
  usable inner-split counts behind Supplementary Table S1g. It exits non-zero on
  failure and runs in under a second. `analysis/export_numbers.R` refuses to
  export if the Rotterdam endpoint, either horizon, or the agreement between the two
  estimates of a quantity is wrong, or if any analysis script pairs the relapse-free
  time with the death indicator. This guard exists because eleven scripts did exactly
  that in an earlier revision; see `analysis/README.md`.

## References

Liu R, Rizzo S, Whipple S, et al. Evaluating eligibility criteria of oncology trials
using real-world data and AI. *Nature* 2021;592:629–33.

Grabisch M, Roubens M. An axiomatic approach to the concept of interaction among
players in cooperative games. *Int J Game Theory* 1999;28:547–65.

Hernán MA. The hazards of hazard ratios. *Epidemiology* 2010;21:13–5.

Uno H, Claggett B, Tian L, et al. Moving beyond the hazard ratio in quantifying the
between-group difference in survival analysis. *J Clin Oncol* 2014;32:2380–5.

Ren Y, Wang Z, Lin L, Zhao S, Chu H. A novel visualization approach for network
meta-analysis: the plate plot and the nmaplateplot R package.
*Res Synth Methods* 2026;17:1045–53.

## Licence

MIT.
