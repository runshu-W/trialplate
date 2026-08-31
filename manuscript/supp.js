const d = require('docx');
const {Document, Packer, Paragraph, TextRun, AlignmentType, HeadingLevel, Table, TableRow,
       TableCell, WidthType, ShadingType, BorderStyle} = d;
const fs = require('fs');
const NUM = JSON.parse(fs.readFileSync("/home/claude/repo/analysis/out/numbers.json","utf8"));
const FA = NUM.factorial || {}, CN = NUM.concentration || {}, PA = NUM.pareto || {}, FX = (NUM.fixedn||{}).cells || {};
const NS = NUM.nested || {}, FO = NUM.frontier_opt || null, RR = NUM.rmst_rule || null, SNR = NUM.snr || null, CW = NUM.colon_wt || null;
const f = (x,k=3) => (x===null||x===undefined||Number.isNaN(x)) ? "—" : Number(x).toFixed(k);
const f0 = x => f(x,0);
const W = 9360;
const body = []; const add = (...x) => x.forEach(e => Array.isArray(e)?body.push(...e):body.push(e));
const P = (t,o={}) => new Paragraph({spacing:{after:o.after??120, line:o.line??280},
  alignment:o.align??AlignmentType.JUSTIFIED,
  children:[new TextRun({text:t, size:o.size??20, font:o.mono?"Consolas":"Calibri",
                         italics:o.i, bold:o.b, color:o.color})]});
const H1 = t => new Paragraph({heading:HeadingLevel.HEADING_1, spacing:{before:300,after:140},
  children:[new TextRun({text:t, font:"Calibri"})]});
const MONO = t => new Paragraph({spacing:{after:20, line:250}, indent:{left:260},
  children:[new TextRun({text:t, size:17, font:"Consolas", color:"1F3A52"})]});

function table(head, rows, widths, note, sz) {
  const cell = (txt, o={}) => new TableCell({width:{size:o.w,type:WidthType.DXA},
    shading:o.head?{type:ShadingType.CLEAR, fill:"EDF1F5"}:undefined,
    margins:{top:50,bottom:50,left:80,right:80},
    children:[new Paragraph({spacing:{after:0,line:240},
      alignment:o.right?AlignmentType.RIGHT:AlignmentType.LEFT,
      children:[new TextRun({text:String(txt), bold:o.head, size:sz??16, font:"Calibri"})]})]});
  const trs=[new TableRow({tableHeader:true, cantSplit:true,
    children:head.map((h,i)=>cell(h,{w:widths[i],head:true,right:i>0}))})];
  rows.forEach(r=>trs.push(new TableRow({cantSplit:true,
    children:r.map((c,i)=>cell(c,{w:widths[i],right:i>0}))})));
  const out=[new Table({columnWidths:widths, width:{size:W,type:WidthType.DXA}, rows:trs,
    borders:{top:{style:BorderStyle.SINGLE,size:6,color:"9AA4AF"},
             bottom:{style:BorderStyle.SINGLE,size:6,color:"9AA4AF"},
             left:{style:BorderStyle.NONE},right:{style:BorderStyle.NONE},
             insideHorizontal:{style:BorderStyle.SINGLE,size:2,color:"D7DEE5"},
             insideVertical:{style:BorderStyle.NONE}}})];
  out.push(note ? P(note,{size:17,after:240,color:"555555"}) : P("",{after:200}));
  return out;
}

add(new Paragraph({spacing:{after:240}, children:[new TextRun({
  text:"Supplementary material", bold:true, size:30, font:"Calibri"})]}));

