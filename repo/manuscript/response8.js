/* The provenance check runs before this document is written, so the letter is
 * gated the same way the manuscript and supplement are. */
require("child_process").execFileSync(process.execPath, [__dirname + "/check_numbers.js"],
  { stdio: "inherit", cwd: __dirname });

const d = require('docx');
const {Document, Packer, Paragraph, TextRun, AlignmentType, HeadingLevel} = d;
const fs = require('fs');
const NUM = JSON.parse(fs.readFileSync("/home/claude/repo/analysis/out/numbers.json","utf8"));
const PR=NUM.primary||{}, NS=NUM.nested||{}, TW=NUM.threeway||null,
      TN=(NUM.threeway_nested&&NUM.threeway_nested.colon)?NUM.threeway_nested:null,
      CV=NUM.converge||null, FXD=NUM.fixedn||{}, LOSO=(NUM.fixedn||{}).currency_loso||null;
const f=(x,k=3)=>(x===null||x===undefined||!isFinite(x))?"—":Number(x).toFixed(k);
const f0=x=>f(x,0); const pct=(x,k=1)=>(x===null||x===undefined||!isFinite(x))?"—":(100*Number(x)).toFixed(k)+"%";
const C=PR.colon||{}, R=PR.rott||{};
const rng  = z => "[" + f(z.ci80[0],2) + " to " + f(z.ci80[1],2) + "]";
const rng1 = z => "[" + f(z.ci[0],1) + " to " + f(z.ci[1],1) + "]";

const body=[]; const add=(...x)=>x.forEach(e=>Array.isArray(e)?body.push(...e):body.push(e));
const P=(t,o={})=>new Paragraph({spacing:{after:o.after??96,line:264},
  alignment:AlignmentType.JUSTIFIED,
  children:[new TextRun({text:t,size:o.size??21,font:"Calibri",italics:o.i,bold:o.b,color:o.color})]});
const H1=t=>new Paragraph({heading:HeadingLevel.HEADING_1,spacing:{before:250,after:120},
  children:[new TextRun({text:t,font:"Calibri"})]});
const Q=t=>new Paragraph({spacing:{before:200,after:80},indent:{left:340},
  border:{left:{style:d.BorderStyle.SINGLE,size:12,color:"9DB2C6",space:12}},
  children:[new TextRun({text:t,size:20,font:"Calibri",italics:true,color:"3A4A5C"})]});
const W=t=>add(P(t,{size:19,color:"55606B",after:170}));

add(new Paragraph({spacing:{after:60},children:[new TextRun({
  text:"Response to the eighth review",bold:true,size:30,font:"Calibri"})]}));
add(P("Manuscript: What data-driven relaxation of trial eligibility criteria can and cannot promise: an out-of-sample evaluation, and why reliability was not determined by cohort size alone across the mechanisms examined",{size:20,color:"555555",after:250}));

add(P("We have taken the reviewer's first recommendation in the form the reviewer preferred. The nested quantities are no longer presented as intervals of any kind. They are reported as patient-resampled ranges, described as such, and no claim anywhere in the paper now turns on whether one of them covers one half, or zero, or any other value. That change reaches the abstract, the Methods, both Results sections that used them, the Discussion and every table. It costs the paper nothing it was entitled to, because the inference it was making was not licensed.",{after:250}));

add(H1("Major comments"));

/* 1 */
add(Q("1. The variance-deflated interval is not a validated 95% patient-level interval, and should not be used as one."));
add(P("Accepted, and we have taken option (b). Running the bootstrap at the point estimate's own inner split count and then evaluating coverage by simulation is roughly twenty times the compute this analysis already uses for the first part alone, and we do not have it, so the second option is the honest one and we would rather say so than half-do the first."));
add(P("The mechanics of the change. Every out-of-sample probability now carries a PATIENT-RESAMPLED RANGE: the cohort is bootstrapped over patient identifiers, the whole split procedure is rerun inside each resample, and we report the central 80% of the resulting values with the wider 2.5 to 97.5 per cent span beside it. The phrases “95% interval”, “confidence interval” and “patient-level interval” are gone from the paper except where they are being disclaimed. Our first pass at this missed three places and introduced a fresh over-claim in a fourth; a self-audit caught them and they are listed at the end of this letter. The Methods now state the three separate reasons these are not intervals: each replicate is a " + (NS.colon ? f0(NS.colon.R) : "25") + "-split estimator against the " + (C.R ? f0(C.R) : "500") + " behind the point estimate, so the spread carries Monte Carlo variance the population does not; the correction for that is a linear shrinkage that matches a second moment and is not known to recover quantiles of the patient-sampling distribution from its convolution with Monte Carlo noise, for bounded statistics produced by a procedure containing a non-smooth Shapley sign step and a frontier selection; and coverage has not been evaluated against a known population at all."));
add(P("The substantive change is what we no longer say. The matched comparison used to conclude that “every interval contains one half, so neither an advantage nor its absence is established”. It now reports the point estimate and says that resampling the patients moves the statistic across most of the distance between chance and certainty, which is a description of the data rather than a test. The paired rule comparison used to conclude that “every one of these intervals contains zero, so the paired advantage of either rule is not established”; it now reports that the ranges reach well past zero on both sides and makes no claim either way. The abstract carries the same wording. We think the paper's negative message survives this intact, because that message was always about what these cohorts cannot pin down."));
W("Where: Abstract; Methods, uncertainty and implementation; Results §1 and §2; Discussion; Supplement Tables S3, S3c and Text S1.6.");

