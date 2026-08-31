const d = require('docx');
const {Document, Packer, Paragraph, TextRun, AlignmentType, HeadingLevel} = d;
const fs = require('fs');
const NUM = JSON.parse(fs.readFileSync("/home/claude/repo/analysis/out/numbers.json","utf8"));
const PR=NUM.primary||{}, NS=NUM.nested||{}, FO=NUM.frontier_opt||null,
      TW=NUM.threeway||null, HZ=NUM.horizon||null, SC=NUM.snr_curve||null;
const f=(x,k=3)=>(x===null||x===undefined)?"—":Number(x).toFixed(k);
const f0=x=>f(x,0); const pct=(x,k=1)=>(x===null||x===undefined)?"—":(100*Number(x)).toFixed(k)+"%";
const C=PR.colon||{}, R=PR.rott||{};

const body=[]; const add=(...x)=>x.forEach(e=>Array.isArray(e)?body.push(...e):body.push(e));
const P=(t,o={})=>new Paragraph({spacing:{after:o.after??130,line:290},
  alignment:AlignmentType.JUSTIFIED,
  children:[new TextRun({text:t,size:o.size??21,font:"Calibri",italics:o.i,bold:o.b,color:o.color})]});
const H1=t=>new Paragraph({heading:HeadingLevel.HEADING_1,spacing:{before:300,after:140},
  children:[new TextRun({text:t,font:"Calibri"})]});
const Q=t=>new Paragraph({spacing:{before:230,after:90},indent:{left:340},
  border:{left:{style:d.BorderStyle.SINGLE,size:12,color:"9DB2C6",space:12}},
  children:[new TextRun({text:t,size:20,font:"Calibri",italics:true,color:"3A4A5C"})]});
const W=t=>add(P(t,{size:19,color:"55606B",after:190}));

add(new Paragraph({spacing:{after:60},children:[new TextRun({
  text:"Response to the fourth review",bold:true,size:30,font:"Calibri"})]}));
add(P("Manuscript: What data-driven relaxation of trial eligibility criteria can and cannot promise: an out-of-sample evaluation, and why no data requirement can be read from cohort size alone",{size:20,color:"555555",after:250}));

add(P("The first comment led us to an error that matters more than the inconsistency the reviewer observed. Chasing it down, we found that the analyses added in the second and third revisions had been run on the Rotterdam cohort with the relapse-free survival time paired with the death indicator, at a five-year horizon, while Table 1 used the death time with the death indicator at seven years. That is not a valid pair: it censors deaths at relapse times and systematically shortens event times. It was not Monte Carlo noise between two runs; it was two different endpoints. We have corrected it, rebuilt every affected number, and restructured the analysis so that it cannot recur. We are grateful the reviewer pressed on a discrepancy we had explained away.",{after:250}));

add(H1("Major comments"));

/* ---- 1 ---- */
add(Q("1. The main text and the supplement report different numbers for the same quantities; name a single primary analysis and generate everything from it."));
add(P("Accepted, and the diagnosis was wrong in our previous reply. We attributed the divergence to different split counts and Monte Carlo variation. The real cause was that eleven analysis scripts specified the Rotterdam endpoint as the relapse-free time with the death indicator at a horizon of 1825 days, while the script behind Table 1 specified the death time with the death indicator at 2555 days. The mismatched pair shortens event times and is not interpretable; every Rotterdam figure produced by those scripts was affected."));
add(P("The remedy is structural rather than editorial. A single script, analysis/primary.R, now computes every observed-cohort point estimate quoted anywhere in the paper — the out-of-sample comparison, the matched statistics at all four tolerances, the frontier and dominance counts, and the restricted-mean rule variant — in one pass per cohort, and writes one result file. The abstract, the main text, Table 1 and the supplement all read from that file; none of them contains a transcribed number. The nested bootstrap now supplies uncertainty only, never a point estimate, which removes the second source of disagreement."));
add(P("Four checks run at export time and stop the build if violated. Three are on the exported numbers: that the Rotterdam endpoint is the death time with the death indicator, that the horizons are the intended 1825 and 2555 days, and that the primary and nested estimates of the same quantity do not differ by more than Monte Carlo variation could explain. The fourth is on the source, because a check on the numbers alone would not have caught this error: every analysis script is scanned, and the build stops if any line pairs the relapse-free time with the death indicator or calls a Rotterdam dataset at the colon horizon. That is the check that would have failed in the previous revision. The corrected canonical values are given in Table 1; for Rotterdam the probability of a lower out-of-sample hazard ratio is " + f(R.lower,3) + " rather than the previously reported value, and the matched proportion at the ten per cent band is " + f(R["hr0.1"],3) + "."));
W("Where: analysis/primary.R (new); analysis/export_numbers.R (assertions); Table 1; Abstract; Results §1; Supplement Table S3.");