/* ---------------- Table S1 ---------------- */
add(H1("Table S1. Criteria, eligibility, missingness and retained information"));
add(P("Marginal eligibility is computed before the missing-as-eligible convention is applied. Events and patients retained are those meeting that criterion alone. The full protocol row is the intersection of all nine."));
add(P("colon: adjuvant colon-cancer trial, Lev+5FU vs observation (n = 619, 304 treated, 291 events)", {b:true, after:80, size:19}));
add(table(["code","definition","eligible","missing","events kept","treated","control"],
[["AGE75","age ≤ 75","0.937","0.000","275","287","293"],
 ["AGE40","age ≥ 40","0.918","0.000","266","278","290"],
 ["NOOBS","no bowel obstruction","0.811","0.000","231","250","252"],
 ["NOPRF","no perforation","0.973","0.000","282","296","306"],
 ["NOADH","not adherent to adjacent organs","0.861","0.000","242","265","268"],
 ["DIFF12","differentiation ≤ 2","0.825","0.021","230","250","263"],
 ["EXT13","extent ≤ 3","0.950","0.000","272","293","295"],
 ["SURG0","short interval since surgery","0.730","0.000","201","228","224"],
 ["NOD4","fewer than 4 positive nodes","0.732","0.000","177","225","228"],
 ["FULL","all nine applied","0.284","—","56","89","87"]],
[900,2860,1000,900,1200,1250,1250],
"Maximum absolute off-diagonal correlation among the eligibility indicators: 0.250 (NOADH with EXT13)."));

add(P("Rotterdam: breast-cancer registry, chemotherapy vs none (n = 2982, 580 treated, 1272 events)", {b:true, after:80, size:19}));
add(table(["code","definition","eligible","missing","events kept","treated","control"],
[["AGE70","age ≤ 70","0.861","0.000","1017","578","1990"],
 ["AGE30","age ≥ 30","0.989","0.000","1257","569","2381"],
 ["ND9","nodes ≤ 9","0.910","0.000","1069","508","2207"],
 ["NDPOS","nodes ≥ 1","0.518","0.000","877","580","966"],
 ["SZ50","tumour size ≤ 50 mm","0.898","0.000","1060","502","2176"],
 ["ERP","ER ≥ 10","0.764","0.000","949","443","1835"],
 ["PGRP","PgR ≥ 10","0.681","0.000","823","428","1603"],
 ["YR85","enrolled ≥ 1985","0.873","0.000","1022","502","2101"],
 ["YR90","enrolled ≤ 1990","0.758","0.000","1068","427","1832"],
 ["FULL","all nine applied","0.141","—","191","203","216"]],
[900,2860,1000,900,1200,1250,1250],
"Maximum absolute off-diagonal correlation: 0.572 (ERP with PGRP); also ND9 with NDPOS at −0.30 and SZ50 with NDPOS at −0.23. Rotterdam has no missingness on any criterion variable."));

/* ---------------- Table S1b: PS diagnostics ---------------- */
add(H1("Table S1b. Propensity-score behaviour inside the full protocol"));
add(table(["specification","cohort","max |SMD|","covariates > 0.10","ESS","truncated","n retained"],
[["M1 main effects, unstabilised, truncated (main analysis)","colon","0.011","0 of 5","172","0","176"],
 ["M2 + natural splines on continuous covariates","colon","0.026","0 of 5","166","0","176"],
 ["M3 + stabilised weights","colon","0.026","0 of 5","166","0","176"],
 ["M4 + trimming to common support","colon","0.058","0 of 5","165","0","172"],
 ["M1 main effects, unstabilised, truncated (main analysis)","Rotterdam","0.251","6 of 8","155","132","419"],
 ["M2 + natural splines on continuous covariates","Rotterdam","0.413","6 of 8","138","181","419"],
 ["M3 + stabilised weights","Rotterdam","0.413","6 of 8","139","181","419"],
 ["M4 + trimming to common support","Rotterdam","0.215","5 of 8","111","181","338"]],
[3300,1100,1000,1300,800,1000,860],
"Four covariates in colon are fixed by the criteria themselves inside the full protocol and carry no balance information. No specification restores balance in Rotterdam; splines make it worse. Of 116 full-protocol Rotterdam patients aged 55 to 70, 12 received chemotherapy; 175 of 203 treated patients are premenopausal against 45 of 216 controls."));

/* ---------------- Table S1c: overlap vs restriction ---------------- */
add(H1("Table S1c. Overlap does not degrade with restriction"));
add(P("Median over all subsets of each size, across the full 2⁹ enumeration in each cohort. If restriction created the positivity problem, the effective-sample-size fraction would fall from left to right. It does not."));
add(table(["criteria applied","colon: median n","colon: ESS/n","Rotterdam: median n","Rotterdam: ESS/n","Rotterdam: truncated","Rotterdam: max |SMD|"],
[["0","619","0.989","2982","0.374","0.397","0.465"],
 ["2","458","0.985","1968","0.383","0.366","0.436"],
 ["4","341","0.981","1266","0.381","0.309","0.327"],
 ["6","257","0.977","694","0.380","0.294","0.252"],
 ["9","176","0.976","419","0.369","0.315","0.251"]],
[1500,1300,1200,1500,1400,1300,1160]));

