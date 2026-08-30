module.exports = function (M) {
const {add, P, H1, H2, R, table} = M;

add(H1("Results"));

add(H2("One promise held, the other did not"));
add(P("Table 1 gives the out-of-sample comparison in both cohorts. The eligibility promise held decisively: the data-driven protocol admitted 59 more patients in colon and 229 more in Rotterdam, and did so in 98.2% and 100% of splits. The effect-estimate promise did not hold in either cohort. In colon the out-of-sample hazard ratio was 0.078 higher under the data-driven protocol, and lower in only 27.0% of splits; in Rotterdam the difference was 0.001 and the probability 0.497, an exact coin flip. The restricted mean survival difference was essentially unchanged in both (−5.8 and +6.9 days). Raising the fitting fraction from 0.5 to 0.7 moved the colon probability from 0.270 to 0.336 and the Rotterdam probability from 0.497 to 0.527, in the expected direction but not to the point of keeping the promise."));
add(table(
  ["", "colon (n = 619)", "Rotterdam (n = 2982)"],
  [["Fitting-set size (fraction 0.5)", "309", "1491"],
   ["Splits", "500", "400"],
   ["Original protocol, out of sample", "n = 88, HR = 0.592, RMST = +75.8 d", "n = 210, HR = 0.740, RMST = +143.9 d"],
   ["Data-driven protocol, out of sample", "n = 148, HR = 0.670, RMST = +70.0 d", "n = 440, HR = 0.742, RMST = +150.8 d"],
   ["Eligible patients, difference", "+59 (SE 2)", "+229 (SE 6)"],
   ["P(more patients)", "0.982", "1.000"],
   ["Hazard ratio, difference", "+0.0781 (SE 0.0058)", "+0.0012 (SE 0.0069)"],
   ["P(lower hazard ratio)", "0.270", "0.497"],
   ["RMST difference, difference", "−5.8 d", "+6.9 d"],
   ["P(greater absolute benefit)", "0.452", "0.580"]],
  [3400, 2980, 2980],
  "Table 1. Out-of-sample comparison of the data-driven protocol against the original full protocol. The rule was fitted on one random half and both protocols scored on the other. SE is the standard error of the mean difference across splits."));

add(H2("The threshold is in the fitting cohort, not in the rule"));
add(P("Table 2 shows the simulated curve with the scoring set fixed at 100 000 patients, so the horizontal axis is fitting size alone. The eligibility promise was kept at every size, from 0.950 at 300 fitting patients to 1.000 at 20 000. The effect-estimate promise rose from 0.273 to 0.997 across the same range, crossing 0.8 at about 3000 patients and reaching 0.937 at 5167 — the average per-trial size in the original work. At the population level the rule was correct: it identified the diluting criterion, and the protocol it produced lowered the hazard ratio from 0.6637 to 0.6327 while raising the eligible count from 55 179 to 78 847."));
add(P("The two observed cohorts fall on this curve. Colon, with 309 fitting patients, was predicted at 0.279 and observed at 0.270. At the 0.7 fitting fraction, with 433 patients, the curve predicts 0.339 and the observed value was 0.336 — a split the curve had not been fitted to. Rotterdam sat consistently below the curve (0.497 and 0.527 against predictions of 0.603 and 0.698), which the confounding arms explain."));
add(table(
  ["Fitting patients", "P(more patients)", "P(lower HR)", "P(exact criterion set recovered)"],
  [["300", "0.950", "0.273", "0.033"],
   ["1000", "0.943", "0.490", "0.073"],
   ["3000", "0.973", "0.800", "0.147"],
   ["5167", "0.990", "0.937", "0.280"],
   ["20 000", "1.000", "0.997", "0.637"]],
  [2760, 2200, 2200, 2200],
  "Table 2. Simulated probability that each promise is kept, by fitting-cohort size, with the scoring set fixed at 100 000 patients. 300 replicates per row. 5167 is the average per-trial cohort size in the original work."));

add(H2("Why the promises diverge"));
add(P("The rightmost column of Table 2 explains the divergence. The rule recovered the exactly correct criterion set in 3.3% of replicates at 300 fitting patients and in only 28.0% at 5167. Enrolling more patients does not require the selection to be correct — relaxing almost any criterion admits more people — so that promise survives a mostly wrong selection. Improving the effect estimate does require it, and so tracks the recovery probability."));

add(H2("Confounding moves the threshold, and hides itself"));
add(P("Table 3 gives the three arms. Confounded assignment that was correctly adjusted for lowered the curve throughout: at 5167 fitting patients the probability fell from 0.937 to 0.808, and roughly twice the sample was needed to reach a given reliability. This is consistent with Rotterdam sitting below the randomised curve."));
add(P("The third arm is the more consequential result. When one confounder was omitted from the propensity model the curve returned to randomised levels — 0.936 at 5167 patients against 0.937 under randomisation. This looks like reassurance and is the opposite. The population quantity the rule was detecting had itself been inflated: the true gap between the full and rule protocols was 0.0408 in arm C against 0.0310 under randomisation, 32% larger, and the whole hazard ratio was displaced upward from 0.664 to 0.757. The procedure appeared more reliable because part of what it was detecting was bias rather than benefit."));
add(P("The practical implication is uncomfortable and should be stated plainly. On real-world data, the observation that the method works well is not evidence that adjustment was adequate; incomplete adjustment makes it work better. A defensible sensitivity analysis compares the estimated gap under richer and poorer adjustment and expects it to shrink as adjustment improves. A gap that grows as covariates are added is a warning."));
add(table(
  ["Fitting patients", "A: randomised", "B: confounded, adjusted", "C: confounded, one unmeasured"],
  [["1000", "0.490", "0.408", "0.588"],
   ["3000", "0.800", "0.660", "0.852"],
   ["5167", "0.937", "0.808", "0.936"],
   ["20 000", "0.997", "0.956", "0.988"],
   ["True population gap in HR", "0.0310", "0.0327", "0.0408"],
   ["Hazard ratio, full protocol", "0.6637", "0.6600", "0.7569"]],
  [2760, 2200, 2200, 2200],
  "Table 3. Probability of a lower out-of-sample hazard ratio under three treatment-assignment mechanisms sharing one outcome model. 250 replicates per cell. The last two rows are population quantities computed at N = 300 000."));

add(H2("Non-collapsibility"));
add(P("Under a proportional-hazards model with the conditional hazard ratio fixed at 0.6 in every stratum, a criterion defined on the prognostic covariate changes no individual's relative benefit, yet the Shapley value of that criterion on the log hazard ratio was non-zero and grew monotonically with prognostic strength, from −0.0008 when there was no heterogeneity to −0.066 at the strongest setting; the marginal hazard ratio drifted from 0.599 to 0.804 over the same range. The value at zero heterogeneity is the falsification point and the artefact vanished there as required. The restricted mean survival difference also changed across the sweep, but for a legitimate reason: the selected lower-risk group genuinely has less absolute survival to gain. The hazard-ratio movement corresponds to no such fact, which is why it is the fragile leg of the procedure."));

add(H2("Interaction leverage"));
add(P("In colon the interaction leverage had median 0.012 and maximum 0.086, and no pair of the 36 exceeded 0.10; in Rotterdam the median was 0.021 and three pairs exceeded 0.10. Real protocol criteria are permissive by design, and permissiveness drives the leverage to zero. A pairwise interaction analysis on such criteria is therefore structurally uninformative, independently of sample size — and this is known before any outcome is examined. In a simulation with a planted interaction the first-order prediction from the leverage was −0.180 against a realised value of −0.164, an error of 9%. Consistently, a global permutation test on the colon interaction matrix returned p = 0.26 on the hazard ratio and 0.21 on the restricted mean, and no main effect on either estimand survived multiplicity adjustment."));

add(H2("Interval coverage"));
add(P("Against known truth at n = 1500 with 200 bootstrap and 25 jackknife groups, the bias-corrected and accelerated interval attained 0.942 coverage (SE 0.021) for a null interaction, indistinguishable from the nominal 0.95, while the plain percentile interval over-covered at 0.967. Since most cells of a real interaction matrix are null and it is their false-positive behaviour that determines what gets reported, this is the comparison that matters and the accelerated interval is the better calibrated. Both under-covered a genuinely non-null interaction, at 0.908 and 0.917 respectively. We therefore recommend at least 1000 bootstrap replicates and 50 jackknife groups in application, and suggest treating intervals for large interactions as mildly anticonservative. The median interval width was 0.351, of the same order as the largest interaction observed in either cohort, which is a further reminder that this quantity is not well determined at accessible sample sizes."));

/* ---------------- discussion ---------------- */
add(H1("Discussion"));
add(P("Data-driven relaxation of eligibility criteria works, and the case for it is inclusiveness. In both public cohorts and at every simulated fitting size the procedure admitted substantially more patients, and it did so without requiring the criterion selection to be correct. That is a real and robust benefit, and on its own a sufficient argument for the approach."));
add(P("The accompanying claim of an improved effect estimate is more delicate. It is not wrong — at the population level the rule does lower the hazard ratio, and at the fitting sizes used in the original work it does so out of sample with probability 0.937 under randomisation. But it has a threshold, at roughly 3000 fitting patients under randomisation and about twice that under confounding, and below the threshold what is reported is in-sample selection. Public individual-level cohorts, and many single-institution electronic health record cohorts, fall below it. Investigators reusing this framework should check where their cohort sits before relying on the effect-estimate claim, and we provide the curve for that purpose."));
add(P("The finding we would most want carried forward is the behaviour of the unmeasured-confounding arm. Residual confounding inflated the quantity the procedure was detecting and thereby made the procedure appear more reliable. This inverts the usual intuition that a clear signal is reassuring. In a real-world data setting where adjustment is never known to be complete, an impressive result should prompt a sensitivity analysis over adjustment sets rather than confidence, and the direction of travel matters: the estimated gap should shrink, not grow, as adjustment improves."));
add(P("Three by-products may be useful independently. The interaction leverage is a closed-form quantity requiring no outcome data that says whether a criterion pair can exhibit an interaction at all; on both real criteria sets the answer was essentially no, which converts a null result from a power problem into a structural one that can be anticipated. The implication detector removes cells that are arithmetic identities rather than evidence, a trap that is easy to fall into because criteria such as a nodal count bound and a nodal status requirement look independent but are not. And carrying both benefit estimands rather than one makes visible where a criterion's relative and absolute effects disagree, which is a substantive question that should be decided on clinical grounds rather than by the choice of software default."));
add(P("Several limitations bound these conclusions. The criteria sets were constructed from available covariates rather than transcribed from the trials' protocols, so this is a demonstration of a general property of the procedure and not an evaluation of any particular trial's criteria. Neither cohort is the advanced non-small-cell lung cancer real-world database used in the original work, and the treatments in colon are no longer in use; the cohorts are a methodological bench, chosen because they are fully public and every number here can be recomputed by a reader. The threshold curve is derived from one generating model and its numerical values will depend on the strength of effect modification present; it is the existence and approximate location of a threshold, and its shift under confounding, that we intend to be general. Sample splitting halves the fitting set, which is why we also report a 0.7 fitting fraction and calibrate against simulation rather than relying on the split result alone. Finally, the leverage expression is derived for the specific structure in which extra benefit accrues only to patients meeting both criteria; other interaction structures will have different coefficients, though the qualitative conclusion that permissive criteria carry little leverage is not specific to that form."));

add(H1("Conclusions"));
add(P("Relaxing trial eligibility criteria from data reliably widens the eligible population, and that alone justifies the approach. The improvement in the treatment-effect estimate reported alongside it requires a fitting cohort of roughly 3000 patients under randomisation and about twice that under confounded assignment; below that threshold it does not survive out-of-sample validation. Incomplete confounding adjustment makes the procedure appear more successful rather than less, so apparent success on real-world data is not evidence of adequate adjustment. Two diagnostics computable before any outcome is examined — interaction leverage and logical implication — and the threshold curve reported here allow an investigator to establish in advance what their cohort can and cannot support."));

/* ---------------- declarations ---------------- */
add(H1("Declarations"));
add(P([R("Ethics approval and consent to participate. ", {b:true}), R("Not applicable; both datasets are publicly distributed and de-identified. [Confirm local requirements.]")], {after: 90}));
add(P([R("Consent for publication. ", {b:true}), R("Not applicable.")], {after: 90}));
add(P([R("Availability of data and materials. ", {b:true}), R("Both cohorts are distributed with the R package survival (datasets colon and rotterdam). All analysis code, including the R package trialplate and every script reproducing the figures and tables, is available at [repository URL] and archived at [DOI].")], {after: 90}));
add(P([R("Competing interests. ", {b:true}), R("[To be completed.]")], {after: 90}));
add(P([R("Funding. ", {b:true}), R("[To be completed.]")], {after: 90}));
add(P([R("Authors' contributions. ", {b:true}), R("[To be completed.]")], {after: 90}));
add(P([R("Acknowledgements. ", {b:true}), R("[To be completed.]")], {after: 200}));

/* ---------------- references ---------------- */
add(H1("References"));
const refs = [
"Liu R, Rizzo S, Whipple S, Pal N, Pineda AL, Lu M, Arnieri B, Lu Y, Capra W, Copping R, Zou J. Evaluating eligibility criteria of oncology trials using real-world data and AI. Nature. 2021;592:629–33.",
"Shapley LS. A value for n-person games. In: Kuhn HW, Tucker AW, editors. Contributions to the Theory of Games II. Princeton: Princeton University Press; 1953. p. 307–17.",
"Grabisch M, Roubens M. An axiomatic approach to the concept of interaction among players in cooperative games. Int J Game Theory. 1999;28:547–65.",
"Hernán MA. The hazards of hazard ratios. Epidemiology. 2010;21:13–5.",
"Uno H, Claggett B, Tian L, Inoue E, Gallo P, Miyata T, Schrag D, Takeuchi M, Uyama Y, Zhao L, Skali H, Solomon S, Jacobus S, Hughes M, Packer M, Wei LJ. Moving beyond the hazard ratio in quantifying the between-group difference in survival analysis. J Clin Oncol. 2014;32:2380–5.",
"Benjamini Y, Hochberg Y. Controlling the false discovery rate: a practical and powerful approach to multiple testing. J R Stat Soc B. 1995;57:289–300.",
"Efron B. Better bootstrap confidence intervals. J Am Stat Assoc. 1987;82:171–85.",
"Moertel CG, Fleming TR, Macdonald JS, Haller DG, Laurie JA, Goodman PJ, Ungerleider JS, Emerson WA, Tormey DC, Glick JH, Veeder MH, Mailliard JA. Levamisole and fluorouracil for adjuvant therapy of resected colon carcinoma. N Engl J Med. 1990;322:352–8.",
"Royston P, Altman DG. External validation of a Cox prognostic model: principles and methods. BMC Med Res Methodol. 2013;13:33.",
"Ren Y, Wang Z, Lin L, Zhao S, Chu H. A novel visualization approach for network meta-analysis: the plate plot and the nmaplateplot R package. Res Synth Methods. 2026;17:1045–53.",
"Therneau TM, Grambsch PM. Modeling Survival Data: Extending the Cox Model. New York: Springer; 2000.",
"[Add: the scoping review of eligibility-criteria target trial emulation, and the three Trial Pathfinder follow-ups in lung cancer, asthma/COPD and multiple myeloma — verify citations before submission.]",
];
refs.forEach((r, i) => add(P([R((i+1) + ". "), R(r)], {size: 20, after: 80})));

/* ---------------- figure legends ---------------- */
add(P("", {after: 200}));
add(H1("Figure legends"));
add(P([R("Figure 1. ", {b:true}), R("Probability that each promise is kept, by fitting-cohort size, with the scoring set fixed at 100 000 patients. The eligibility promise (green) is kept at every size; the effect-estimate promise (red) has a threshold near 3000 patients. Diamonds mark the randomised cohort observed at two fitting fractions, which fall on the simulated curve; triangles mark the observational cohort, which sits below it. The right panel shows the probability that the rule recovers the exactly correct criterion set, which is why the two promises behave differently.")]));
add(P([R("Figure 2. ", {b:true}), R("Three treatment-assignment mechanisms sharing one outcome model. Left: correctly adjusted confounding lowers the curve throughout, so a given reliability needs about twice the sample. Unmeasured confounding returns it to randomised levels. Right: the reason — the true population gap the procedure is detecting is 32% larger under unmeasured confounding, and the hazard ratio itself is displaced upward.")]));
add(P([R("Figure 3. ", {b:true}), R("Out-of-sample comparison of the data-driven protocol against the original full protocol in both cohorts. Open circles are the original protocol, filled circles the data-driven one, both scored on patients that had no part in the selection. Annotations give the probability that each promise is kept across splits.")]));
add(P([R("Figure 4. ", {b:true}), R("Non-collapsibility as a dose–response. The conditional hazard ratio is 0.6 in every stratum at every point on the curve, so the criterion changes no individual's relative benefit; the Shapley value on the log hazard ratio nonetheless grows with prognostic strength and vanishes, as it must, when there is no heterogeneity to collapse over.")]));
add(P([R("Figure 5. ", {b:true}), R("The criteria plate plot for the colon cohort. Upper triangle, pairwise interaction on the log hazard ratio; lower triangle, on the restricted mean survival difference; diagonal, per-criterion main effects on both estimands with background shading by the fraction of the cohort the criterion excludes. Light hatching marks cells whose interaction leverage is below 0.05 — 35 of 36 here — and dense hatching cells that are arithmetic identities.")]));
};
