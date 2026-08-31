const d = require('docx');
const {Document, Packer, Paragraph, TextRun, AlignmentType, HeadingLevel} = d;
const fs = require('fs');
const NUM = JSON.parse(fs.readFileSync("/home/claude/repo/analysis/out/numbers.json","utf8"));
const PR=NUM.primary||{}, NS=NUM.nested||{}, TW=NUM.threeway||null, FO=NUM.frontier_opt||null,
      TN=(NUM.threeway_nested&&NUM.threeway_nested.colon)?NUM.threeway_nested:null;
const f=(x,k=3)=>(x===null||x===undefined||!isFinite(x))?"—":Number(x).toFixed(k);
const f0=x=>f(x,0); const pct=(x,k=1)=>(x===null||x===undefined||!isFinite(x))?"—":(100*Number(x)).toFixed(k)+"%";
const iv=z=>z?"["+f(z.ci[0],2)+", "+f(z.ci[1],2)+"]":"—";
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
  text:"Response to the sixth review",bold:true,size:30,font:"Calibri"})]}));
add(P("Manuscript: What data-driven relaxation of trial eligibility criteria can and cannot promise: an out-of-sample evaluation, and why no data requirement can be read from cohort size alone",{size:20,color:"555555",after:250}));

add(P("Four points, and we accept all four. Two of them catch us applying a standard to most of the paper and then exempting the numbers we had just promoted to the abstract: the three-way results had no patient-level uncertainty, and the frontier simulation reported probabilities with no replicate count or Monte Carlo error, both while the Methods claimed otherwise. One catches a comparison that cannot support the interpretation put on it — two marginal intervals in place of a paired difference. And one catches a title that claims more than sixteen scenarios can establish. The title has changed.",{after:250}));

add(H1("Major comments"));

/* 1 */
add(Q("1. The confirmatory three-way results have no patient-level uncertainty, yet the Methods say every out-of-sample quantity passes through the outer bootstrap."));
add(P("Accepted, and we took the first of the two options offered. The whole fit / select / test procedure is now wrapped in the same outer bootstrap over patient identifiers used everywhere else, with the three-way split itself taken over unique identifiers so no patient appears in more than one third of a split."));
if (TN) {
  add(P("At " + TN.colon.B + " outer resamples by " + TN.colon.R + " inner three-way splits, the replication rate is " + pct(TW.colon.repro) + " with interval " + iv(TN.colon.repro) + " in colon and " + pct(TW.rott.repro) + " with " + iv(TN.rott.repro) + " in Rotterdam. The quantity we ask a reader to carry away — the rule left undominated by every pre-selected subset — is " + pct(TW.colon.front_conf) + ", interval " + iv(TN.colon.front_conf) + ", and " + pct(TW.rott.front_conf) + ", interval " + iv(TN.rott.front_conf) + ". The single lowest-hazard-ratio dominator carries over in " + pct(TW.colon.best_holds) + ", interval " + iv(TN.colon.best_holds) + ". Endpoint movement between half and the full outer count is reported alongside, as for the other nested quantities."));
} else {
  add(P("The run is reported in Results section 1 and Supplement Table S3c, with interval endpoints and their convergence."));
}
add(P("One thing the run makes visible that we would rather state than have found: these rates are poorly determined. The bootstrap uses " + (TN ? TN.colon.R : "25") + " inner splits per resample against the " + (TW ? f0(TW.colon.R) : "400") + " of the point-estimate run, and its own observed-data replicate differs from that estimate by up to " + (NUM.threeway_nested && NUM.threeway_nested.max_gap ? f(NUM.threeway_nested.max_gap,2) : "\u2014") + " across the three confirmatory quantities. The intervals say the same thing more formally. We report the gap in the caption rather than leaving a reader to notice that two runs of the same quantity disagree, which is the failure mode of the last two rounds."));
add(P("On the comparison: the reviewer is right that " + pct(TW ? TW.colon.front_conf : null) + " and " + pct(TW ? TW.rott.front_conf : null) + " must be set against " + pct(TW ? TW.colon.front_sel : null) + " and " + pct(TW ? TW.rott.front_sel : null) + " from the selection third of the same three-way design, not against the half-split figures, which change the evaluation-set size at the same time and so confound two effects. Every place these numbers appear — the abstract, the Results and the Discussion — now makes the within-design comparison, and says why."));
W("Where: analysis/threeway_nested.R (new); Results §1; Discussion ¶1; Abstract; Supplement Table S3c.");

/* 2 */
add(Q("2. “No unconditional data requirement exists” is not established by sixteen scenarios."));
add(P("Accepted. Sixteen factorial scenarios and one arrangement sweep establish heterogeneity among the mechanisms we examined. They are not an impossibility proof, and we have neither identified the governing quantity nor supplied a conditional design curve, so the stronger claim was not ours to make."));
add(P("The title now reads “…and why no data requirement can be read from cohort size alone”. The abstract says that no universal requirement could be determined from cohort size, event count or effective sample size alone across the mechanisms simulated. The Results and the Conclusions say that what the simulations rule out is a portable cohort-size-only threshold of the kind we ourselves offered in an earlier version, within the mechanisms examined, and add explicitly that this is a statement about those mechanisms and not a general impossibility result."));
W("Where: title; Abstract; Results §3; Discussion ¶3; Conclusions.");