/* ---------------- Table S2: factorial ---------------- */
add(H1("Table S2. Threshold across the fractional factorial"));
if (FA.table && FA.table.length) {
  const rows = FA.table.map(r => [
    String(r.run), String(r.p), f(r.retain,2), String(r.nmod), f(r.gmag,2),
    f(r.crate,3), f(r.alloc,2), (r.conf===true||r.conf==="true") ? "yes" : "no",
    r.cens==="right" ? "> 18 000" : r.cens==="left" ? "< 600" : f0(r.n_star),
    (r.n_lo===null||r.n_hi===null) ? "—" : f0(r.n_lo)+"–"+f0(r.n_hi),
    r.ev_star===null ? "—" : f0(r.ev_star),
    r.ess_star===null ? "—" : f0(r.ess_star)]);
  add(table(["run","p","retain","mod","|γ|","cens","alloc","conf","n*","95% CI","events*","ESS*"],
    rows, [560,520,760,560,620,700,700,620,900,1400,900,1120],
    "n* is the fitting-cohort size at which the probability of a lower out-of-sample hazard ratio crosses 0.80, located by interpolation with a bootstrap interval over replicates. events* and ESS* are the corresponding full-protocol event count and weighted effective sample size. “> 18 000” marks a scenario in which the probability never reached 0.80 anywhere on the ladder; “< 600” one in which it was already above 0.80 at the smallest size, which happens where the full protocol retains so few events that it is the imprecise comparator. Both are excluded from the spread statistics below. mod is the number of criteria carrying effect modification: 2 concentrates it, 5 spreads it.", 15));
  add(P("Of the 16 scenarios, " + FA.n_complete + " located a threshold, " + FA.n_right + " were right-censored at 18 000 fitting patients and " + FA.n_left + " left-censored below 600. Among those located, the spread is: fitting patients " + f0(FA.n_min) + " to " + f0(FA.n_max) + " (coefficient of variation " + f(FA.cv_n,2) + "); full-protocol events " + f0(FA.ev_min) + " to " + f0(FA.ev_max) + " (" + f(FA.cv_ev,2) + "); effective sample size " + f0(FA.ess_min) + " to " + f0(FA.ess_max) + " (" + f(FA.cv_ess,2) + "). Neither information currency is more stable than the patient count."));
  const BY = FA.by || {};
  add(P("Completion by factor level (8 runs each):", {b:true, after:60, size:19}));
  add(table(["factor","level","threshold located","right-censored","median n* where located"],
    [["criteria p","6", String(BY.p_6.complete), String(BY.p_6.right), BY.p_6.med_n===null?"—":f0(BY.p_6.med_n)],
     ["criteria p","8", String(BY.p_8.complete), String(BY.p_8.right), BY.p_8.med_n===null?"—":f0(BY.p_8.med_n)],
     ["full-protocol retention","0.30", String(BY["retain_0.3"].complete), String(BY["retain_0.3"].right), BY["retain_0.3"].med_n===null?"—":f0(BY["retain_0.3"].med_n)],
     ["full-protocol retention","0.12", String(BY["retain_0.12"].complete), String(BY["retain_0.12"].right), BY["retain_0.12"].med_n===null?"—":f0(BY["retain_0.12"].med_n)],
     ["effect modification","concentrated (2 criteria, |γ| 0.40)", String(BY.nmod_2.complete), String(BY.nmod_2.right), BY.nmod_2.med_n===null?"—":f0(BY.nmod_2.med_n)],
     ["effect modification","diffuse (5 criteria, |γ| 0.16)", String(BY.nmod_5.complete), String(BY.nmod_5.right), BY.nmod_5.med_n===null?"—":f0(BY.nmod_5.med_n)],
     ["censoring rate","0.020", String(BY["crate_0.02"].complete), String(BY["crate_0.02"].right), BY["crate_0.02"].med_n===null?"—":f0(BY["crate_0.02"].med_n)],
     ["censoring rate","0.180", String(BY["crate_0.18"].complete), String(BY["crate_0.18"].right), BY["crate_0.18"].med_n===null?"—":f0(BY["crate_0.18"].med_n)],
     ["allocation","1:1", String(BY["alloc_0.5"].complete), String(BY["alloc_0.5"].right), BY["alloc_0.5"].med_n===null?"—":f0(BY["alloc_0.5"].med_n)],
     ["allocation","1:3", String(BY["alloc_0.25"].complete), String(BY["alloc_0.25"].right), BY["alloc_0.25"].med_n===null?"—":f0(BY["alloc_0.25"].med_n)],
     ["assignment","randomised", String(BY.conf_FALSE.complete), String(BY.conf_FALSE.right), BY.conf_FALSE.med_n===null?"—":f0(BY.conf_FALSE.med_n)],
     ["assignment","confounded, adjusted", String(BY.conf_TRUE.complete), String(BY.conf_TRUE.right), BY.conf_TRUE.med_n===null?"—":f0(BY.conf_TRUE.med_n)]],
    [2100,3000,1600,1500,1160],
    "Only the effect-modification factor separates the design: every scenario with diffuse modification failed to reach 0.80 anywhere on the ladder, under every combination of the other five factors.", 16));
} else { add(P("[Factorial table pending completion of the simulation.]")); }