/* 2 */
add(Q("2. A non-positive variance difference does not mean there is no patient-sampling variation."));
add(P("Correct, and this was our error twice over: we first read it as the quantity being nearly constant, then, correcting that, as the inner term accounting for the whole spread. Neither is right. When the estimated inner Monte Carlo variance is at least the total spread across resamples, the subtraction returns a non-positive outer-sampling variance and the correct statement is that the patient-level component is NOT IDENTIFIABLE at the Monte Carlo precision we can afford. It is not evidence that the component is zero and not evidence about what the inner term does or does not account for."));
add(P("The Results paragraph on the lowest-hazard-ratio dominator, the Table S3 note and the Table S3c note have all been rewritten to say that, and each says explicitly that the previous reading is withdrawn. The dash in the tables now means “no stable patient-level variance estimate could be obtained”, which is what it always meant."));
W("Where: Results §1; Supplement Tables S3 and S3c.");

/* 3 */
add(Q("3. The cluster bootstrap over sixteen factorial scenarios has no sampling population."));
add(P("Accepted, and it is withdrawn rather than caveated. The sixteen are the fixed design points of a resolution-IV fractional factorial, not clusters drawn from a population of mechanisms, so resampling them with replacement refers to nothing; it destroys the factorial balance; and because the quartile edges are recut inside every replicate it does not resample the same statistic, which is why its mean fell on the opposite side of zero from the observed difference. We had reported that sign reversal as a curiosity in the last revision. It was a symptom, and we should have read it as one."));
if (LOSO) add(P("In its place, Table S2c now carries the sensitivity analysis the fixed design does support: the three summaries recomputed with each scenario left out in turn. The events-minus-patients difference moves over " + f(LOSO.range_events[0],3) + " to " + f(LOSO.range_events[1],3) + " and the effective-sample-size difference over " + f(LOSO.range_ess[0],3) + " to " + f(LOSO.range_ess[1],3) + ", against observed values of " + f(LOSO.events_minus_patients,3) + " and " + f(LOSO.ess_minus_patients,3) + ", so no one design point is carrying the result. The claim is now the reviewer's wording: the three chosen descriptive summaries were numerically similar under this particular binning scheme. We have also said in the table that the three columns are not estimating quite the same conditional dispersion, since binning by fitting patients recovers the four fitting sizes exactly while the other two currencies mix sizes and scenarios."));
W("Where: Abstract; Results §3; Supplement Table S2c; analysis/export_numbers.R.");

/* 4 */
add(Q("4. A hundred to a hundred and fifty outer replicates cannot determine the 2.5% and 97.5% points."));
add(P("Accepted. At " + (NS.colon ? NS.colon.B : 150) + " and " + (TN ? TN.colon.B : 100) + " outer replicates those points rest on about the third replicate from each end, and we were printing them to two decimals and then reasoning about where they fell. Both were wrong."));
add(P("The central 80% range now leads everywhere, because its endpoints rest on about the tenth replicate from each end. The wider span is still given, because a reader should see the tails, but it is printed to one decimal, which is what our own endpoint Monte Carlo errors say it can support: for the colon matched comparison at the ten per cent band the endpoint error is " + (NS.colon && NS.colon["hr0.1"].ci_se ? f(Math.max(NS.colon["hr0.1"].ci_se[0], NS.colon["hr0.1"].ci_se[1]),3) : "—") + " for the wider points against " + (NS.colon && NS.colon["hr0.1"].ci80_se ? f(Math.max(NS.colon["hr0.1"].ci80_se[0], NS.colon["hr0.1"].ci80_se[1]),3) : "—") + " for the central ones. Both are reported in the tables. And, as under comment 1, nothing is now concluded from where an endpoint falls, so the remaining imprecision cannot propagate into a claim."));
W("Where: Methods; Results §1 and §2; Supplement Tables S3 and S3c; analysis/export_numbers.R.");