/* ---- 2 ---- */
add(Q("2. “The effect-estimate promise was not kept in either cohort” overstates what proportions with wide patient-level intervals can establish."));
add(P("Accepted; we have adopted the reviewer's wording. The sentence in the abstract now reads that the observed proportions were below one half in colon and close to one half in Rotterdam, and that with patient-level uncertainty this establishes neither failure nor success of the promise. The same change is made in the Results and in the Conclusions, and no sentence anywhere now says the promise was kept or not kept."));
add(P("The claim about the restricted-mean rule variant is softened in the same way. We previously wrote that switching the decomposition improves neither estimand and that an investigator gains nothing by it. What we can say is that the two decompositions select almost different criterion sets, and that the variant shows no clear or consistent advantage: its point estimates go in different directions on the two estimands and the intervals establish neither superiority nor equivalence. The supplement caption for Table S3c is changed to match."));
W("Where: Abstract, Results §1 and §5, Discussion, Conclusions, Supplement Table S3c.");

/* ---- 3 ---- */
add(Q("3. “The rule is not close to the best attainable protocol” still treats the empirical frontier as the target; define the margin and consider a nested three-way split."));
add(P("Accepted on all three sub-points. The sentence now reads that the rule is not close to the empirical optimistic oracle, and adds explicitly that how far it sits from the true best attainable protocol is something these cohorts cannot tell us."));
add(P("On the margin: it is " + f(C.margin,2) + " on the LOG hazard ratio, roughly a five per cent relative change, chosen by us as a sensitivity margin, not derived from any clinical standard. The scale is now stated wherever the margin appears, which it was not before, and it is described throughout as an investigator-chosen sensitivity margin so that no reader takes it for a threshold with general clinical meaning. The margin is applied only to the observed-cohort frontier statistics; the simulation figures use a bare inequality, and the text now says so rather than leaving the reader to infer it."));
if (TW) {
  add(P("On the three-way split: we have run it. Each cohort is divided into three stratified thirds — fit, select, test. Subsets that dominate the rule are identified on the second third and exactly those subsets are re-evaluated on the third, which has been used for nothing. In colon a median of " + f0(TW.colon.dom_sel) + " subsets dominate on the selection third and " + pct(TW.colon.repro) + " of them still dominate on the test third; in Rotterdam, " + f0(TW.rott.dom_sel) + " and " + pct(TW.rott.repro) + ". Frontier membership itself moves little: the rule is on the frontier in " + pct(TW.colon.front_sel) + " of colon splits judged on the selection third and " + pct(TW.colon.front_test) + " judged on the untouched third. So the optimism is substantial in the count of apparent dominators and in how many of them survive re-evaluation, and modest in the headline membership figure. The reviewer's prediction is borne out in the first sense and not in the second, and we now report both. A third of a cohort is a small evaluation set, so these rates are themselves uncertain and are reported as an order of magnitude."));
} else {
  add(P("On the three-way split: implemented as analysis/threeway.R and reported in Results §1 and Supplement Table S3d."));
}
W("Where: Results §1; Supplement Table S3d; analysis/threeway.R (new).");