/* ---------------- Text S1 ---------------- */
add(H1("Table S2b. Threshold analysis without conditioning on an observable threshold"));
add(P("The threshold estimates in Table S2 are censored in ten of sixteen scenarios, so summarising only the six that are observable conditions on the outcome. Two analyses that do not. First, an interval-censored lognormal accelerated-failure-time regression of the threshold on the six factors, in which right-censored runs contribute (18 000, infinity) and the left-censored run (0, 600): the effect-modification factor completely separates the design — all eight diffuse runs are right-censored — so its coefficient is unbounded and not estimable, and the remaining terms are estimated from six exact observations with intervals spanning one to two orders of magnitude. Second, the sensitivity of the pattern to the 0.80 reliability target."));
add(table(["reliability target","threshold located","right-censored","left-censored","median located n*","concentrated located","diffuse located"],
 [["0.70","7","8","1","2 000","6 of 8","1 of 8"],
  ["0.80","6","9","1","3 265","6 of 8","0 of 8"],
  ["0.90","6","10","0","4 811","6 of 8","0 of 8"]],
 [1700,1500,1400,1300,1500,1500,1460],
 "The separation by effect-modification arrangement is unchanged across targets, so nothing in the main text depends on the choice of 0.80."));

add(H1("Table S3. Matched and frontier comparison, with patient-level uncertainty"));
add(P("All 512 subsets are scored on the held-out half of each split. “Matched” keeps those whose eligible count is within the stated tolerance of the rule's. “On the frontier” means no scored subset admits at least as many patients at a hazard ratio at least as low. The proportion is computed within a split and splits are averaged with equal weight; intervals come from the outer bootstrap over patients, not from resampling splits. Rotterdam entries are descriptive, that cohort having a severe lack of empirical overlap."));
if (NS.colon) { const C=NS.colon, RT=NS.rott;
  const row = (lab, key) => [lab,
    f(C[key].point,3)+" ["+f(C[key].ci[0],2)+", "+f(C[key].ci[1],2)+"]",
    f(RT[key].point,3)+" ["+f(RT[key].ci[0],2)+", "+f(RT[key].ci[1],2)+"]"];
  add(table(["quantity","colon","Rotterdam (descriptive)"],
   [["outer resamples x inner splits", C.B+" x "+C.R, RT.B+" x "+RT.R],
    row("P(more eligible)","more"), row("P(lower hazard ratio)","lower"),
    row("matched on HR, band 2%","hr0.02"), row("matched on HR, band 5%","hr0.05"),
    row("matched on HR, band 10%","hr0.1"), row("matched on HR, band 15%","hr0.15"),
    row("matched on RMST, band 10%","rm0.1"),
    row("on count/HR frontier","front_hr"), row("on count/RMST frontier","front_rm"),
    row("on frontier with margin "+f(C.margin,2),"front_hrM"),
    ["matched comparators per split (median)", f0(C["nm0.1"]), f0(RT["nm0.1"])],
    ["comparator count skew vs rule", f(C["sk0.1"],3), f(RT["sk0.1"],3)],
    ["subsets dominating (median)", f0(C.n_dom), f0(RT.n_dom)]],
   [3600, 2900, 2860],
   "Point estimates are from the observed cohort; SD is decomposed as SD_outer = sqrt(SD_total^2 - SD_MC^2) in the main text. Intervals are percentile intervals of the outer distribution and are exploratory at these resample counts.")); }