/* 5 */
add(Q("5. Table S1e supports the Monte Carlo magnitude but does not license the quantile correction."));
add(P("Agreed, and the phrase “what licenses the deflation” is removed. Table S1e now ends with a paragraph on what it does not establish, in the reviewer's four terms: it runs on colon only, so the same correction applied to the Rotterdam ranges rests on the variance decomposition alone; several of its observed block spreads come from two to five blocks, where a standard deviation is itself very imprecise; the block means are flat in the split count because the blocks partition one finite run, which is arithmetic rather than an independent test of unbiasedness; and confirming that dispersion falls like one over the square root of the split count says nothing about the coverage of a range whose replicates have been linearly shrunk, a variance law being a statement about second moments while the corrected range is a pair of quantiles."));
add(P("What we do still claim for it is narrower and we think uncontroversial: it puts a size on the component being removed, and it agrees with the estimate the bootstrap forms internally from the within-resample variance to within " + (CV && CV.vs_internal ? f(Math.ceil(1000*CV.vs_internal.max_diff)/1000,3) : "—") + " across " + (CV && CV.vs_internal ? f0(CV.vs_internal.rows.length) : "—") + " quantities. The corrected range is presented as an approximation of unknown accuracy, shown beside the observed range and never instead of it."));
W("Where: Supplement Table S1e.");

add(H1("Minor comments"));
add(P("1. “Too wide” is replaced. The observed spread now “carries inner Monte Carlo variance that patient sampling alone would not”, which is what we can say; with coverage unknown we cannot promise the observed range is conservative, and we no longer imply it."));
add(P("2. “Accepted in full” overstated what we did. The letter above says instead that we agree with the diagnosis, that the exact correction — rerunning the bootstrap at the point estimate's inner split count — was beyond our compute, and that we therefore downgraded the inferential claim. We have not reproduced the bootstrap at the full split count and do not imply that we have."));
add(P("3. The Results subheading now reads “Cohort size alone did not determine reliability across the mechanisms examined”, matching the title."));
add(P("4. Table precision follows the reviewer's point: the wider span is printed to one decimal throughout, in the tables as well as the text. The central range is printed to two, and the table note says that its second decimal is also inside the Monte Carlo error for the least well determined quantities — we keep it so narrow ranges stay distinguishable, not because that digit is determined."));

add(H1("Caught by our own audit after drafting this reply"));
add(P("Applying the relabelling proved harder to complete than to decide, and an audit of the redrafted manuscript found four things wrong with our first pass. We list them because they bear on how much weight to put on the rest."));
add(P("A sentence in the Methods comparing three propensity weightings still called a range an interval, printed it to two decimals, and drew a conclusion from the fact that it contained all three point estimates. That conclusion was empty as well as forbidden: the three differ by " + f(Math.max(NUM.colon_wt.ps.lower,NUM.colon_wt.known.lower,NUM.colon_wt.none.lower)-Math.min(NUM.colon_wt.ps.lower,NUM.colon_wt.known.lower,NUM.colon_wt.none.lower),3) + " and the range is more than half a unit wide, so containment was guaranteed. It is now a comparison of point estimates."));
add(P("Our replacement wording for the deleted inferences was itself an over-claim. “Resampling the patients moves the figure across most of the distance between chance and certainty” is not true of the ranges it was attached to \u2014 the central range for the matched comparison is about a third of a unit wide \u2014 and the phrase hid the fact that the range extends below one half as well as above. The abstract, Results and Discussion now give the width plainly. Two further sentences said the ranges reached “well past” one half and zero, where the margins are around five hundredths; those read as the tests we had just removed, and they are gone."));
add(P("The arithmetic of the leading claim was wrong. At " + (NS.colon ? NS.colon.B : 150) + " replicates the tenth percentile sits on the fifteenth order statistic, not the tenth. The Methods and Table S3 now say fifteenth and tenth for the two outer counts, and disclose that a replicate is dropped in each design, so the counts behind the ranges are " + (NS.colon ? f0(NS.colon.lower.n_outer) : "149") + " and " + (TN ? f0(TN.colon.front_conf.n_outer) : "99") + " rather than the nominal ones."));
add(P("Table S1e still contained a coverage claim \u2014 that the corrected range is “the anti-conservative of the two” \u2014 fifty lines above the paragraph saying the table cannot speak to coverage. It is withdrawn, and the observed-to-implied ratios it rested on are now reported accurately as running from about six tenths to about two and a half rather than seven tenths to one. Separately, the Methods claimed four interval procedures, counting the coefficient intervals of the interval-censored regression; that table prints no coefficients and no intervals, so the count is three."));

add(new Paragraph({spacing:{before:280},children:[new TextRun({
  text:"Across this review and the last, the same fault has appeared three times: we built a correction, checked that it was internally consistent, and then described it as though the check had established more than it did. The remedy we have adopted is to write down, beside each device, the specific thing it does not establish.",
  size:21,font:"Calibri",italics:true})]}));

const doc=new Document({sections:[{properties:{page:{size:{width:12240,height:15840},
  margin:{top:1000,bottom:960,left:1120,right:1120}}},children:body}]});
Packer.toBuffer(doc).then(b=>{fs.writeFileSync("response_to_reviewer_round8.docx",b);
  console.log("written",b.length,"bytes");});