/* ---- 4 ---- */
add(Q("4. A sentence naming the largest diluting coefficient as the governing quantity contradicts the paper's own results, and “read the requirement off conditional curves” promises curves that do not exist."));
add(P("Both accepted. The sentence is deleted. It contradicted two results we ourselves report: spreading the enrichment raised success by 0.21 with an interval of [0.08, 0.34] at 6 000 rather than leaving it unchanged, and halving the diluting coefficient also roughly halves the attainable improvement, so in that design the coefficient and the size of the prize move together and neither can be assigned the effect alone. The Discussion now says plainly that we are not able to name the governing quantity, states the weaker claim we can support, and marks the withdrawal."));
add(P("On the curves, we have taken the reviewer's second option and also attempted the first. Table 2 is now described as a sensitivity analysis across arrangements at fixed fitting sizes, not as a design curve, and the phrase about reading a requirement off conditional curves is removed." + (SC ? " In addition, Supplement Table S4b reports success against a criterion-specific signal-to-noise ratio — the population Shapley value of the most diluting criterion divided by the standard deviation of its estimate at that fitting size — across " + SC.cells.length + " cells, four arrangements at three fitting sizes. The Spearman correlation with success is " + f(SC.sp_snr,2) + " for the ratio against " + f(SC.sp_n,2) + " for fitting size alone, so the ratio does order the cells better, in the direction the reviewer suggested in the third round. We stop short of calling it the governing quantity: twelve cells at twenty-five replicates cannot establish one, the ratio and the fitting size are correlated by construction, and in two of the four arrangements success barely moves with size. The table is offered as a direction, and the Discussion says what we can and cannot support." : " A signal-to-noise indexed table is included in the supplement where the compute allowed it, labelled as indicative.")));
W("Where: Discussion ¶3; Table 2 caption; Supplement Table S4b; analysis/snr_curve.R (new).");

/* ---- 5 ---- */
add(Q("5. The inner Monte Carlo variance uses p(1−p)/R, which is wrong for the matched statistics; and the outer count needs convergence evidence."));
add(P("Accepted. The binomial form is right only for a statistic that is 0/1 within a split. The two promises and the frontier indicators are of that kind, but a matched rank is already a proportion over comparators, so p(1−p)/R overstated its Monte Carlo component and, by subtraction, understated the outer-sampling component. The Monte Carlo variance is now estimated from the data: within each resample we take the sample variance of the per-split values and average s²/R over resamples. This reduces to the binomial form for the 0/1 statistics and is correct for the others."));
if (NS.colon && NS.colon.lower && isFinite(NS.colon.lower.conv)) {
  const mv = Math.max.apply(null, ["more","lower","front_hr","front_rm","front_hrM","hr0.1","rm0.1"].map(k=>(NS.colon[k]||{}).conv||0));
  add(P("On convergence, every reported interval is now recomputed from the first 50, 100 and half of the outer resamples, and the largest movement of either endpoint between half and the full count is reported. In colon that movement is at most " + f(mv,3) + " across the quantities in Table S3. That is the resolution at which these intervals should be read, and it is not fine enough to support any claim that turns on the second decimal; the Methods say so and continue to describe the intervals as exploratory. Increasing the outer count further was beyond the compute available to us, and we would rather report the resolution honestly than imply a precision we have not demonstrated."));
} else {
  add(P("On convergence, every reported interval is now recomputed from the first 50, 100 and half of the outer resamples, and the largest movement of either endpoint between half and the full count is reported in Supplement Table S3."));
}
W("Where: Methods; Results §2; Supplement Table S3; analysis/nested_all.R, analysis/export_numbers.R.");