add(H1("Table S3b. Optimism of the empirical held-out frontier"));
add(P("The frontier is selected from the same held-out data on which it is evaluated, so it is an argmax over 512 noisy estimates. In simulation the population is known and the optimism can be measured directly, at a held-out half the size of a colon scoring set."));
if (FO) add(table(["quantity","judged on a held-out half","judged at the population"],
 [["subsets dominating the rule (median)", f0(FO.dom_emp), f0(FO.dom_pop)],
  ["rule on the frontier", f(FO.front_emp,3), f(FO.front_pop,3)],
  ["of subsets dominating on half A, share still dominating on an independent half B", f(FO.repro,3), "—"],
  ["of subsets dominating on half A, share genuinely dominating at the population", "—", f(FO.true_frac,3)]],
 [4600, 2400, 2360],
 "Roughly four in five apparently dominating subsets do not dominate at the population, and the empirical frontier understates the rule's true frontier membership by about a factor of two."));

add(H1("Table S3c. Selecting on the absolute-benefit estimand instead"));
add(P("The published rule decomposes the log hazard ratio. This variant retains every criterion whose Shapley value on the restricted mean difference is positive, and is scored out of sample on both estimands."));
if (RR) add(table(["quantity","colon","Rotterdam (descriptive)"],
 [["the two rules select the same criterion set", f(RR.colon.same,3), f(RR.rott.same,3)],
  ["eligible: full protocol", f0(RR.colon.n_full), f0(RR.rott.n_full)],
  ["eligible: HR-selected rule", f0(RR.colon.n_hr), f0(RR.rott.n_hr)],
  ["eligible: RMST-selected rule", f0(RR.colon.n_rm), f0(RR.rott.n_rm)],
  ["HR-selected rule: P(lower HR)", f(RR.colon.hr_lowerHR,3), f(RR.rott.hr_lowerHR,3)],
  ["HR-selected rule: P(greater RMST)", f(RR.colon.hr_moreRM,3), f(RR.rott.hr_moreRM,3)],
  ["RMST-selected rule: P(lower HR)", f(RR.colon.rm_lowerHR,3), f(RR.rott.rm_lowerHR,3)],
  ["RMST-selected rule: P(greater RMST)", f(RR.colon.rm_moreRM,3), f(RR.rott.rm_moreRM,3)]],
 [4200, 2600, 2560],
 "Switching the decomposition to the absolute-benefit estimand changes the selected criteria almost completely and improves neither estimand out of sample."));

add(H1("Table S4. Arrangement of the effect modification, total held fixed"));
add(P("Total modification is 0.85 in every row. Rows A to C hold the diluting coefficient at 0.30 and spread the enrichment over one, two and four criteria. Row D holds the enrichment in one criterion and splits the dilution across two, halving the coefficient the rule has to detect. Entries are the probability of a lower out-of-sample hazard ratio; the scoring set is fixed at 60 000 patients."));
if (CN.A_dil1_enr1) {
  const row = (k, lab) => [lab, f(Math.max(...CN[k].rows.map(r=>0)) || 0.30, 2)].concat(CN[k].rows.map(r=>f(r.p_lower,2)));
  add(table(["arrangement","largest diluting coefficient","600","2 000","6 000","18 000"],
   [["A  dilution in 1, enrichment in 1", "0.30"].concat(CN.A_dil1_enr1.rows.map(r=>f(r.p_lower,2))),
    ["B  dilution in 1, enrichment in 2", "0.30"].concat(CN.B_dil1_enr2.rows.map(r=>f(r.p_lower,2))),
    ["C  dilution in 1, enrichment in 4", "0.30"].concat(CN.C_dil1_enr4.rows.map(r=>f(r.p_lower,2))),
    ["D  dilution in 2, enrichment in 1", "0.15"].concat(CN.D_dil2_enr1.rows.map(r=>f(r.p_lower,2)))],
   [3400, 2000, 1200, 1200, 1300, 1260],
   "Spreading the enrichment (A to C) leaves success unchanged or slightly improved; halving the diluting coefficient (A against D) reduces it from 0.85 to 0.43 at the largest size. Monte Carlo standard error is at most 0.065."));
}

