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
  text:"Response to the tenth review",bold:true,size:30,font:"Calibri"})]}));
add(P("Manuscript: What data-driven relaxation of trial eligibility criteria can and cannot promise: an out-of-sample evaluation, and why reliability was not determined by cohort size alone across the mechanisms examined",{size:20,color:"555555",after:250}));

add(P("Three points, all accepted and all implemented, plus the traceability request. The third turned out to need a table rather than a sentence, and writing it out showed that the machinery was already doing the right thing but had never said so.",{after:250}));

/* 1 */
add(Q("1. The observed range mixes two sources of variation, so its width cannot be attributed to cohort composition."));
add(P("Correct. The Methods said the observed range carries both the patient-resampling variability and the Monte Carlo noise of a " + (NS.colon ? f0(NS.colon.R) : "25") + "-split estimator, and then the Results attributed the whole width to which patients happen to be in the cohort. That does not follow."));
add(P("Both sentences are rewritten. The Results now say that the combined resampling-and-splitting procedure produced central ranges of the stated widths, that the width is not attributable to the patients alone because it carries the inner Monte Carlo variance as well, and — taking the reviewer's second option — that the decomposition puts the outer-sampling standard deviation at " + (NS.colon ? f(NS.colon["hr0.1"].sd_outer,3) : "—") + " and " + (NS.rott ? f(NS.rott["hr0.1"].sd_outer,3) : "—") + " against totals of " + (NS.colon ? f(NS.colon["hr0.1"].sd_total,3) : "—") + " and " + (NS.rott ? f(NS.rott["hr0.1"].sd_total,3) : "—") + ", so patient sampling contributes the larger part while the patient-only quantiles remain unidentified. The Conclusions no longer say “sensitive to cohort composition”; the paired difference now “varies substantially under the combined resampling-and-splitting procedure”."));
add(P("Two other places said the same thing more quietly and are fixed with them: the abstract, which had the patients moving the figures on their own, and the paragraph on the paired difference, which now adds that the inner Monte Carlo component is a larger share of the total for the paired quantities than for the marginal ones (" + (NS.colon && NS.colon.d_pair_lower ? f(NS.colon.d_pair_lower.sd_mc,3) + " of " + f(NS.colon.d_pair_lower.sd_total,3) : "—") + " on the colon hazard-ratio difference), so the narrower paired widths are not patient-level variability either."));
W("Where: Abstract; Results, the matched comparison, the repeated-splits section and the paired rule comparison; Discussion; Conclusions.");

/* 2 */
add(Q("2. Calling 150 and 100 “outer resamples” is still not right."));
add(P("Accepted. The rows now read “bootstrap resamples x inner splits, forming the ranges”, at " + (NS.colon ? f0(NS.colon.lower.n_outer) : "149") + " x " + (NS.colon ? f0(NS.colon.R) : "25") + " in Table S3 and " + (TN ? f0(TN.colon.front_conf.n_outer) : "99") + " x " + (TN ? f0(TN.colon.R) : "25") + " in Table S3c, with a row beneath each giving the one observed-data evaluation held out of the ranges. The count that appears in the table is now the count the range actually rests on, and the reader does not have to reach the note to learn that."));
W("Where: Supplement Tables S3 and S3c.");

/* 3 */
add(Q("3. Quantify the unusable inner splits."));
add(P("Accepted, and the four questions have four definite answers. A resample's value for a statistic is the mean over the splits that define it, not over all " + (NS.colon ? f0(NS.colon.R) : "25") + ". The R in s squared over R is that resample's own usable count and never the nominal one — the export computes it as the within-resample variance divided by the stored usable count, so no re-check of the Monte Carlo component is needed. No statistic is undefined in a whole resample anywhere: every resample contributes to every range."));
if (NUM.usable) add(P("The counts themselves are now in the paper as Supplementary Table S1g, with each statistic under the name the paper uses for it rather than its column name in the result file, and with the frequency of the shortfall as well as its depth \u2014 which turned out to matter. In the two-way design the shortfall is rare: on colon three statistics at the tightest matching band fall below the nominal count in " + f0((NUM.usable.two_colon.short[0]||{}).n_below) + " of " + f0(NUM.usable.two_colon.n_resamples) + " resamples, smallest usable count " + f0(NUM.usable.two_colon.min_any) + "; on Rotterdam the two-way design is at the nominal count for every statistic in every resample. In the three-way design it is not rare: the three quantities that need a dominator on the selection third are undefined together when a split produces none, and the most demanding of them, the replication rate with the margin required, loses at least one split in " + f0((NUM.usable.three_colon.short.filter(function(q){return q.quantity===NUM.usable.three_colon.worst;})[0]||{}).n_below) + " of " + f0(NUM.usable.three_colon.n_resamples) + " colon resamples and " + f0((NUM.usable.three_rott.short.filter(function(q){return q.quantity===NUM.usable.three_rott.worst;})[0]||{}).n_below) + " of " + f0(NUM.usable.three_rott.n_resamples) + " Rotterdam resamples, with smallest usable counts " + f0(NUM.usable.three_colon.min_any) + " and " + f0(NUM.usable.three_rott.min_any) + " and medians of " + f0(Math.min.apply(null, NUM.usable.three_colon.short.concat(NUM.usable.three_rott.short).map(function(q){return q.median;}))) + ". Those fractions count RESAMPLES touched, not splits lost \u2014 a typical resample still keeps " + f0(Math.min.apply(null, NUM.usable.three_colon.short.concat(NUM.usable.three_rott.short).map(function(q){return q.median;}))) + " of the nominal " + f0(NUM.usable.three_colon.R_nominal) + " \u2014 and the table now says so, because our first draft reported only the minimum and the median and made the shortfall look occasional, while this phrasing could equally make it look catastrophic."));
add(P("The Methods now state the averaging rule and the denominator explicitly, and the export asserts that no usable count reaches zero and stops the build if one ever does."));
W("Where: Methods, out-of-sample evaluation; Supplement Table S1g; analysis/export_numbers.R.");

