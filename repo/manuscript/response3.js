const d = require('docx');
const {Document, Packer, Paragraph, TextRun, AlignmentType, HeadingLevel} = d;
const fs = require('fs');
const NUM = JSON.parse(fs.readFileSync("/home/claude/repo/analysis/out/numbers.json","utf8"));
const NS=NUM.nested||{}, FO=NUM.frontier_opt||null, RR=NUM.rmst_rule||null,
      CN=NUM.concentration||{}, FX=NUM.fixedn||{}, SNR=NUM.snr||null, CW=NUM.colon_wt||null;
const f=(x,k=3)=>(x===null||x===undefined)?"—":Number(x).toFixed(k);
const f0=x=>f(x,0); const pct=(x,k=1)=>(x===null||x===undefined)?"—":(100*Number(x)).toFixed(k)+"%";

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
  text:"Response to the third review",bold:true,size:30,font:"Calibri"})]}));
add(P("Manuscript: What data-driven relaxation of trial eligibility criteria can and cannot promise: an out-of-sample evaluation, and why reliability was not determined by cohort size alone across the mechanisms examined",{size:20,color:"555555",after:250}));
add(P("The frontier comment is correct and we had not seen it: the frontier we built is an argmax over 512 noisy estimates and is optimistic. We have measured how optimistic in simulation and rewritten the section around the answer. The comment on conditional sample-size planning is also correct and has changed the title and the conclusions, which previously overreached. On two points — the pseudoreplication in the matched comparison and the variance subtraction — the code already did what the reviewer asks; the text did not say so, which is our fault, and both are now written out.",{after:250}));

add(H1("Major comments"));

/* ---- 1 ---- */
add(Q("1. The attainable frontier is an empirical frontier subject to winner's curse."));
add(P("Accepted, and this was the most consequential thing we missed. The rule never sees the scoring half, so the comparison is honest for the rule, but the frontier is selected from that same half and is therefore biased toward the extremes. Calling it the attainable frontier was wrong."));
if (FO) {
  add(P("We have quantified the optimism in simulation, where the population is known. With a held-out half the size of a colon scoring set, a median of " + f0(FO.dom_emp) + " subsets appear to dominate the rule where the population has " + f0(FO.dom_pop) + ", and the rule appears off the frontier in " + pct(1-FO.front_emp) + " of replicates against " + pct(1-FO.front_pop) + " judged at the population. Of the subsets that dominate on one held-out half, only " + pct(FO.repro) + " still dominate on an independent half and " + pct(FO.true_frac) + " genuinely dominate at the population. The reviewer's suspicion is confirmed at close to the magnitude they suggested."));
} else { add(P("[Simulation results reported in Results §1.]")); }
add(P("Four changes follow. The object is now called the empirical held-out frontier throughout, never the attainable or population frontier. The optimism simulation is reported alongside it. We add a margin-based dominance criterion, requiring a comparator to beat the rule's log hazard ratio by a stated amount rather than by any amount, and report the frontier membership under it. And the interpretation in both Results and Discussion is now that these numbers measure the rule's distance from an optimistic oracle, not algorithmic efficiency; the ordering survives, the magnitude does not."));
add(P("We did not find a way to supply an independent large sample for the two real cohorts, which is the check the reviewer would most want. The split-half reproducibility above is the closest available substitute and we present it as such."));
W("Where: Results §1; Discussion ¶1; Methods; analysis/frontier_optimism.R, analysis/nested_all.R.");

/* ---- 2 ---- */
add(Q("2. Uncertainty in the eligible-count matched comparison is inadequately handled."));
add(P("Partly a reporting failure on our side. The proportion was already computed within each split and the splits then averaged with equal weight — comparator-rule pairs were never pooled, so the weighting-by-comparator-count problem the reviewer describes does not arise. We did not say this anywhere, so the inference was reasonable, and the Methods now state the estimand and the order of operations explicitly."));
add(P("The part of the criticism that stands is the interval. It was bootstrapped over splits, which reuse patients, and was therefore too narrow — as the reviewer notes, narrower than our own population uncertainty. Every out-of-sample quantity, the matched comparison and the frontier statistics included, is now carried through the same patient-level outer bootstrap as the two promises."));
if (NS.colon) {
  const C=NS.colon, RT=NS.rott;
  add(P("The intervals widen substantially. At the ten per cent band the colon matched-HR proportion is " + pct(C["hr0.1"].point) + " with an outer-bootstrap interval of " + pct(C["hr0.1"].ci[0]) + " to " + pct(C["hr0.1"].ci[1]) + ", and Rotterdam " + pct(RT["hr0.1"].point) + " with " + pct(RT["hr0.1"].ci[0]) + " to " + pct(RT["hr0.1"].ci[1] ) + ". We no longer describe the advantage as real without that qualification."));
  add(P("On the remaining questions: tolerances of 2, 5, 10 and 15 per cent are all reported, and the colon estimate moves only between " + pct(Math.min(C["hr0.02"].point,C["hr0.05"].point,C["hr0.1"].point,C["hr0.15"].point)) + " and " + pct(Math.max(C["hr0.02"].point,C["hr0.05"].point,C["hr0.1"].point,C["hr0.15"].point)) + " across them. Comparators sit close to symmetrically around the rule's eligible count, with a mean relative difference of " + f(C["sk0.1"],3) + " in colon and " + f(RT["sk0.1"],3) + " in Rotterdam, so the matched set is not systematically larger or smaller."));
}
W("Where: Methods, out-of-sample evaluation; Results §1; Table S3; analysis/nested_all.R.");