add(H1("Figure S3. Propensity distributions inside the full protocol"));
add(P("Estimated propensity scores by treatment arm within the full protocol of each cohort, with the 0.05 and 0.95 truncation bounds marked and the common-support region indicated. The Rotterdam panel shows the near-separation that makes its weighted estimates descriptive rather than causal."));
add(new Paragraph({spacing:{after:200}, alignment:AlignmentType.CENTER,
  children:[new d.ImageRun({data: fs.readFileSync("/home/claude/repo/figures/fig_overlap.png"),
    type:"png", transformation:{width:620, height:248}})]}));

add(H1("Text S1. Complete specification of every generating mechanism"));
add(P("No parameter below was estimated from either cohort. All were set a priori. Z denotes a vector of independent standard normal covariates, A the treatment indicator, and E the vector of eligibility indicators.", {after:160}));

add(P("S1.1 Training-size sweep (Figure 3)", {b:true, after:70}));
MONO && add(MONO("p = 8 criteria; per-criterion retention (0.85, 0.75, 0.70, 0.90, 0.80, 0.85, 0.75, 0.90)"));
add(MONO("Z_k ~ N(0,1), k = 1..8, independent      threshold_k = Phi^-1(retention_k)"));
add(MONO("E_k = 1{ Z_k <= threshold_k }            A ~ Bernoulli(0.5)"));
add(MONO("gamma = (-0.35, -0.25, +0.30, 0, 0, 0, 0, 0)   [criteria 1,2 enrich; 3 dilutes]"));
add(MONO("linear predictor  eta = log(0.75)*A + sum_k 0.55*Z_k + A * sum_k gamma_k * E_k"));
add(MONO("T ~ Exponential(rate = 0.20 * exp(eta))  C ~ Exponential(rate = 0.05)"));
add(MONO("observed time = min(T, C), event = 1{T <= C}   tau = 8, min per arm = 3"));
add(P("Fitting sizes 300, 1000, 3000, 5167 and 20 000 with 300 replicates each; scoring set fixed at 100 000 patients generated once with seed 999; population reference enumerated at N = 300 000.", {after:170}));

add(P("S1.2 Three assignment arms (Figure 4)", {b:true, after:70}));
add(MONO("Outcome model identical to S1.1 in all three arms."));
add(MONO("arm A  randomised            A ~ Bernoulli(0.5)"));
add(MONO("arm B  confounded, adjusted  A ~ Bernoulli( logit^-1( Z . alpha ) ),"));
add(MONO("                             alpha = (0.6, 0.5, 0.4, 0, 0, 0, 0, 0)"));
add(MONO("                             propensity model uses V1..V8"));
add(MONO("arm C  one confounder unmeasured: assignment as arm B,"));
add(MONO("                             propensity model uses V2..V8 only"));
add(P("250 replicates per cell at fitting sizes 1000, 3000, 5167 and 20 000. Because the outcome model is common, the true causal contrast is identical in all three arms; what differs across arms is the population limit of the weighted estimator.", {after:170}));

add(P("S1.3 Non-collapsibility sweep (Figure 5)", {b:true, after:70}));
add(MONO("N = 300 000, tau = 5, conditional log hazard ratio bA = log(0.6)"));
add(MONO("Z ~ N(0,1)   A ~ Bernoulli(0.5)"));
add(MONO("T ~ Exponential(rate = 0.25 * exp(bA*A + bZ*Z)),  bZ swept over"));
add(MONO("   0, 0.3, 0.6, 0.9, 1.2, 1.5, 1.8"));
add(MONO("criterion under study: Z <= 0 (retains half the cohort)"));
add(P("The conditional hazard ratio is exp(bA) = 0.6 in every stratum of Z at every point on the sweep, so the criterion changes no individual's relative benefit. bZ = 0 is the falsification point: with no prognostic heterogeneity there is nothing to collapse over and the artefact must vanish.", {after:170}));