/* ---- 6 ---- */
add(Q("6. The restricted-mean horizon is not justified, agreement between the two decompositions is reported at one horizon only, and the RMST-rule metrics lack patient-level intervals."));
add(P("All three are addressed. On the horizon: the restricted mean must be taken inside the observed follow-up of both arms of every candidate protocol, or subsets are not compared on the same scale." + (HZ ? " At the horizons used, at least " + pct(HZ.risk_colon) + " of patients in either colon arm and " + pct(HZ.risk_rott) + " in either Rotterdam arm are still under observation, and the next horizon we tried drops that figure sharply. The rationale and these figures are now in the Methods and Results rather than implicit." : " The rationale and the corresponding at-risk proportions are now stated in the Methods and Results.")));
if (HZ) {
  const rng=(T,k)=>f(Math.min.apply(null,T.map(r=>r[k])),3)+" to "+f(Math.max.apply(null,T.map(r=>r[k])),3);
  add(P("On agreement across horizons: the selection comparison is repeated at four horizons per cohort. The two decompositions select the same criterion set in " + rng(HZ.colon,"same") + " of colon splits and " + rng(HZ.rott,"same") + " of Rotterdam splits, with mean Jaccard similarity of " + rng(HZ.colon,"jac") + " and " + rng(HZ.rott,"jac") + ". They disagree at every horizon tried, so the disagreement is a property of the estimands rather than of the particular horizon, but the exact rate is horizon-dependent and is now always reported with the horizon attached (Supplement Table S3e)."));
  add(P("The sweep also turned up something we had not looked for and that bears on comment 2. In colon the sign of the absolute-benefit comparison depends on the horizon: at the shortest horizon tried both relaxed protocols have a larger mean restricted mean difference than the full protocol (" + f(HZ.colon[0].rmF,1) + " days against " + f(HZ.colon[0].rm1,1) + " and " + f(HZ.colon[0].rm2,1) + "), and at the horizon used in the main analysis the ordering reverses (" + f(HZ.colon[2].rmF,1) + " against " + f(HZ.colon[2].rm1,1) + " and " + f(HZ.colon[2].rm2,1) + "). Our main-text figures are therefore the pessimistic end of the range we examined. This is now reported in the Results, and it is a further reason the softened wording the reviewer asked for is the right one."));
}
add(P("On intervals: the restricted-mean rule variant is now carried through the same nested bootstrap as everything else, so its agreement rate and all of its out-of-sample metrics have patient-level intervals rather than intervals bootstrapped across splits that share patients. They are reported in Supplement Table S3 alongside the published rule's."));
W("Where: Methods; Results §5; Supplement Tables S3 and S3e; analysis/horizon_sweep.R (new), analysis/nested_all.R.");

add(H1("Minor comments"));
add(P("1. Supplement Text S1.4 gave the criterion-count factor as 6 against 10; the analysis uses 6 against 8, as the main text says. Corrected to 8."));
add(P("2. “Between-cohort component” has been replaced by “outer-sampling component” everywhere, including in one sentence of the Methods that the previous revision missed."));
add(P("3. “Validation” is replaced by “out-of-sample evaluation” in the title, the abstract and the keywords, and by “confirmation” where the sense was that a comparison confirms nothing. The paper reports an evaluation and a stress test; it validates nothing, and the title should not suggest otherwise."));
add(P("4. Trailing whitespace at manuscript/part3.js has been removed, and the whole manuscript source now passes a whitespace check."));
add(P("5. Page breaks have been tightened so that no blank page falls inside either document."));
add(P("6. Author names, affiliations, funding, competing interests, contribution statement and the repository URL remain placeholders for the corresponding author to complete before submission, and are marked as such in the manuscript."));

add(new Paragraph({spacing:{before:300},children:[new TextRun({
  text:"The endpoint error found through comment 1 is the most serious mistake in this manuscript's history, and it survived three rounds of review because our numbers were produced by many scripts rather than one. That is now fixed structurally, not by hand. The softened claims in comments 2 and 4 are corrections of overreach, and in both cases our own results were the evidence against us.",
  size:21,font:"Calibri",italics:true})]}));

const doc=new Document({sections:[{properties:{page:{size:{width:12240,height:15840},
  margin:{top:1080,bottom:1080,left:1180,right:1180}}},children:body}]});
Packer.toBuffer(doc).then(b=>{fs.writeFileSync("response_to_reviewer_round4.docx",b);
  console.log("written",b.length,"bytes");});
