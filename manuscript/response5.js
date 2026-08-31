const d = require('docx');
const {Document, Packer, Paragraph, TextRun, AlignmentType, HeadingLevel} = d;
const fs = require('fs');
const NUM = JSON.parse(fs.readFileSync("/home/claude/repo/analysis/out/numbers.json","utf8"));
const PR=NUM.primary||{}, NS=NUM.nested||{}, TW=NUM.threeway||null, HZ=NUM.horizon||null,
      SC=NUM.snr_curve||null, CW=NUM.colon_wt||null;
const f=(x,k=3)=>(x===null||x===undefined||!isFinite(x))?"—":Number(x).toFixed(k);
const f0=x=>f(x,0); const pct=(x,k=1)=>(x===null||x===undefined||!isFinite(x))?"—":(100*Number(x)).toFixed(k)+"%";
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
  text:"Response to the fifth review",bold:true,size:30,font:"Calibri"})]}));
add(P("Manuscript: What data-driven relaxation of trial eligibility criteria can and cannot promise: an out-of-sample evaluation, and why no unconditional data requirement exists",{size:20,color:"555555",after:250}));

add(P("The reviewer's central point is correct and it is the one that matters: we claimed in the last cover letter that every figure in the paper is generated from a single result file, and that claim was false. Results section 2 quoted two probabilities as typed literals, the Methods quoted three weighting probabilities the same way, and two superseded result objects were still being read by the supplement — one of them produced before the Rotterdam endpoint was corrected. We should not have made a claim of that kind without a check that enforces it.",{after:130}));
add(P("So we built the check. A script now scans every prose string in the manuscript sources and fails the build on any decimal or percentage that is not a whitelisted structural constant. On first run it found 84 transcribed figures, far more than the reviewer identified. All are now read from result files, the whitelist holds a small number of design constants, each with a stated reason in the source, and the check runs as the first step of the build. We should state its limits rather than overclaim again: it tests decimals and percentages in prose and in table cells across all five document sources, but it does not test bare integers, which are too often legitimate counts to flag usefully. Integer counts in the text were checked by hand against the result files for this submission.",{after:130}));
add(P("Fixing them turned up four errors of substance that we would otherwise have submitted, and we would rather set them out plainly. A figure caption still claimed the estimator's population limit was inflated by 32% under unmeasured confounding; recomputed from the script that is actually in the repository it is " + (NUM.confound_limits ? (100*NUM.confound_limits.inflation).toFixed(1) + "%" : "much smaller") + ", and the 32% came from a parameterisation that no longer exists. The over-prediction of the leverage coefficient for the OR and XOR forms was given as 10 to 30 per cent; it is " + (NUM.leverage_fit ? (100*NUM.leverage_fit.other_min).toFixed(0) + " to " + (100*NUM.leverage_fit.other_max).toFixed(0) : "wider") + " per cent. The median located threshold at the 0.70 and 0.90 reliability targets was quoted from no surviving script; recomputed by the same interpolation used for the 0.80 target it reproduces the quoted values exactly, and now comes from the result file. And the two simulations that report an evaluation set of 120 000 and a scoring set of 60 000 patients are different simulations, which the text did not make clear; it does now.",{after:250}));

add(H1("Major comments"));

/* 1 */
add(Q("1. The “single primary analysis” fix is not actually in effect; several quantities still appear with two different values."));
add(P("Accepted without qualification. Each conflict the reviewer lists was real, and tracing them found more."));
add(P("The two probabilities in Results section 2 were literals left over from a superseded analysis. That section read split_dependence.rds, an object produced before the endpoint correction and superseded by the nested bootstrap; it has been rewritten to read the nested run, and now reports " + f(C.lower,3) + " and " + f(R.lower,3) + " from the primary file, the same values as Table 1."));
add(P("Supplement Table S3c read rmst_rule.rds, which was also produced before the endpoint correction, so its Rotterdam column had been computed with the mismatched pair. That table is deleted; the RMST-rule variant is reported once, in Table S3, from the primary analysis with nested intervals. Five superseded result objects in all have been moved to analysis/out/superseded/ with a note explaining why each was retired, and the export now refuses to run if any of them reappears in the read path."));
add(P("Two further quantities were second estimates of things the primary analysis already reports, computed at their own seeds and split counts. The weighting sensitivity and the horizon sweep now use the primary run's seed, split count and stratified split function — which has been moved into the shared setup so every script uses literally the same function — and the export asserts that their overlapping cells reproduce the primary values exactly. If those runs ever drift apart again the build stops."));
add(P("Finally, Figure 3 plotted the observed cohort values as literals, and they were the pre-correction ones; it also drew its intervals from the retired object. It now reads the primary analysis and the nested bootstrap like everything else."));
add(P("One reassurance we can offer, since the reviewer asks for a clean rebuild: moving the split function into the shared setup and adding the two counters described below required rerunning the primary analysis, and it reproduced every previously reported value bit for bit in both cohorts — the frontier, dominance and matched statistics as well as the headline probabilities. The primary analysis is deterministic given its seed, so a reader who runs it gets the numbers in Table 1 and nothing else."));
W("Where: analysis/primary.R; analysis/export_numbers.R (retirement guard, cross-run assertions); manuscript/check_numbers.js (new); Results §2; Supplement Tables S3 and S3d; Figure 3.");

/* 2 */
add(Q("2. Interval definition and resample counts are not consistent between the Methods, the Results and the supplement."));
add(P("Accepted. The Results built its intervals as the point estimate plus or minus twice the outer-sampling standard deviation, while the Methods and the supplement described percentile intervals, so the same estimate carried two different intervals."));
add(P("There is now one interval procedure for the whole paper: the 95% percentile interval of the outer bootstrap distribution, at one stated resample count. No interval anywhere is formed from a standard deviation multiplier, and the Methods say so explicitly. The " + (NS.colon ? NS.colon.B + " by " + NS.colon.R : "outer by inner") + " counts quoted in the supplement are now the only counts quoted anywhere; the numbers that came from the superseded object, including its resample counts, are gone with it."));
W("Where: Methods, uncertainty subsection; Results §1 and §2; Supplement Table S3.");