add(P("S1.4 Fractional factorial over the threshold (Table S2)", {b:true, after:70}));
add(MONO("2^(6-2) resolution IV, generators E = ABC and F = ABD, 16 runs."));
add(MONO("A  number of criteria p                6        vs  10"));
add(MONO("B  full-protocol retention             0.30     vs  0.12"));
add(MONO("   per-criterion retention = retention^(1/p)"));
add(MONO("C  effect modification    sparse: gamma_1 = -|g|, gamma_3 = +0.80|g|"));
add(MONO("                          dense : gamma_1..5 = -|g|, -0.75|g|, +0.80|g|,"));
add(MONO("                                                -0.50|g|, +0.40|g|"));
add(MONO("   |g| = 0.40 (sparse, strong)  vs  0.16 (dense, weak)"));
add(MONO("D  censoring rate                      0.020    vs  0.180"));
add(MONO("E  allocation P(A=1)                   0.50     vs  0.25"));
add(MONO("F  assignment    randomised  vs  A ~ Bern(logit^-1(logit(alloc)+0.45(Z1+Z2)))"));
add(MONO("                             with the propensity model using all of V1..Vp"));
add(MONO("prognostic strength 0.55 per covariate; baseline rate 0.20; tau = 8"));
add(MONO("ladder 600, 2000, 6000, 18 000 fitting patients"));
add(MONO("replicates 100, 100, 70, 50 respectively; scoring set 60 000, fixed per run"));
add(P("Every scenario contains at least one diluting criterion, because relaxation can lower the hazard ratio only if some retained criterion selects patients who benefit less. A rung on which more than half the replicates encountered an infeasible subset is dropped rather than reported as a low probability. The crossing is located by linear interpolation of the probability against log fitting size between the two bracketing rungs, and its interval by resampling the replicate indicators 400 times.", {after:170}));

add(P("S1.5 Interaction-leverage verification", {b:true, after:70}));
add(MONO("p = 4 criteria; criteria 1 and 2 at the stated eligibility rate q,"));
add(MONO("criteria 3 and 4 at 0.85; g = -0.60; N = 40 000; prognostic 0.20;"));
add(MONO("baseline rate 0.20; censoring 0.03; tau = 8"));
add(MONO("bonus indicator  AND: E1 & E2    OR: E1 | E2    XOR: E1 xor E2"));
add(MONO("eta = log(0.80)*A + sum_k 0.20*Z_k + g * A * bonus"));
add(P("Under independent criteria at a common rate q the coefficients multiplying g are (1−q)² for the AND form, −(1−q)² for OR and −2(1−q)² for XOR.", {after:170}));

add(H1("Figure S1. Full-page study design"));
add(P("Figure 1 of the main text at full width.", {after:120}));
add(new Paragraph({spacing:{after:200}, alignment:AlignmentType.CENTER,
  children:[new d.ImageRun({data: fs.readFileSync("/home/claude/repo/figures/fig_design.png"),
    type:"png", transformation:{width:660, height:336}})]}));

add(H1("Figure S2. Full-page criteria plate plot"));
add(P("The colon criteria plate plot at full page size, reproducing Figure 6 of the main text.", {after:120}));
add(new Paragraph({spacing:{after:100}, alignment:AlignmentType.CENTER,
  children:[new d.ImageRun({data: fs.readFileSync("/home/claude/repo/figures/fig2_plate3.png"),
    type:"png", transformation:{width:600, height:713}})]}));

const doc = new Document({sections:[{properties:{page:{size:{width:12240,height:15840},
  margin:{top:1000,bottom:1000,left:1080,right:1080}}}, children: body}]});
Packer.toBuffer(doc).then(b => { fs.writeFileSync("supplement.docx", b);
  console.log("supplement written", b.length, "bytes"); });
