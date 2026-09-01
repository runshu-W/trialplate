const d = require('docx');
const {Document, Packer, Paragraph, TextRun, AlignmentType, HeadingLevel} = d;
const fs = require('fs');
const NUM = JSON.parse(fs.readFileSync("/home/claude/repo/analysis/out/numbers.json","utf8"));
/* This letter reported quantities from result objects that were retired in the fifth
 * revision (see analysis/out/superseded/README.md): the split-dependence, Pareto
 * benchmark and random-benchmark objects. The letter is a historical record of what
 * was said at the time, so the values it quoted are preserved here as literals,
 * transcribed from the letter as it was built on 30 August, rather than re-read from
 * result files that no longer hold them. Nothing here feeds the manuscript or the
 * supplement; those read only the live objects in numbers.json. */
if (!NUM.dependence) NUM.dependence = {
  colon: {ci_lower:[0.00,0.72], B:70, R_IN:18,
          se_lower:0.184, mc_lower:0.105, between_lower:0.151, ratio_between_lower:14},
  rott:  {ci_lower:[0.15,0.81]}
};
if (!NUM.pareto) NUM.pareto = {
  colon: {n_match:123, rank_hr:[0.598,0.568,0.628], rank_rm:[0.427],
          front_hr:[0.016], n_dom:72},
  rott:  {n_match:66,  rank_hr:[0.548], rank_rm:[0.515],
          front_hr:[0.030], n_dom:60}
};
if (!NUM.random_ci) NUM.random_ci = {
  colon: {hr:[0.576,0.545,0.607]},
  rott:  {hr:[0.686,0.660,0.714]}
};
const FA=NUM.factorial, DP=NUM.dependence, PA=NUM.pareto, CN=NUM.concentration,
      FX=(NUM.fixedn||{}), RCI=NUM.random_ci;
const f=(x,k=3)=>(x===null||x===undefined)?"—":Number(x).toFixed(k);
const f0=x=>f(x,0); const pct=(x,k=1)=>(100*Number(x)).toFixed(k)+"%";

const body=[]; const add=(...x)=>x.forEach(e=>Array.isArray(e)?body.push(...e):body.push(e));
const P=(t,o={})=>new Paragraph({spacing:{after:o.after??130,line:290},
  alignment:AlignmentType.JUSTIFIED,
  children:[new TextRun({text:t,size:o.size??21,font:"Calibri",italics:o.i,bold:o.b,color:o.color})]});
const H1=t=>new Paragraph({heading:HeadingLevel.HEADING_1,spacing:{before:300,after:140},
  children:[new TextRun({text:t,font:"Calibri"})]});
const Q=t=>new Paragraph({spacing:{before:230,after:90},indent:{left:340},
  border:{left:{style:d.BorderStyle.SINGLE,size:12,color:"9DB2C6",space:12}},
  children:[new TextRun({text:t,size:20,font:"Calibri",italics:true,color:"3A4A5C"})]});
const W=t=>P(t,{size:19,color:"55606B",after:190});

add(new Paragraph({spacing:{after:60},children:[new TextRun({
  text:"Response to the second review",bold:true,size:30,font:"Calibri"})]}));
add(P("Manuscript: What data-driven relaxation of trial eligibility criteria can and cannot promise: an out-of-sample evaluation, and why reliability was not determined by cohort size alone across the mechanisms examined",{size:20,color:"555555",after:250}));
add(P("This review found a leakage bug in our resampling, a selection-biased summary that we had built a headline on, an unfair benchmark, and a sentence about restricted mean survival that was simply backwards. Acting on the second and third has changed the paper's central claim, and the new claim is a negative one. The title has changed to match. We are grateful for the care this took.",{after:250}));

add(H1("Major comments"));