/* traceability */
add(H1("Traceability of the round-nine correction"));
add(P("The reviewer is right that an admitted error raises the bar for verifying what replaced it, and that the replacement should not have to be taken on trust either. We have added analysis/check_outer.R, which reads only the four stored result objects — analysis/out/nested_colon.rds, nested_rott.rds, threeway_nested_colon.rds and threeway_nested_rott.rds — and prints the three statements at issue: the number of non-finite cells in each result matrix, which is zero in all four; that the first row of each is the observed-data evaluation, leaving " + (NS.colon ? f0(NS.colon.lower.n_outer) : "149") + " and " + (TN ? f0(TN.colon.front_conf.n_outer) : "99") + " bootstrap resamples; and the usable inner-split counts behind Table S1g. It also computes the Monte Carlo term both ways, dividing by each resample's usable count and by the nominal count, and locates and prints the actual source lines that make the first replicate the observed data and that set the denominator, rather than describing them. Two of those statements were fixed text in our first draft of the script, which an audit caught: the replicate count is now read out of analysis/nested_all.R and analysis/threeway_nested.R and compared with the number of rows stored, since the objects record the count AFTER any discard and a discarded replicate would otherwise be invisible. The script exits non-zero if any check fails. It runs in well under a second from the repository root and needs nothing but the result files and the sources."));
add(P("On the wording of the round-nine admission, we take the reviewer's phrasing. We inferred the cause incorrectly without inspecting the stored result object; the subsequent audit showed that no outer replicate failed or was discarded. That is what happened, and it is more useful to an editor than the stronger word we used."));
W("Where: analysis/check_outer.R (new); Supplement Text S1.6.");

add(H1("Added after the tenth review\u2019s own audit"));
add(P("Three further things, two of them ours to have caught."));
add(P("The audit script had a defect of exactly the kind it exists to prevent. It collected the expected source lines with c(), and c() drops NULL, so a line that could not be found simply vanished from the sequence and the branch that sets the failure flag could never run: the script would report a pass having silently checked one thing fewer. It now collects them with list(), reports each by name when missing, and carries a deliberate negative test \u2014 a search for a line that cannot exist \u2014 so the failure branch is exercised on every run rather than assumed to work. We verified the repair by mutating one of the four target lines in a scratch copy: the script names the missing check and exits non-zero, and the source was restored unchanged afterwards."));
add(P("The four result objects the script reads were not in the update package. The exclusion that keeps the large intermediate objects out of the archive was matching them too, so the audit we described could not actually be run from what we sent. They are 94 kB in total and are now included, together with the script\u2019s output as response/check_outer_output.txt, so the check can be run or simply read."));
add(P("On the three-way conditioning the reviewer is right that the summary was loose in a way that could mislead. The Results now say \u201camong splits with at least one selection-stage dominator\u201d where the replication rate and the carry-over are first reported, and say explicitly that frontier membership is not conditioned in the same way, a split with no dominator leaving the rule undominated by construction. Tables S1g and S3c carry the same distinction. We have also taken the correction on how to read the frequencies: \u201cshort in 85 of 99\u201d counts resamples in which at least one inner split failed to define the statistic, not splits, and the table now says so beside the median, which is " + (NUM.usable ? f0(Math.min.apply(null, NUM.usable.three_colon.short.concat(NUM.usable.three_rott.short).map(function(q){return q.median;}))) : "23") + " of " + (NUM.usable ? f0(NUM.usable.three_colon.R_nominal) : "25") + " for every affected quantity."));
add(P("The paired-versus-marginal width comparison named a lower bound that only held for the published rule. It now compares the four paired ranges against all eight marginal figures the two rules contribute, so the bound is " + (NS.colon ? f(Math.min.apply(null,[NS.colon.lower,NS.colon.greater,NS.rott.lower,NS.rott.greater,NS.colon.rmrule_lower,NS.colon.rmrule_greater,NS.rott.rmrule_lower,NS.rott.rmrule_greater].map(function(z){return z.ci80[1]-z.ci80[0];})),2) : "\u2014") + " rather than the narrower figure we quoted. And the repository README still carried three claims this manuscript has since withdrawn or corrected \u2014 an inflation figure from an earlier run, now " + (NUM.confound_limits ? pct(NUM.confound_limits.inflation,1) : "\u2014") + "; coverage figures from a 200-replicate run, now " + (NUM.coverage ? f0(NUM.coverage.reps) : "\u2014") + " replicates; and low interaction leverage described as structural invisibility independent of sample size, which is attenuation by a known factor, logical implication being the only genuinely uninformative case. It is synchronised."));

add(new Paragraph({spacing:{before:280},children:[new TextRun({
  text:"Two of these three were things the code already did correctly and the paper had never said. That is its own kind of defect: a reader cannot check what is only in the source, and an author who has not written it down has not really checked it either.",
  size:21,font:"Calibri",italics:true})]}));

const doc=new Document({sections:[{properties:{page:{size:{width:12240,height:15840},
  margin:{top:1000,bottom:960,left:1120,right:1120}}},children:body}]});
Packer.toBuffer(doc).then(b=>{fs.writeFileSync("response_to_reviewer_round10.docx",b);
  console.log("written",b.length,"bytes");});