/* ---- 3 ---- */
add(Q("3. The outer bootstrap is too small for stable percentile intervals."));
add(P("Accepted in substance. On the formula, the code computed sqrt(SD_total² − SD_MC²) rather than a subtraction of standard deviations; the Methods now give the expression rather than the word “subtracting”. We have also renamed the component outer-sampling, since the reviewer is right that only one cohort is ever involved and “between-cohort” misleads."));
if (NS.colon) {
  add(P("On scale, we increased the design from 70×18 to " + NS.colon.B + "×" + NS.colon.R + " and now report how the interval endpoints move as the number of resamples grows, so a reader can judge stability directly. We did not reach the 500–1000 outer resamples the reviewer suggests. Every out-of-sample quantity now passes through this loop, which roughly doubles the cost per split, and the compute available to us set the ceiling. We say so in the Methods and label these intervals exploratory rather than implying more precision than the design supports."));
} else { add(P("[Enlarged design reported in Methods and Results §2.]")); }
W("Where: Methods; Results §2; analysis/nested_all.R.");

/* ---- 4 ---- */
add(Q("4. “Cannot be stated in advance” is too absolute."));
add(P("Accepted, and the reviewer has stated the correct claim better than we did. Every power calculation depends on an effect size not yet observed, and the response is not to declare planning impossible but to condition on a minimum effect one would not want to miss. Our result is narrower than we wrote: there is no threshold in cohort size, event count or effective sample size that holds without an assumption about the diluting signal."));
add(P("The title now ends “and why no unconditional data requirement exists”. The abstract and conclusions state that the requirement can be given conditionally, on an assumed minimum diluting signal, exactly as a power calculation is given on an assumed minimum clinically relevant effect. Table 2 is presented as that family of conditional reliability curves rather than as a negative finding, so the result becomes a design tool. We have kept the negative half — that no unconditional currency works — because it is what our data show and it is what we ourselves got wrong in the previous version."));
W("Where: title; Abstract; Results §3; Discussion ¶3; Conclusions.");

/* ---- 5 ---- */
add(Q("5. Evidence that the largest diluting coefficient is the governing quantity is insufficient."));
add(P("Accepted. Running the check the reviewer implies also uncovered a confound in our own sweep, which we now report. Holding the total modification fixed keeps the full-protocol hazard ratio exactly equal, because under the full protocol the treated bonus is the sum of the coefficients; but it does not keep the ATTAINABLE improvement equal. On a 120 000-patient evaluation set the best subset reaches 0.6698 against a full-protocol 0.6900 in the three arrangements that concentrate the dilution, a gap of 0.0203, and 0.6803 in the arrangement that splits it, a gap of 0.0098. Splitting the dilution halves the prize as well as the coefficient, and the two cannot be separated by construction."));
if (SNR) {
  add(P("We also tested the reviewer's proposal directly, computing for each arrangement the population Shapley value of the most diluting criterion and the standard deviation of its estimate at a fixed fitting size. Across the four arrangements the signal-to-noise ratio orders the success probabilities at least as well as the raw coefficient does. Four arrangements cannot establish a governing quantity and we do not claim they do; the manuscript now says that a criterion-specific signal-to-noise ratio is the more plausible general form, names the further factors the reviewer lists — prevalence, correlation, retained events, censoring, weight variability — and states that our sweeps identify a principal determinant within them rather than a general law."));
}
W("Where: Results §3; Discussion ¶3; Table S4; analysis/conc_targets.R, analysis/snr_check.R.");

/* ---- 6 ---- */
add(Q("6. “Spreading enrichment does not matter” is not what the numbers show."));
add(P("Correct, and we have withdrawn the phrase. With Monte Carlo intervals attached, spreading the enrichment over two or four criteria raises the success probability at 6000 fitting patients by 0.21 (95% interval 0.08 to 0.34) and 0.20 (0.07 to 0.33) relative to concentrating it. That is not “unchanged”; it is a real difference in the opposite direction from the one we were guarding against. The text now says spreading the enrichment never hurts and at one size helps significantly, and reserves the strong statement for the dilution comparison, where the differences are −0.19, −0.26, −0.39 and −0.42 with every interval excluding zero."));
add(P("On comparability of the arrangements, the four quantities the reviewer asks for are now reported: full-protocol hazard ratio (identical at 0.6900 by construction), oracle-relaxed hazard ratio, the gap between them, and the eligible fraction (0.200 in all four). As noted under point 5, the gap is not constant, and we say so."));
W("Where: Results §3; Table S4; analysis/conc_targets.R.");