add(Q("1. Outer bootstrap may leak between fitting and scoring sets."));
add(P("Correct, and it was a bug. The previous script bootstrapped the cohort and then split the resampled ROWS, so two copies of one patient could indeed land on opposite sides. Every row now carries the identifier of the patient it was drawn from, the inner split is taken over unique identifiers, all copies follow their identifier to one side, and an assertion in the loop fails if the two halves ever share an identifier. The analysis has been rerun."));
add(P("The correction moved the numbers in the opposite direction from the reviewer's expectation: it narrowed the intervals rather than widening them. The colon 95% interval for the probability of a lower out-of-sample hazard ratio was [0.00, 0.91] and is now [" + f(DP.colon.ci_lower[0],2) + ", " + f(DP.colon.ci_lower[1],2) + "]; Rotterdam is now [" + f(DP.rott.ci_lower[0],2) + ", " + f(DP.rott.ci_lower[1],2) + "]. The qualitative conclusion is unchanged."));
add(P("On the specifics asked for: " + DP.colon.B + " outer resamples and " + DP.colon.R_IN + " inner splits per resample. The across-resample variance contains both the inner Monte Carlo term and the genuine between-cohort term, so we subtract the first to report the second: for colon the total standard deviation is " + f(DP.colon.se_lower,3) + ", of which " + f(DP.colon.mc_lower,3) + " is Monte Carlo and " + f(DP.colon.between_lower,3) + " is between-cohort. The between-cohort component alone is " + f(DP.colon.ratio_between_lower,0) + " times the naive across-split standard error, which is the comparison we now report. Intervals are percentile intervals of the outer distribution; we do not use accelerated intervals here because the statistic is a proportion of proportions and the acceleration estimate is unstable at this outer count. All of this is now stated in the Methods."));
W("Where: Methods, out-of-sample evaluation; Results §2; analysis/split_dependence.R.");

add(Q("2. The same-number-of-criteria benchmark is not fair."));
add(P("Accepted. Matching on the number of criteria removed is not matching on inclusiveness, and with 442 patients against 664 the hazard ratios were being compared at different eligible counts. We have replaced the benchmark with the analysis the reviewer proposes."));
add(P("Every one of the 512 subsets is now scored on the held-out half of each split, so the attainable set is known rather than sampled. Matched to within ten per cent on eligible count (median " + f0(PA.colon.n_match) + " comparators per split in colon, " + f0(PA.rott.n_match) + " in Rotterdam), the rule reaches a lower log hazard ratio than a matched subset in " + pct(PA.colon.rank_hr[0]) + " of colon comparisons (" + pct(PA.colon.rank_hr[1]) + " to " + pct(PA.colon.rank_hr[2]) + ") and " + pct(PA.rott.rank_hr[0]) + " in Rotterdam. On the restricted mean difference it is at or below chance, " + pct(PA.colon.rank_rm[0]) + " and " + pct(PA.rott.rank_rm[0]) + "."));
add(P("The dominance analysis is the more informative one and is less flattering than our previous framing. The rule's choice lay on the eligible-count-versus-hazard-ratio frontier in " + pct(PA.colon.front_hr[0]) + " of colon splits and " + pct(PA.rott.front_hr[0]) + " of Rotterdam splits, with a median of " + f0(PA.colon.n_dom) + " and " + f0(PA.rott.n_dom) + " subsets dominating it. So the reviewer's reading is right: the earlier statement conflated a genuine advantage with a smaller expansion, and what we can now say is that at equal inclusiveness the hazard-ratio advantage is real but modest, absent on the absolute-benefit estimand, and that the rule is usually well inside the attainable frontier. The same-size comparison is retained with intervals, labelled as such."));
add(P("We have not defined a joint utility over enrolment and treatment contrast. Doing so would require weights we cannot justify from these data, and we prefer to report the frontier and let a reader supply their own."));
W("Where: Results §1; Discussion ¶1; Table S3; analysis/pareto_benchmark.R.");

add(Q("3. The factorial threshold analysis does not handle censoring."));
add(P("Accepted, and this one invalidated a headline. Computing coefficients of variation over the six scenarios in which a threshold was observable conditions on the outcome, and the conclusion we drew from it — that events and effective sample size travel worse than patients — does not survive a proper analysis. We withdraw it explicitly in the text rather than quietly dropping it."));
add(P("The primary analysis is now the success probability at fixed fitting sizes, which every scenario supplies whether or not it has an attainable threshold and which requires no threshold estimation. Repeating the currency comparison without conditioning — binning all sixteen scenarios by each currency and measuring the within-bin spread of the success probability — gives " + f(FX.spread_patients,2) + " for patients, " + f(FX.spread_events,2) + " for full-protocol events and " + f(FX.spread_ess,2) + " for effective sample size. They are indistinguishable. None is more portable, and none is less."));
add(P("We have also fitted the interval-censored regression the reviewer suggests, with right-censored runs contributing (18 000, infinity) and the left-censored run (0, 600). It cannot carry weight: the effect-modification factor completely separates the design, so its coefficient is unbounded and not estimable, and the other terms are estimated from six exact observations with intervals spanning one to two orders of magnitude. We report it in the supplement as supporting material and say why it cannot do more."));
add(P("The phrase “no realistic sample size is sufficient” is gone. What we now write is that at 18 000 fitting patients the median success probability in the diffuse scenarios was 0.27, which is what we observed."));
W("Where: Results §3; Table 2; Table S2b; analysis/factorial_reanalysis.R.");