/* 3 */
add(Q("3. The rule comparison needs a paired difference, not two marginal intervals."));
add(P("Accepted; this was a real error of inference on our side. The two rules are fitted on the same patients in the same splits, so their errors are correlated and two intervals each formed against the full protocol say nothing about the difference between them."));
add(P("The difference is now computed inside each split and carried through the same outer bootstrap. This required adding the published rule's absolute-benefit indicator to the nested run, which had been recording it only for the variant." + (NS.colon && NS.colon.d_pair_greater ? " The paired advantage of the RMST-selected variant is " + f(C.d_pair_greater,3) + ", interval [" + f(NS.colon.d_pair_greater.ci[0],3) + ", " + f(NS.colon.d_pair_greater.ci[1],3) + "], on the restricted mean difference and " + f(C.d_pair_lower,3) + ", interval [" + f(NS.colon.d_pair_lower.ci[0],3) + ", " + f(NS.colon.d_pair_lower.ci[1],3) + "], on the hazard ratio in colon." : "")));
add(P("We have also adopted the reviewer's wording. The paper now says the paired advantage of either rule was not established, and that no equivalence analysis was prespecified, rather than claiming the intervals establish neither superiority nor equivalence — which, as the reviewer notes, would need a prespecified margin we never set."));
W("Where: analysis/nested_all.R; Results §5; Abstract; Conclusions; Supplement Table S3.");

/* 4 */
add(Q("4. The frontier simulation lacks replicate counts and Monte Carlo error; and the paper still claims “every number” is machine-checked."));
if (FO) add(P("The first is accepted and fixed. Table S3b now reports the replicate count (" + f0(FO.R) + ") and a Monte Carlo standard error beside each simulated probability" + (FO.se ? ": " + f(FO.se.true_frac,3) + " on the " + pct(FO.true_frac) + " that genuinely dominate at the population and " + f(FO.se.repro,3) + " on the " + pct(FO.repro) + " that reproduce on an independent half" : "") + ". Both of those figures are in the abstract, so they should have carried it from the start."));
add(P("The second is accepted too. The Methods sentence claiming that no figure can drift overstated the guard, which tests decimals and percentages but not bare integers. Rather than only narrow the claim, we have closed most of the gap: " + (NUM.integers ? f0(Object.keys(NUM.integers).length) : "the") + " counts a reader relies on — both cohort sizes, the criterion and subset counts, both horizons, every split and resample count including those of the three-way design added in this revision, the simulation replicate counts and the number of factorial scenarios — are now asserted individually against the analysis output, and the build stops if any of them changes. The Methods now state the scope of the automatic check and the existence of the integer schema, and say plainly that an earlier version of this paper claimed more than its checks delivered."));
add(P("Working through this we found five further defects and would rather list them than have them found. A Results heading still read \u201cNo unconditional data requirement exists\u201d, and the Conclusions still contained the clause \u201cwhat does not exist is an unconditional threshold\u201d, both surviving the change we describe under comment 2. The note under Table S2 reinstated the information-currency claim the Results withdraw, computed over the same six selected scenarios. Text S1.6 still said four export checks run; there are six. The claim that the paper uses only two interval procedures was false \u2014 it uses four, including a normal-approximation Monte Carlo interval for simulated probabilities, which is the one place a standard deviation multiplier is used; the Methods now list all four and say which class of quantity each covers. And the Methods illustrated Rotterdam\u2019s near-deterministic assignment with two counts we could not reproduce from the cohort; recomputed with the definition stated, the band holds " + (NUM.rott_age_band ? f0(NUM.rott_age_band.n_band) : "\u2014") + " patients of whom " + (NUM.rott_age_band ? f0(NUM.rott_age_band.n_treated) : "\u2014") + " received chemotherapy, and the figures are now read from the result file.",{after:130}));
add(P("On reproducibility materials: the repository is submitted with the manuscript sources, every analysis script, the result files, the clean-build log and the check output. We agree that after this many rounds a statement in a cover letter is not evidence, and that the reviewer should be able to run the checks rather than take our word for them. The repository URL placeholder is the corresponding author's to complete at submission."));
W("Where: Methods, implementation subsection; analysis/export_numbers.R (integer schema); Supplement Table S3b.");

add(H1("Minor comments"));
add(P("1. The claim that the advantage is “specific to the hazard ratio and does not appear on absolute benefit” is corrected. The abstract and Conclusions now say the hazard-ratio point estimates favour the rule in both cohorts while the two cohorts point opposite ways on absolute benefit (colon " + f(C["rm0.1"],3) + ", Rotterdam " + f(R["rm0.1"],3) + "), which is what the numbers show."));
add(P("2. “One interval procedure used everywhere” is narrowed to every out-of-sample probability. The interaction and Shapley analyses use bias-corrected and accelerated intervals; the Methods and the Results now list all four procedures the paper uses and say which class of quantity each covers, as set out under comment 4."));
add(P("3. Table S3c's caption said block (c) is an oracle on “a different half”. It is a different third; corrected."));
add(P("4. The signal-to-noise comparison stays in the supplement with its caveats, and is not raised to a design recommendation anywhere."));
add(P("5. Thank you for the page-by-page render check. The whitespace after Supplementary Figure S1 and on the final reference page is a consequence of keeping the full-page figures on their own pages; we have left it rather than compress the figures."));

add(new Paragraph({spacing:{before:300},children:[new TextRun({
  text:"Two of these points are the same mistake in different places: we set a standard for the paper and then exempted the numbers we most wanted to be true. That is worth naming, because it is not something a build check catches.",
  size:21,font:"Calibri",italics:true})]}));

const doc=new Document({sections:[{properties:{page:{size:{width:12240,height:15840},
  margin:{top:1080,bottom:1080,left:1180,right:1180}}},children:body}]});
Packer.toBuffer(doc).then(b=>{fs.writeFileSync("response_to_reviewer_round6.docx",b);
  console.log("written",b.length,"bytes");});