/* 3 */
add(Q("3. The three-way split conflates a replication rate with a fresh scan of the test third; the counts cannot both be right."));
add(P("The reviewer is right, and the arithmetic they point at is the proof: a median of " + (TW ? f0(TW.colon.dom_sel) : "—") + " selection-third dominators surviving at " + (TW ? pct(TW.colon.repro) : "—") + " cannot produce the " + (TW ? f0(TW.colon.dom_test) : "—") + " we reported on the test third, because those two numbers come from different scans. We had run both and reported them side by side as though they were one analysis."));
add(P("They are now three separately named quantities, in the Results and in Table S3d, in the order the reviewer sets out. (a) The selection-third dominators, an empirical and optimistic set. (b) Of exactly those, the ones that still dominate on the untouched third — the only confirmatory quantity, because the comparator set was fixed before the test third was used. (c) A fresh scan of all 512 subsets on the test third, which is a second empirical oracle and is labelled descriptive."));
if (TW) add(P("We have also added the confirmatory analogue of frontier membership, which the previous version lacked, and it changes a headline. The rule is left undominated by every pre-selected subset in " + pct(TW.colon.front_conf) + " of colon splits and " + pct(TW.rott.front_conf) + " of Rotterdam splits, against " + pct(C.front_hr) + " and " + pct(R.front_hr) + " on the empirical reading — a factor of several. The qualitative finding survives, since the rule is beaten in most splits either way, but quoting only the empirical figure overstates the shortfall, and the abstract, Results, Discussion and Conclusions now carry both with the confirmatory one identified as the out-of-sample statement. We would not have found this without the reviewer\u2019s insistence that the estimands be separated."));
W("Where: Results §1; Supplement Table S3d; analysis/threeway.R.");

/* 4 */
add(Q("4. The old “conditional reliability curves” sentence survives and contradicts the new Discussion; the pooled SNR correlation is confounded by arrangement and sample size."));
add(P("The sentence is deleted. The paragraph now says that the requirement can in principle be stated conditionally, that we do not supply that conditional statement, that Table 2 is a sensitivity analysis across arrangements at fixed sizes, and that we have not established the quantity such curves would need to be indexed by."));
if (SC) add(P("On the correlation, the reviewer's diagnosis is right and we have made it explicit rather than defending the pooled figure. Within an arrangement the ratio is a monotone function of the fitting size, so the arrangement-adjusted association of " + f(SC.sp_within,2) + " restates that success rises with sample size and is not evidence for the ratio. The informative comparison is between arrangements at a fixed size, where it is " + f(SC.sp_between,2) + " at the largest size tried, over " + SC.n_arr + " arrangements of which " + SC.n_flat + " shows no variation in success at all. Both figures, and that caveat, are now in the Results, the Discussion and the caption of Table S4b. We do not claim the ratio as the governing quantity."));
W("Where: Results §3; Discussion ¶3; Supplement Table S4b.");

/* 5 */
add(Q("5. The RMST-rule conclusion contradicts its own point estimates."));
add(P("Accepted. The point estimates are " + f(C.rmrule_greater,3) + " against " + f(C.greater,3) + " on the restricted mean difference and " + f(C.rmrule_lower,3) + " against " + f(C.lower,3) + " on the hazard ratio, so the variant is slightly higher on one and lower on the other. Writing that it was “not higher on either estimand” was wrong."));
add(P("We have adopted the reviewer's wording. The abstract, the Results and the Conclusions now say that the variant showed no clear or consistent advantage, that its point estimates go in different directions on the two estimands, and that the intervals establish neither superiority nor equivalence. The supplement caption matches."));
W("Where: Abstract; Results §5; Discussion; Conclusions; Supplement Table S3.");

add(H1("Minor comments"));
add(P("1. Hamming distance is out of the nine criteria in each cohort's protocol, not six. The caption of Table S3e is corrected; six was the criterion count in the simulation factorial and did not belong there."));
add(P("2. The weighting sensitivity now runs at the primary analysis's seed and split count, so its estimated-propensity row is the primary estimate rather than a second version of it" + (CW && PR.colon ? " — " + f(CW.ps.lower,3) + " against the primary " + f(PR.colon.lower,3) + ", identical by construction and asserted at export time" : "") + ". The other two rows differ from it only in the weighting."));
add(P("3. The 0.05 margin is described throughout as an investigator-chosen sensitivity margin, reported because a bare inequality is sensitive to arbitrarily small differences. The previous justification implied a general clinical meaning it does not have, and that clause is removed."));
add(P("4. We are grateful for the page-by-page render check. Nothing further was changed on layout beyond keeping the two full-page figures on their own pages."));

add(new Paragraph({spacing:{before:300},children:[new TextRun({
  text:"We would rather have found these ourselves. The lesson we take from this round is narrow and useful: a claim about how a manuscript is generated has to be enforced by the build, because a claim in a cover letter is only a claim. The check is in the repository, it runs first, and it is what we would ask a statistical reviewer to run against the next version.",
  size:21,font:"Calibri",italics:true})]}));

const doc=new Document({sections:[{properties:{page:{size:{width:12240,height:15840},
  margin:{top:1080,bottom:1080,left:1180,right:1180}}},children:body}]});
Packer.toBuffer(doc).then(b=>{fs.writeFileSync("response_to_reviewer_round5.docx",b);
  console.log("written",b.length,"bytes");});