add(Q("4. Concentration of effect modification is not checkable in advance."));
add(P("This is the most useful comment in the review and we have restructured the paper around it. The reviewer is right on both halves."));
add(P("On the second half first, because running it changed what we believe. We built a sweep holding the total effect modification fixed and varying only its arrangement, and it showed that our factorial had confounded two things. There the per-criterion coefficient was simply divided, so the diffuse arm also had a weaker DILUTING coefficient — 0.128 against 0.32 — and dilution is the signal the rule must detect, since relaxation lowers the hazard ratio only by dropping a criterion selecting patients who benefit less."));
if (CN && CN.A_dil1_enr1) {
  const g = k => CN[k].rows.map(r=>f(r.p_lower,2)).join(" / ");
  add(P("Separating them: with the diluting coefficient fixed at 0.30, success at 600, 2000, 6000 and 18 000 fitting patients runs " + g("A_dil1_enr1") + " with the enrichment in one criterion, " + g("B_dil1_enr2") + " over two and " + g("C_dil1_enr4") + " over four. Spreading the enrichment costs nothing. Splitting the DILUTION across two criteria, same total, gives " + g("D_dil2_enr1") + ". So the governing quantity is the magnitude of the largest diluting coefficient, not concentration, and the reviewer's suspicion that the original contrast was partly mechanical was justified."));
}
add(P("On the first half: that quantity is exactly what the analysis exists to discover, so it cannot be checked beforehand. We have therefore reframed the paper as the reviewer suggests. The title now ends “and why the data requirement cannot be stated in advance”; the abstract and conclusions state the negative result; and the Discussion separates explicitly what is checkable before any outcome is examined — empirical overlap inside the full protocol, logical implication, interaction leverage — from what is not. We agree this is more valuable than a threshold we could not defend."));
W("Where: title, abstract, Results §3, Discussion ¶3, Conclusions; Table S4; analysis/concentration_sweep.R.");

add(Q("5. Regret is insufficiently defined and over-interpreted."));
add(P("Accepted. Regret is now defined in the text where it is used: the difference between the population log hazard ratio under the selected protocol and under the subset minimising it, both evaluated on the fixed 100 000-patient scoring set. It is on the log hazard-ratio scale, it is single-objective, and it ignores eligible count, safety and every other clinical consideration."));
add(P("The interpretation is correspondingly narrowed. Because different protocols target different populations, a larger regret means further from the lowest attainable hazard ratio and not worse for a patient, and we no longer write that the protocol is worse without that qualification. The abstract and conclusions have been changed to match."));
add(P("On the second point: the claim that the population-limit set coincides with the best attainable set is now explicitly a property of this generating model. The reviewer is right that the Shapley-sign rule carries no general guarantee of finding the global optimum in the presence of interactions, and we say so."));
W("Where: Results §4; Abstract; Conclusions.");

add(Q("6. Figure 3 overstates the empirical–simulation agreement."));
add(P("Accepted. The observed cohort points now carry their outer-bootstrap intervals, which span most of the unit interval and dominate the panel visually, and both the caption and the text say that the agreement has almost no power to discriminate and that we draw no validation from it. The panel title no longer describes the threshold as a general property."));
add(P("The random-relaxation percentages now carry bootstrap intervals throughout — colon " + pct(RCI.colon.hr[0]) + " (" + pct(RCI.colon.hr[1]) + " to " + pct(RCI.colon.hr[2]) + "), Rotterdam " + pct(RCI.rott.hr[0]) + " (" + pct(RCI.rott.hr[1]) + " to " + pct(RCI.rott.hr[2]) + ") — with a note that they are computed across splits and so are narrower than the population uncertainty. The reviewer is right that the colon figure represents a small advantage, and the text says so."));
W("Where: Figure 3 and caption; Results §1 and §3.");

add(Q("7. Positivity terminology, and weighting a randomised trial."));
add(P("Accepted on both. We now write “a severe lack of empirical overlap — a practical positivity violation”, and note that a finite sample cannot establish that the theoretical assumption fails. Supplementary Figure S3 shows the propensity distributions by arm inside the full protocol, with the truncation bounds and common-support region marked; the trimmed target population is defined in Table S1b."));
add(P("On weighting the randomised cohort, the reviewer's concern is justified and we have quantified it. Comparing the estimated propensity model with the known randomisation probability and with no weighting at all: the full-protocol hazard ratio is 0.5823, 0.5940 and 0.5951, and the rule's is 0.5352, 0.5474 and 0.5478. The selected criterion set is the same except that estimating the propensity model retains one additional criterion of nine. So estimation noise does shift a marginal criterion, though it does not move the headline numbers. This is now reported."));
W("Where: Methods, cohorts and weighting; Figure S3; analysis/ph_and_weights.R.");