/* ---- 7 ---- */
add(Q("7. A weak hazard-ratio advantage sits uneasily with the paper's own critique of the hazard ratio."));
add(P("This is a fair and uncomfortable point and we have changed the conclusion. The rule's matched advantage is on the hazard ratio and is not reproduced on the restricted mean difference, and the paper separately argues that hazard-ratio movement need not correspond to any individual's benefit. Writing that its contribution is “to the effect estimate” papered over exactly the distinction the paper exists to draw."));
if (RR) {
  add(P("Two additions. The eligible-count-versus-RMST frontier is now reported alongside the hazard-ratio one throughout. And we added a rule that selects on the RMST Shapley value instead of the log hazard ratio: it agrees with the published rule on the criterion set in " + pct(RR.colon.same) + " of colon splits, and its out-of-sample probability of a greater RMST difference is " + pct(RR.colon.rm_moreRM) + " against " + pct(RR.colon.hr_moreRM) + " for the hazard-ratio rule. An investigator whose endpoint is absolute benefit should see that comparison before adopting either."));
}
add(P("The abstract and conclusions now say the advantage is specific to the hazard ratio and does not reproduce on the absolute-benefit estimand, rather than describing it as a contribution to the effect estimate in general."));
W("Where: Abstract; Results §1 and §7; Conclusions; analysis/rmst_rule.R.");

/* ---- 8 ---- */
add(Q("8. Methods and Results still describe the factorial analysis differently."));
add(P("Fixed. The Methods paragraph still carried the threshold-interpolation description from the previous version. It now states that the primary analysis is the success probability at fixed fitting sizes, that threshold estimates and the interval-censored regression are supplementary, how the 0.70, 0.80 and 0.90 targets are handled under right- and left-censoring, and that medians are taken over located runs only, which is why they are supplementary. The currency comparison is described precisely: all sixteen scenarios are binned into quartiles of each currency and the mean within-bin standard deviation of the success probability is reported, so no scenario is dropped."));
add(P("On Monte Carlo error in Table 2 the reviewer is right that 0.071 is large. We report it with the table and flag that the extreme cells of the min–max ranges are the least stable. We were not able to raise the replicate count within the compute available and say so rather than leaving the reader to discover it."));
W("Where: Methods, simulation and factorial; Results §3; Table 2 note; Table S2b.");

add(H1("Minor comments"));
if (CW) {
  add(P("1. Weighting in the randomised cohort. The three schemes are now carried through the full out-of-sample evaluation rather than compared on the whole cohort only. The probability of a lower out-of-sample hazard ratio is " + pct(CW.ps.lower) + " under the estimated propensity model, " + pct(CW.known.lower) + " under the known randomisation probability and " + pct(CW.none.lower) + " unweighted."));
} else { add(P("1. Weighting in the randomised cohort. All three schemes are now carried through the full out-of-sample evaluation rather than compared on the whole cohort only.")); }
add(P("2. Proportional hazards. Results now given: p = 0.28 and 0.31 for colon whole-cohort and full protocol, 0.95 and 0.65 for Rotterdam, with a sentence on what the Cox coefficient would summarise had the test failed."));
add(P("3. Rotterdam. Its matched and frontier numbers are now labelled descriptive wherever they appear, on the same footing as its hazard ratios, rather than standing beside colon as evidence of method performance."));
add(P("4. Table 1 units. “d” and “days” are unified to “days”."));
add(P("5. Figure sizes. Figures 1 and 6 are enlarged again in the main text and both remain full-page in the supplement."));
add(P("6. Placeholders. Repository URL, authors, affiliations, competing interests, funding and contributions remain for the corresponding author to complete before submission; they are marked in the manuscript."));
add(P("7. Acknowledgements. Reworded to “whose comments motivated additional analyses and corrections”."));

add(new Paragraph({spacing:{before:300},children:[new TextRun({
  text:"The frontier optimism and the conditional framing of the sample-size result are the two changes that alter what the paper claims. Both came from this review, and in both cases the earlier version was more confident than the design allowed.",
  size:21,font:"Calibri",italics:true})]}));

const doc=new Document({sections:[{properties:{page:{size:{width:12240,height:15840},
  margin:{top:1080,bottom:1080,left:1180,right:1180}}},children:body}]});
Packer.toBuffer(doc).then(b=>{fs.writeFileSync("response_to_reviewer_round3.docx",b);
  console.log("written",b.length,"bytes");});
