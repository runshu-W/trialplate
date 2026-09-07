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
  text:"Response to the ninth review",bold:true,size:30,font:"Calibri"})]}));
add(P("Manuscript: What data-driven relaxation of trial eligibility criteria can and cannot promise: an out-of-sample evaluation, and why reliability was not determined by cohort size alone across the mechanisms examined",{size:20,color:"555555",after:250}));

add(P("All five points are accepted and all five are now implemented. One of them, the third, turned out not to be the question we expected: there were no failed replicates to explain. The explanation we gave for the counts in the last revision was invented, and we set that out below rather than quietly replacing it.",{after:250}));

add(H1("Major comments"));

/* 1 */
add(Q("1. The text still used the ranges for implicit null-hypothesis inference."));
add(P("Accepted. The Methods said no conclusion turns on whether a range covers one half or zero, and then three sentences did exactly that. They are gone."));
add(P("The matched comparison read that each central range “straddles one half, which is the substance of what these cohorts can say”. It now reads that patient resampling produced ranges about a third of the unit interval wide, so the statistic is highly sensitive to which patients happen to be in the cohort, and that no calibrated population-level comparison was performed. The paired rule comparison read that each range “lies on both sides of zero”; it now reports the width, notes that the paired ranges are narrower than the marginal ones, and says that no calibrated comparison of the two rules was performed. The Conclusions sentence and the abstract carry the same wording."));
add(P("On equivalence the claim now rests only on what we did and did not do: no equivalence margin was prespecified and no equivalence test was run, therefore neither an advantage for either rule nor equivalence between them is claimed. Where a range falls plays no part in it."));
W("Where: Abstract; Results §1 and §2; Discussion; Conclusions.");

/* 2 */
add(Q("2. The corrected range needs a separate name from the observed one."));
add(P("Accepted, and the reviewer is right that a slash invites exactly the wrong reading. The two are now in separate columns with different names: OBSERVED PATIENT-RESAMPLED RANGE, which is an empirical quantile of the resampled statistic, and VARIANCE-ADJUSTED SENSITIVITY RANGE (HEURISTIC), which is not — it is the same replicates shrunk toward their mean, matching a second moment, with unknown quantile accuracy and unknown coverage."));
add(P("Tables S3 and S3c now carry five columns: the quantity, then for each cohort the point estimate with the observed range beneath it, and the adjusted range in a column of its own. The notes say in terms which of the two is an empirical quantile and which is a transformation, and that the adjusted one may be either too wide or too narrow. The main text quotes the observed range throughout and never the adjusted one; the adjusted column is supplementary sensitivity and is described as such."));
W("Where: Supplement Tables S3 and S3c.");

/* 3 */
add(Q("3. Explain the two failed outer-bootstrap replicates."));
add(P("There were none, and we should not have said there were. Checking the result objects for this reply: every one of the " + (NS.colon ? NS.colon.B : 150) + " rows in each nested object and every one of the " + (TN ? TN.colon.B : 100) + " rows in each three-way object is finite in every column. No outer replicate failed, none was discarded, and no deletion was data-dependent because no deletion occurred. (Individual inner splits can be unusable within a replicate when a matched comparator or a dominator does not exist, which the supplement already reported; that is a different thing and affects no outer count.)"));
add(P("The counts differ by one for a reason that was in the code and not in the paper. The first outer replicate is not a resample: the loop uses the observed cohort itself at b = 1, and the export holds that row out of the bootstrap distribution and uses it only as the observed-data replicate whose disagreement with the repeated-split estimate Table S3c reports. So " + (NS.colon ? NS.colon.B : 150) + " and " + (TN ? TN.colon.B : 100) + " replicates give " + (NS.colon ? f0(NS.colon.lower.n_outer) : "149") + " and " + (TN ? f0(TN.colon.front_conf.n_outer) : "99") + " bootstrap resamples behind each range."));
add(P("In the last revision we noticed the mismatch between " + (NS.colon ? NS.colon.B : 150) + " and " + (NS.colon ? f0(NS.colon.lower.n_outer) : "149") + ", assumed a failure, and wrote that a replicate had been dropped where the split procedure failed. We did not check, and it was untrue. The Methods and both table notes now give the real reason and say that the earlier statement was wrong. We are grateful the question was asked, because the sentence would otherwise have stood."));
W("Where: Methods, out-of-sample evaluation; Supplement Tables S3 and S3c.");

/* 4 */
add(Q("4. A few phrasings remain too strong or ambiguous."));
add(P("“Separates algorithmic stability from population uncertainty” is replaced by “attempts an approximate decomposition of two sources of variation”, with the observation that for some quantities the patient-level component is not identifiable at the Monte Carlo precision we can afford — which is the same fact the dashes in Table S3c record."));
add(P("The Discussion sentence on information currencies was ambiguous in exactly the way the reviewer describes: the withdrawal clause could be read as attaching to the leave-one-out result rather than to the earlier threshold-conditioned comparison. It is now two sentences, close to the reviewer's wording. The earlier comparison, restricted to the scenarios in which a threshold happened to be observable, is withdrawn, because conditioning on the outcome that way selected the sample; in the full fixed " + (LOSO ? f0(LOSO.n_scenarios) : "16") + "-scenario design the three descriptive summaries were numerically similar under the chosen binning and were not driven by any single scenario. “Robustly” is gone from both the Discussion and Table S2c, replaced by the narrower phrase."));
W("Where: Results §2; Discussion; Supplement Table S2c.");

/* 5 */
add(Q("5. Two textual errors."));
add(P("Both corrected. The abstract's stray punctuation after “equal weight” is removed."));
add(P("The Table S2c bin-edge header was worse than a typo and we thank the reviewer for catching it. The header is generated by rounding each edge to three significant figures; the routine we added in the last revision then stripped trailing zeros from the formatted string, which turns 710 into 71 and would have turned any edge ending in zero into a wrong number. The events edges now read " + (FXD.currency_detail ? FXD.currency_detail.events.edges.map(function(e){return String(Number(Number(e).toPrecision(3)));}).join(", ") : "—") + ", matching the bin labels in the table body, and the header says the edges are given to three significant figures while the labels use R's own formatting."));
W("Where: Abstract; Supplement Table S2c.");

add(new Paragraph({spacing:{before:280},children:[new TextRun({
  text:"Comment 3 is the one we will remember. Faced with a count we could not immediately explain, we supplied a plausible mechanism instead of opening the result file, and the invented explanation then read as a candid disclosure of a limitation. Checking took a few minutes and would have caught it at the time.",
  size:21,font:"Calibri",italics:true})]}));

const doc=new Document({sections:[{properties:{page:{size:{width:12240,height:15840},
  margin:{top:1000,bottom:960,left:1120,right:1120}}},children:body}]});
Packer.toBuffer(doc).then(b=>{fs.writeFileSync("response_to_reviewer_round9.docx",b);
  console.log("written",b.length,"bytes");});