add(Q("8. Two remaining overstatements about interaction leverage."));
add(P("Both accepted. The text now reads that positive correlation raises the joint eligibility rate and that once it rises far enough the factor CAN become negative. And we no longer describe the coefficient uniformly as known: it is exact for the both-criteria structure, where simulation confirms it to within a few per cent, and an order-of-magnitude diagnostic for the other two forms, where it is over-predicted by 10 to 30 per cent because the derivation ignores reweighting. The Discussion uses the same distinction."));
W("Where: Methods, interaction leverage; Results §7; Discussion ¶6.");

add(Q("9. The restricted mean interpretation appears to have the direction wrong."));
add(P("It did, and thank you. The sentence claimed that the selected lower-risk group has more absolute survival to gain, which is both contrary to the usual logic and contradicted by our own numbers: in the sweep the restricted mean difference falls from 0.664 in the whole cohort to 0.599 in the selected group at the weakest setting and from 0.425 to 0.322 at the strongest, so the Shapley value is negative throughout, exactly as Figure 5 shows."));
add(P("The corrected text gives those numbers and states the direction properly: a lower-risk group has LESS absolute survival to gain, because more of it survives the horizon regardless of treatment. The point the passage was making is unaffected and is in fact cleaner — the restricted mean moves for a reason, in the expected direction, while the hazard ratio moves for no reason at all."));
W("Where: Results §6.");

add(H1("Minor comments"));
add(P("Abstract. “To our knowledge” added, matching the Background."));
add(P("0.80 target. Sensitivity at 0.70 and 0.90 is now reported: the median located threshold is 2000 and 4811 fitting patients, and the separation by effect-modification arrangement is unchanged at every target (Table S2b)."));
add(P("Coverage replicates. Our previous response said these had been increased and they had not been; we apologise. They have now been rerun at 420 replicates, and the replicate count is stated in the text alongside the Monte Carlo error, for the non-null interaction as well as the null one."));
add(P("Proportional hazards. Now tested. The Grambsch–Therneau test on the treatment term gives p = 0.28 in the whole colon cohort and 0.31 in its full protocol, and 0.95 and 0.65 in Rotterdam, so there is no evidence against proportionality in either. We also state what the Cox coefficient would summarise if it failed, and note that the restricted mean difference carried alongside it is the estimand with an unambiguous reading in that case."));
add(P("Table 1 units. The stray line break is fixed; the column now reads “days” and the widths are rebalanced."));
add(P("Figure sizes. Figures 1 and 6 are enlarged in the main text and both are also supplied full-page in the supplement."));
add(P("Axis scaling. The horizontal axes of Figures 3 and 4 are logarithmic and are now labelled “(log scale)”."));
add(P("References, declarations and supplement. All three are now present. The manuscript carries a numbered reference list of 22 sources, every one of them cited in the text and verified against the publisher record or the issuing agency rather than reconstructed; the build fails if a listed reference is never cited. The Declarations section covers ethics, consent, data availability, competing interests, funding and contributions, with the author-specific items marked for completion before submission. The supplement accompanies this response as a separate file containing Tables S1, S1b, S1c, S2, S2b, S3 and S4, Text S1 and Figures S1, S2 and S3. We regret that their absence made parts of the previous version unverifiable."));

add(new Paragraph({spacing:{before:300},children:[new TextRun({
  text:"Three of these comments changed results rather than wording: the leakage correction, the censoring reanalysis, and the sweep that separated concentration from the strength of the diluting signal. The last of these replaced our central claim with a weaker and, we think, more useful one — that the data requirement depends on a quantity the analysis is meant to estimate, and so cannot be given in advance.",
  size:21,font:"Calibri",italics:true})]}));

const doc=new Document({sections:[{properties:{page:{size:{width:12240,height:15840},
  margin:{top:1080,bottom:1080,left:1180,right:1180}}},children:body}]});
Packer.toBuffer(doc).then(b=>{fs.writeFileSync("response_to_reviewer_round2.docx",b);
  console.log("written",b.length,"bytes");});
