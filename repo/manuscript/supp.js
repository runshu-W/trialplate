/* The provenance check runs before this document is written, so the supplement
 * is gated the same way the manuscript is. */
require("child_process").execFileSync(process.execPath, [__dirname + "/check_numbers.js"],
  { stdio: "inherit", cwd: __dirname });

const d = require('docx');
const {Document, Packer, Paragraph, TextRun, AlignmentType, HeadingLevel, Table, TableRow,
       TableCell, WidthType, ShadingType, BorderStyle} = d;
const fs = require('fs');
const NUM = JSON.parse(fs.readFileSync("/home/claude/repo/analysis/out/numbers.json","utf8"));
const FA = NUM.factorial || {}, CN = NUM.concentration || {}, PA = NUM.pareto || {}, FX = (NUM.fixedn||{}).cells || {};
const TG = NUM.targets || null, TIE = NUM.ties || null;
const CV = NUM.converge || null;
const CUR = (NUM.fixedn||{}).currency_detail || null, LOSO = (NUM.fixedn||{}).currency_loso || null;
const CRIT = NUM.criteria || null, OVL = NUM.overlap || null, PSX = NUM.ps_specs || null;
const CFACT = NUM.cohort_facts || null, CD = NUM.conc_diff || null;
const PR = NUM.primary || {}, NS = NUM.nested || {}, FO = NUM.frontier_opt || null;
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
add(P("Marginal eligibility is computed before the missing-as-eligible convention is applied. The note under each block gives the largest absolute off-diagonal correlation among the eligibility indicators; the full matrix for each cohort is Table S1f. Events retained are the total meeting that criterion alone; treated and control are patients, not events. The full protocol row is the intersection of all nine."));
/* Reviewer round 5. This table was a typed copy of analysis/out/cohort_tables.txt.
   It is now generated from the same result file as everything else. */
if (CRIT) {
  const blk = (key, esc) => {
    const H = CRIT.head[key], rows = CRIT.rows.filter(r => r.cohort === key);
    add(P(H.label + " (n = " + f0(H.n) + ", " + f0(H.treated) + " treated, " + f0(H.events) + " events)",
          {b:true, after:80, size:19}));
    add(table(["code","definition","eligible","missing","events kept","treated","control"],
      rows.map(r => [r.code, r.definition, f(r.eligible,3), f(r.missing,3),
                     f0(r.events), f0(r.treated), f0(r.control)])
        .concat([["FULL","all nine applied", f(H.full_frac,3), "\u2014",
                  f0(H.full_events), f0(H.full_treated), f0(H.full_control)]]),
      [900,2860,1000,900,1200,1250,1250], esc));
  };
  blk("colon", "Maximum absolute off-diagonal correlation among the eligibility indicators: " +
      (CFACT && CFACT.colon ? f(Math.abs(CFACT.colon.max_cor),3) + " (" + CFACT.colon.max_cor_pair + ")" : "\u2014") + ".");
  blk("rott", "Maximum absolute off-diagonal correlation: " +
      (CFACT && CFACT.rott ? f(Math.abs(CFACT.rott.max_cor),3) + " (" + CFACT.rott.max_cor_pair + ")" : "\u2014") +
      ". Rotterdam has no missingness on any criterion variable.");
}

/* ---------------- Table S1b: PS diagnostics ---------------- */
add(H1("Table S1b. Propensity-score behaviour inside the full protocol"));
if (PSX) {
  const SPEC = {M1:"M1 main effects, unstabilised, truncated (main analysis)",
                M2:"M2 + natural splines on continuous covariates",
                M3:"M3 + stabilised weights",
                M4:"M4 + trimming to common support"};
  const order = ["colon (randomised)","Rotterdam (registry)"];
  const rows = [];
  order.forEach(coh => ["M1","M2","M3","M4"].forEach(sp => {
    const z = PSX[coh + " " + sp]; if (!z) return;
    rows.push([SPEC[sp], coh.split(" ")[0], f(z.max_smd,3),
               f0(z.n_above_10) + " of " + f0(z.n_cov === undefined ? (coh[0]==="c" ? 5 : 8) : z.n_cov),
               f0(z.ess), f0(z.n_trunc), f0(z.n_kept)]);
  }));
  add(table(["specification","cohort","max |SMD|","covariates > 0.10","ESS","truncated","n retained"],
    rows, [3300,1100,1000,1300,800,1000,860],
    "Covariates fixed by the criteria themselves inside the full protocol carry no balance information and are excluded from the count. No specification restores balance in Rotterdam."));
}

/* ---------------- Table S1c: overlap vs restriction ---------------- */
add(H1("Table S1c. Overlap declines only slightly with restriction"));
add(P("Median over all subsets of each size, across the full 2\u2079 enumeration in each cohort. If restriction created the positivity problem, the effective-sample-size fraction would fall substantially as criteria are added. It does fall, but by a small amount and not at every step: in colon it runs from " + (OVL ? f(OVL.colon[0].ess_frac,3) : "\u2014") + " at no criteria to " + (OVL ? f(Math.min.apply(null, OVL.colon.map(r=>r.ess_frac)),3) : "\u2014") + " at its lowest and back to " + (OVL ? f(OVL.colon[OVL.colon.length-1].ess_frac,3) : "\u2014") + " with all nine applied, and in Rotterdam it rises over the first few steps before drifting down. The size of the movement is the point, not its direction."));
if (OVL) {
  const sizes = OVL.colon.map(r => r.size);
  add(table(["criteria applied","colon: median n","colon: ESS/n","Rotterdam: median n","Rotterdam: ESS/n","Rotterdam: truncated","Rotterdam: max |SMD|"],
    sizes.map((sz, k) => [f0(sz), f0(OVL.colon[k].n), f(OVL.colon[k].ess_frac,3),
      f0(OVL.rott[k].n), f(OVL.rott[k].ess_frac,3),
      f(OVL.rott[k].trunc,3),
      f(OVL.rott[k].maxsmd,3)]),
    [1600,1300,1200,1500,1400,1300,1400],
    "The effective-sample-size fraction declines only slightly as criteria are added — " + (OVL ? "in colon from " + f(OVL.colon[0].ess_frac,3) + " to " + f(OVL.colon[OVL.colon.length-1].ess_frac,3) + " across the full range" : "") + " — rather than falling as it would if restriction were creating the problem, so restriction is not what creates the lack of overlap in Rotterdam."));
}

/* ---------------- Table S1d: comparator set and ties ---------------- */
add(H1("Table S1d. The comparator set, and how often a comparator ties the rule"));
add(P("The matched comparison scores all 512 subsets on the held-out half and keeps those whose eligible count is within the stated tolerance of the rule's. The rule's own subset is excluded, so the reported proportion is over strictly other protocols. All comparisons are strict inequalities, so a subset that exactly ties the rule on the hazard ratio or the restricted mean counts against the rule rather than for it. We stated in an earlier version that ties were negligible without measuring them; they are measured here."));
if (TIE) add(table(["quantity","colon","Rotterdam"],
 [["splits", f0(TIE.colon.splits), TIE.rott ? f0(TIE.rott.splits) : "\u2014"],
  ["matched comparators per split (mean)", f(TIE.colon.comparators,1), TIE.rott ? f(TIE.rott.comparators,1) : "\u2014"],
  ["comparators tying the rule exactly on the hazard ratio", f(TIE.colon.tie_frac_hr,5), TIE.rott ? f(TIE.rott.tie_frac_hr,5) : "\u2014"],
  ["comparators tying the rule exactly on the restricted mean", f(TIE.colon.tie_frac_rm,5), TIE.rott ? f(TIE.rott.tie_frac_rm,5) : "\u2014"],
  ["splits with at least one hazard-ratio tie", f(TIE.colon.splits_with_tie_hr,3), TIE.rott ? f(TIE.rott.splits_with_tie_hr,3) : "\u2014"]],
 [5000,2200,2160],
 "Ties arise when two criterion subsets select the same patients on the scoring half, which happens when a criterion is non-binding there. Ties were counted over the split count in the first row of this table rather than over the " + f0(PR.colon.R) + " and " + f0(PR.rott.R) + " splits behind Table S3, in both cohorts, so the tie fraction here is an estimate of the fraction there and not the same computation; reversing the convention would move the matched proportions by about the tie fraction given above. The mean comparator count in this table is computed over the same shorter run, which is why it differs slightly from the corresponding row of Table S3."));

/* ---------------- Table S1e: split-count convergence ----------------
   Reviewer round 7, major 1. An earlier version of this table reported only
   s/sqrt(R), which is an identity once s is fixed and therefore evidence for
   nothing. It now also reports the observed spread of independent R-split
   estimates, obtained by cutting the long run into disjoint blocks of R splits. */
add(H1("Table S1e. How the split-count estimator behaves as the split count grows"));
add(P("The nested bootstrap takes a limited number of inner splits inside each resample, so what it resamples is a split-count estimator noisier than the one the paper reports as its point estimate. The spread it observes therefore carries the inner Monte Carlo variance as well as the variability from resampling patients. One thing should be said before the table, because it settles what kind of difference this is. Each of these quantities is an average over independent splits, so changing the split count changes the variance of the estimator and not its expectation: the 25-split estimator and the 400-split estimator are estimates of the same thing, one noisier than the other. The bootstrap therefore resamples a noisier version of the reported statistic, not a different statistic, and the excess is variance. What this table can do is put a size on that variance. What it cannot do is validate the correction Tables S3 and S3c report, and we say what it does not reach at the end of this section."));
if (CV) {
  add(P("The table quantifies that variance two ways. The first is the standard deviation implied by the per-split spread, s divided by the square root of R; that is an identity once s is known, so on its own it establishes nothing. The second is an observed quantity: each run \u2014 500 splits for the two-way quantities, 400 for the three-way, matching the runs behind the point estimates \u2014 is cut into disjoint blocks of R consecutive splits, each block giving an independent R-split estimate, and the standard deviation of those block estimates is reported beside the implied value. If the two agree, the variance law s/sqrt(R) describes these estimators on these data."));
  const label = {lower:"P(lower hazard ratio)", "hr0.1":"matched on HR, band 10%",
                 front_hr:"rule on the count/HR frontier",
                 repro:"replication rate (three-way)",
                 front_conf:"undominated by pre-selected (three-way)",
                 best_holds:"lowest-HR dominator carries over (three-way)"};
  /* The two designs run to different lengths — 500 splits for the two-way
     quantities, 400 for the three-way — so the ladder columns stop at the largest
     count both share and each row's own full run gets a column of its own. */
  const get = (q, R) => CV.rows.filter(r => r.quantity === q && r.R === R)[0];
  const keys = Object.keys(label).filter(q => CV.rows.some(r => r.quantity === q));
  const rmax = q => Math.max.apply(null, CV.rows.filter(r => r.quantity === q).map(r => r.R));
  const shared = CV.counts.filter(c => keys.every(q => rmax(q) > c));
  const cell = z => {
    if (!z) return "—";
    const obs = (z.blk_sd !== undefined && z.blk_sd !== null && isFinite(z.blk_sd) && z.blk_n >= 2)
      ? f(z.blk_sd,3) + " (" + f0(z.blk_n) + ")" : "—";
    return f(z.mc_sd,3) + " / " + obs;
  };
  add(table(["quantity","per-split SD"].concat(shared.map(c => "R = " + f0(c))).concat(["full run"]),
    keys.map(q => [label[q], f(get(q, shared[0]).per_split_sd,3)]
      .concat(shared.map(c => cell(get(q, c))))
      .concat([f(get(q, rmax(q)).mc_sd,3) + " (R = " + f0(rmax(q)) + ")"])),
    [2600, 1000].concat(shared.map(() => 900)).concat([1360]),
    "Colon cohort. Each ladder cell gives the implied Monte Carlo standard deviation s/√R, then after the slash the observed standard deviation of the independent block estimates with the number of blocks in parentheses. The last column is each quantity's own full run, which does not divide into two or more blocks and so carries no observed spread; a dash after the slash in this table means only that, and is unrelated to the dash in Tables S3 and S3c, which marks a non-identifiable variance component. The observed spread is itself imprecise where the blocks are few: a standard deviation from two to five blocks carries one to four degrees of freedom and can sit well above or below the implied value without meaning anything. It is the columns with many blocks that carry the comparison, and there the observed spread runs between about seven tenths and about one and a tenth times the implied value; across the whole table the ratio runs from about six tenths to about two and a half, the largest disagreements being on the three-way frontier quantity and in the columns with fewest blocks. Where the implied value is the larger, the correction removes more variance than the blocks show. We do not translate that into a direction for coverage, because as the last paragraph of this section says, a statement about second moments does not determine the coverage of a shrunken quantile; it is a reason the observed range is always printed beside the corrected one. A few splits are unusable, so a column can rest on slightly fewer than its nominal count; the count actually behind each cell is in the result file."));
  /* The estimates themselves, kept in a second table so the dispersion table above
     is not read as a trend in the point estimate. */
  add(table(["quantity"].concat(shared.map(c => "R = " + f0(c))).concat(["full run"]),
    keys.map(q => [label[q]]
      .concat(shared.map(c => { const z = get(q, c); if (!z) return "—";
        return f(z.mean,3) + ((z.blk_mean !== undefined && z.blk_mean !== null && isFinite(z.blk_mean) && z.blk_n >= 2) ? " / " + f(z.blk_mean,3) : ""); }))
      .concat([f(get(q, rmax(q)).mean,3)])),
    [2600].concat(shared.map(() => 1000)).concat([1160]),
    "Estimates, not dispersions. The first number in each cell is the estimate from the first R splits of the run — a single realisation, which wanders; the second, where there are at least two blocks, is the average of the independent block estimates. That average is nearly constant in R — it equals the whole-run value exactly when the blocks use every usable split, and differs by the leftover splits otherwise, which is why the three-way rows sit a few thousandths below their full-run values, some splits there being unusable. That near-constancy is the point of the table: the split count changes the noise on an estimate, not what it estimates. It is arithmetic rather than an independent test, as the closing paragraph says. The last column reproduces the point estimates reported in the paper, because this run uses the same seeds and split counts as the runs that produced them."));
  add(P("Two further readings. First, how far a single 25-split realisation can sit from the whole-run value: across the six quantities the largest such gap is " + (function(){ let m=0; keys.forEach(q => { const a = get(q, shared[0]), b = get(q, rmax(q)); if (a && b) m = Math.max(m, Math.abs(a.mean - b.mean)); }); return f(m,3); })() + ", and the largest ratio of that gap to the implied Monte Carlo standard deviation at 25 splits is " + (function(){ let m=0; keys.forEach(q => { const a = get(q, shared[0]), b = get(q, rmax(q)); if (a && b && a.mc_sd > 0) m = Math.max(m, Math.abs(a.mean - b.mean)/a.mc_sd); }); return f(m,2); })() + ". So the gaps are of the order of the Monte Carlo standard deviation and in places somewhat larger, as single realisations will be; they are not evidence of drift. Second, at the split count the bootstrap uses, the exact Monte Carlo standard deviations agree with the estimates the bootstrap forms internally from the within-resample variance to within " + f(Math.ceil(1000*CV.vs_internal.max_diff)/1000,3) + " across the " + f0(CV.vs_internal.rows.length) + " quantities, so the size of the component being removed is not in doubt.", {after:110}));
  /* Reviewer round 8, major point 5. An earlier version of this section said the
     agreement above was "what licenses the deflation". It is not, and the four
     limits below are why. */
  add(P("What this table does not establish should be said plainly, because an earlier version of it claimed too much. It runs on colon only, so the same correction applied to the Rotterdam ranges rests on the variance decomposition alone and on no convergence run of its own. Several of its observed spreads come from two to five blocks, where a standard deviation carries one to four degrees of freedom and is itself very imprecise. The block means are flat in R because the blocks partition one finite run and their average is that run's own value up to a remainder \u2014 arithmetic, not an independent test of unbiasedness, though the arithmetic is the point being made and is not in question. And most importantly, confirming that dispersion falls like one over the square root of the split count says nothing about the COVERAGE of a range whose replicates have been linearly shrunk: a variance law is a statement about second moments, and the corrected ranges are quantiles. We therefore present the correction as an approximation of unknown accuracy, shown beside the observed range and never instead of it, and we do not describe this table as licensing it.", {after:170}));
}

/* ---------------- Table S1f: full correlation matrix ----------------
   Reviewer round 7, minor 5. The largest off-diagonal value is a summary, and the
   reviewer asked for the matrix. It is nine by nine per cohort, so it fits. */
add(H1("Table S1f. Correlation matrix of the eligibility indicators"));
add(P("Pearson correlation of the nine binary eligibility indicators within each cohort, computed on all patients before any criterion is applied. This is the matrix the largest off-diagonal value in Table S1 summarises. The diagonal is omitted; the matrix is symmetric, so only the lower triangle is shown."));
if (CRIT && CRIT.corr) {
  const cblk = (key, lab) => {
    const Z = CRIT.corr[key]; if (!Z) return;
    const nmv = Z.names, k = nmv.length;
    add(P(lab, {b:true, after:80, size:19}));
    add(table([""].concat(nmv.slice(0, k - 1)),
      nmv.slice(1).map((rn, i) => [rn].concat(nmv.slice(0, k - 1).map((cn, j) =>
        j <= i ? f(Math.abs(Z.m[i + 1][j]) < 0.005 ? 0 : Z.m[i + 1][j], 2) : ""))),
      [1100].concat(nmv.slice(0, k - 1).map(() => 900)),
      "Lower triangle. Values are Pearson correlations of 0/1 indicators, so they are phi coefficients."));
  };
  cblk("colon", "colon");
  cblk("rott", "Rotterdam");
}

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
  add(P("Of the 16 scenarios, " + FA.n_complete + " located a threshold, " + FA.n_right + " were right-censored at 18 000 fitting patients and " + FA.n_left + " left-censored below 600. Among those located, the spread is: fitting patients " + f0(FA.n_min) + " to " + f0(FA.n_max) + " (coefficient of variation " + f(FA.cv_n,2) + "); full-protocol events " + f0(FA.ev_min) + " to " + f0(FA.ev_max) + " (" + f(FA.cv_ev,2) + "); effective sample size " + f0(FA.ess_min) + " to " + f0(FA.ess_max) + " (" + f(FA.cv_ess,2) + "). These three spreads are computed only over the scenarios in which a threshold was observable, which is a selected subset, so they cannot be compared with each other; the claim we drew from them in an earlier version is withdrawn in the Results and the unconditional comparison is in Table S2c."));
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
if (TG) add(table(["reliability target","threshold located","right-censored","left-censored","median located n*","concentrated located","diffuse located"],
 ["t70","t80","t90"].map(k => [f(TG[k].target,2), f0(TG[k].n_located), f0(TG[k].n_right), f0(TG[k].n_left),
   TG[k].med === null ? "\u2014" : f0(TG[k].med),
   f0(TG[k].conc_located) + " of " + f0(TG[k].conc_n),
   f0(TG[k].diff_located) + " of " + f0(TG[k].diff_n)]),
 [1900,1500,1400,1300,1500,1400,1360],
 "Every column is computed from the stored ladder by the same interpolation, so the three targets are treated identically. The separation between the two arrangements is present at all three targets but is not identical across them: one diffuse scenario reaches the 0.70 target and none reaches 0.80 or 0.90."));

/* ---------------- Table S2c: the currency comparison in full ---------------- */
add(H1("Table S2c. The information-currency comparison, in full"));
add(P("The Results compare three candidate currencies by binning the sixteen factorial scenarios into quartiles of each and averaging the within-bin standard deviation of the success probability. Each scenario contributes one row per fitting size, so the table below has four rows per scenario and the resampling unit is the scenario. The reviewer of an earlier version rightly asked to see the binning rather than only its summary. Two features of the binning are visible below and worth naming. Each bin holds sixteen rows. For fitting patients the quartile edges fall exactly on the four fitting sizes, so a bin is one fitting size and holds all sixteen scenarios; for events and for effective sample size the bins mix scenarios and sizes and hold twelve to sixteen distinct scenarios. So the patients column is a within-fitting-size dispersion and the other two are not exactly that, which is a further reason to read the three summaries as descriptive."));
if (CUR) {
  const blk = (key, lab) => {
    const D = CUR[key];
    add(P(lab + " \u2014 bin edges " + D.edges.map(e => Number(e).toPrecision(3).replace(/\.?0+$/, "")).join(", "), {b:true, after:70, size:19}));
    add(table(["bin","rows in bin","distinct scenarios","within-bin SD of success","runs"],
      D.bins.map(b => [b.bin, f0(b.n_rows), f0(b.n_scenarios), b.sd === null ? "\u2014" : f(b.sd,3),
                       (b.runs || []).join(", ")]),
      [1900, 1200, 1500, 1900, 2860],
      "Mean within-bin standard deviation over the " + f0(D.n_bins_used) + " bins with more than one row: " + f(D.mean_within_sd,3) + "."));
  };
  blk("patients", "Binned by fitting patients");
  blk("events", "Binned by full-protocol events");
  blk("ess", "Binned by effective sample size");
}
if (LOSO) add(P("The three summaries are " + f(NUM.fixedn.spread_patients,3) + ", " + f(NUM.fixedn.spread_events,3) + " and " + f(NUM.fixedn.spread_ess,3) + ", so the observed differences are " + f(LOSO.events_minus_patients,3) + " for events minus patients and " + f(LOSO.ess_minus_patients,3) + " for effective sample size minus patients.", {after:110}));
/* Reviewer round 8, major point 3. The previous version put a cluster bootstrap over
   the sixteen scenarios on these differences. It is withdrawn: the scenarios are the
   fixed design points of a fractional factorial, not clusters drawn from a population
   of mechanisms, so there is no sampling population for such an interval to refer to.
   A leave-one-scenario-out sweep makes no such claim and answers the question a
   reader actually has. */
if (LOSO) add(P("A previous version attached an interval to those differences by resampling the sixteen scenarios with replacement. We withdraw it. The sixteen are the fixed design points of a resolution-IV fractional factorial, not clusters drawn from a population of mechanisms, so a cluster bootstrap over them has no sampling population to refer to; it also destroys the factorial balance, and because the quartile edges are recut inside every replicate it does not resample the same statistic \u2014 which is why its mean fell on the opposite side of zero from the observed difference. Anyone wanting an interval here would first have to define the population of mechanisms being sampled and the mechanism by which these sixteen were drawn from it, and we cannot.", {after:110}));
if (LOSO) add(P("What the fixed design does support is a sensitivity analysis. Recomputing the three summaries with each scenario left out in turn, the events-minus-patients difference moves over " + f(LOSO.range_events[0],3) + " to " + f(LOSO.range_events[1],3) + " and the effective-sample-size difference over " + f(LOSO.range_ess[0],3) + " to " + f(LOSO.range_ess[1],3) + ", against observed values of " + f(LOSO.events_minus_patients,3) + " and " + f(LOSO.ess_minus_patients,3) + ". No single scenario is carrying the similarity. One thing the sweep does show, and we state it rather than leave it in the table: the observed events-minus-patients difference is small enough that omitting scenario " + f0(LOSO.worst_events) + " reverses its sign, from " + f(LOSO.events_minus_patients,3) + " to " + f(LOSO.range_events[0],3) + ". The magnitude stays small throughout, but the sign of a difference this size carries no information and should not be read as one. That is the whole of what we claim: THE THREE CHOSEN DESCRIPTIVE SUMMARIES WERE NUMERICALLY SIMILAR UNDER THIS PARTICULAR BINNING SCHEME, and stably so to the omission of any one design point. It is not a claim that the three currencies are equivalent, nor that none of them separates scenarios better than the others; the binning is not even the same kind of quantity across the three, since the patients column is a within-fitting-size dispersion and the other two are not. If uncertainty is wanted here, the honest route is to propagate each scenario's own Monte Carlo error under the fixed design rather than to resample the design.", {after:170}));
if (LOSO) add(table(["scenario left out","patients","events","effective sample size","events \u2212 patients","ESS \u2212 patients"],
  LOSO.rows.map(r => [f0(r.run), f(r.patients,3), f(r.events,3), f(r.ess,3), f(r.d_events,3), f(r.d_ess,3)])
    .concat([["none (observed)", f(LOSO.obs_patients,3), f(LOSO.obs_events,3), f(LOSO.obs_ess,3),
              f(LOSO.events_minus_patients,3), f(LOSO.ess_minus_patients,3)]]),
  [2100, 1500, 1500, 2100, 1900, 1760],
  "Leave-one-scenario-out sensitivity of the three summaries. Each row omits one of the " + f0(LOSO.n_scenarios) + " factorial design points, rebins the remaining rows into quartiles of each currency, and recomputes the mean within-bin standard deviation. This is a sensitivity analysis under a fixed design, not an interval: it says how much the comparison depends on any one scenario, and nothing about a population of mechanisms."));

add(H1("Table S3. Matched and frontier comparison, with patient-resampled ranges"));
add(P("All 512 subsets are scored on the held-out half of each split. “Matched” keeps those whose eligible count is within the stated tolerance of the rule's. “On the frontier” means no scored subset admits at least as many patients at a hazard ratio at least as low. The proportion is computed within a split and splits are averaged with equal weight; the ranges come from the outer bootstrap over patients, not from resampling splits, and are not confidence intervals — see the note below and the Methods. Rotterdam entries are descriptive, that cohort having a severe lack of empirical overlap."));
if (NS.colon && PR.colon) { const C=NS.colon, RT=NS.rott, PC=PR.colon, PRT=PR.rott;
  /* Reviewer round 6: this maximum was taken over a hard-coded seven keys while the
     table reports twenty, so it understated itself. It now covers every entry in the
     block that carries a convergence figure. */
  const maxconv = Z => Math.max.apply(null, Object.keys(Z)
    .filter(k => Z[k] && typeof Z[k] === "object" && isFinite(Z[k].conv))
    .map(k => Z[k].conv));
  /* round 4, major 1: the point estimate always comes from the primary analysis;
     the nested bootstrap contributes only the interval */
  const PKEY = {more:"more", lower:"lower", front_hr:"front_hr", front_rm:"front_rm",
    front_hrM:"front_hrM", rm_same:"same_set", rmrule_lower:"rmrule_lower",
    rmrule_greater:"rmrule_greater", greater:"greater",
    d_pair_lower:"d_pair_lower", d_pair_greater:"d_pair_greater"};
  const pt = (P0, N0, key) => { const k = PKEY[key] !== undefined ? PKEY[key] : key;
    return (P0 && P0[k] !== undefined) ? P0[k] : N0[key].point; };
  /* Reviewer round 7: the raw percentile interval carries the inner Monte Carlo
     variance as well as the population variance. Both are shown, raw first. */
  /* Reviewer round 8. Central 80% first, because it is the better-determined of the
     two at these outer counts; the wider span follows to one decimal. As observed,
     then after the slash with the estimated inner Monte Carlo component removed. */
  const ivs = z => "[" + f(z.ci80[0],2) + " to " + f(z.ci80[1],2) + "]" +
    (z.ci80_deflated ? " / [" + f(z.ci80_deflated[0],2) + " to " + f(z.ci80_deflated[1],2) + "]" : " / \u2014") +
    "  tails " + f(z.ci[0],1) + "\u2013" + f(z.ci[1],1);
  const row = (lab, key) => [lab,
    f(pt(PC,C,key),3)+" "+ivs(C[key]),
    f(pt(PRT,RT,key),3)+" "+ivs(RT[key])];
  add(table(["quantity","colon","Rotterdam (descriptive)"],
   [["splits behind the point estimate", f0(PC.R), f0(PRT.R)],
    ["outer resamples x inner splits (ranges only)", C.B+" x "+C.R, RT.B+" x "+RT.R],
    row("P(more eligible)","more"), row("P(lower hazard ratio)","lower"),
    row("P(greater RMST)","greater"),
    row("matched on HR, band 2%","hr0.02"), row("matched on HR, band 5%","hr0.05"),
    row("matched on HR, band 10%","hr0.1"), row("matched on HR, band 15%","hr0.15"),
    row("matched on RMST, band 2%","rm0.02"), row("matched on RMST, band 5%","rm0.05"),
    row("matched on RMST, band 10%","rm0.1"), row("matched on RMST, band 15%","rm0.15"),
    row("on count/HR frontier","front_hr"), row("on count/RMST frontier","front_rm"),
    row("on frontier with margin "+f(C.margin,2),"front_hrM"),
    ["matched comparators per split (mean, 10% band)", f0(PC["nm0.1"]), f0(PRT["nm0.1"])],
    ["comparator count skew vs rule", f(PC["sk0.1"],3), f(PRT["sk0.1"],3)],
    ["subsets dominating (mean)", f0(PC.n_dom), f0(PRT.n_dom)]].concat(
      C.d_pair_greater ? [["PAIRED difference, RMST rule minus published rule", "", ""],
                          row("      P(lower hazard ratio)","d_pair_lower"),
                          row("      P(greater RMST)","d_pair_greater")] : []).concat(
      C.rm_same ? [row("RMST rule selects the same set","rm_same"),
                   ["RMST rule: eligible patients (mean)", f0(PC.n_rmrule), f0(PRT.n_rmrule)],
                   row("RMST rule: P(lower hazard ratio)","rmrule_lower"),
                   row("RMST rule: P(greater RMST)","rmrule_greater")] : []).concat(
      isFinite(C.lower.conv) ? [["largest endpoint movement, half vs full outer count",
        f(maxconv(C),3), f(maxconv(RT),3)]] : []),
   [3600, 2900, 2860],
   "Each cell gives the point estimate, then the central 80% of the outer bootstrap distribution, then after the slash the same range with the estimated inner Monte Carlo component removed, and last, unbracketed, the 2.5 to 97.5 per cent span to one decimal. These are PATIENT-RESAMPLED RANGES and not confidence intervals. They describe how far each statistic moves when the cohort is resampled over patient identifiers and the whole split procedure is rerun; we make no coverage claim for them and nothing in the paper turns on where an endpoint falls. Three things separate them from an interval. Each outer replicate is a " + f0(C.R) + "-split estimator rather than the " + f0(PC.R) + "- and " + f0(PRT.R) + "-split estimators behind the point estimates, so the observed spread carries inner Monte Carlo variance that patient sampling alone would not; Table S1e quantifies that component. The removal after the slash is a linear shrinkage of the replicates toward their mean by the ratio of the outer-sampling to the total standard deviation. It matches a second moment. It does not in general recover the quantiles of the patient-sampling distribution from the convolution of that distribution with Monte Carlo noise, and these statistics are bounded proportions produced by a procedure containing a Shapley sign step and a frontier selection, neither of which is smooth. It is shown alongside the observed range, never instead of it, and it may be either too wide or too narrow. And we have not evaluated coverage against a known population at all. A dash in place of the second range means the estimated inner Monte Carlo variance was at least the total spread, so the subtraction returns a non-positive outer-sampling variance. The reading is that the patient-level component is NOT IDENTIFIABLE at this Monte Carlo precision: it is neither a finding that patient sampling contributes nothing nor a demonstration that the inner term accounts for the whole spread, both of which we have said in earlier versions and withdraw. The central 80% range leads because at " + C.B + " outer resamples its endpoints rest on the fifteenth replicate from each end while the 2.5 and 97.5 points rest on the fourth; the Monte Carlo error of the wider endpoints, from resampling the outer replicates, is at most " + f(Math.ceil(100*Math.max.apply(null, Object.keys(C).filter(k => C[k] && C[k].ci_se).map(k => Math.max(C[k].ci_se[0], C[k].ci_se[1]))))/100,2) + " over every quantity in the colon result object, against " + f(Math.ceil(100*Math.max.apply(null, Object.keys(C).filter(k => C[k] && C[k].ci80_se).map(k => Math.max(C[k].ci80_se[0], C[k].ci80_se[1]))))/100,2) + " for the central ones, which is why the wider span is printed to one decimal. The second decimal of the central endpoints is inside their Monte Carlo error for the least well determined quantities too; we print it so that narrow ranges stay distinguishable from one another, not because that digit is determined. Point estimates are from the primary analysis; the outer bootstrap supplies spread only. Two consequences of that division are visible in the table and are not errors. A range is centred on the bootstrap\u2019s own mean, which comes from a noisier estimator than the point estimate beside it, so for a quantity near a boundary the corrected range can sit wholly to one side of that point; the count/RMST frontier row in colon and the count/HR frontier row in Rotterdam both do. And a quantity that takes the same value in every replicate, such as the Rotterdam probability of more eligible patients, has a central range of zero width; its wider span is not zero, and is rounded to one decimal like every other. SD is decomposed as SD_outer = sqrt(SD_total^2 - SD_MC^2), with SD_MC^2 estimated from the sample variance of the per-split values within each resample rather than from p(1-p)/R. The last row reports how far either of the wider endpoints moves between half and the full outer count.")); }

add(H1("Table S3b. Optimism of the empirical held-out frontier"));
add(P("The frontier is selected from the same held-out data on which it is evaluated, so it is an argmax over 512 noisy estimates. In simulation the population is known and the optimism can be measured directly, at a held-out half the size of a colon scoring set."));
if (FO) add(table(["quantity","judged on a held-out half","judged at the population"],
 [["simulation replicates", f0(FO.R), f0(FO.R)],
  ["subsets dominating the rule (median)", f0(FO.dom_emp), f0(FO.dom_pop)],
  ["rule on the frontier", f(FO.front_emp,3) + (FO.se ? " (" + f(FO.se.front_emp,3) + ")" : ""),
                           f(FO.front_pop,3) + (FO.se ? " (" + f(FO.se.front_pop,3) + ")" : "")],
  ["of subsets dominating on half A, share still dominating on an independent half B",
   f(FO.repro,3) + (FO.se ? " (" + f(FO.se.repro,3) + ")" : ""), "\u2014"],
  ["of subsets dominating on half A, share genuinely dominating at the population",
   "\u2014", f(FO.true_frac,3) + (FO.se ? " (" + f(FO.se.true_frac,3) + ")" : "")]],
 [4600, 2400, 2360],
 "Monte Carlo standard errors are in parentheses. The first two rows are over all " + f0(FO.R) + " replicates; the last two are over the " + (FO.n_eff ? f0(FO.n_eff.repro) : "\u2014") + " replicates in which at least one subset dominated on half A, since the quantity is undefined otherwise. Roughly four in five apparently dominating subsets do not dominate at the population, and the empirical frontier understates the rule's true frontier membership by about a factor of two."));

add(H1("Table S3c. Three-way split: three frontier quantities, kept apart, with patient-resampled ranges"));
add(P("Each cohort is split into three stratified thirds. The rule is fitted on the first. All 512 subsets are scored on the second and those dominating the rule are recorded. Exactly those subsets — fixed before the third is touched — are then re-evaluated on the third. The three blocks below are different estimands and only block (b) is evaluated on patients that took no part in choosing the comparator. Block (c) re-scans all 512 subsets on the test third, so its counts are a fresh selection on the data that judges them and are not the survivors in block (b)."));
if (NUM.threeway) { const A = NUM.threeway.colon, B = NUM.threeway.rott;
  /* patient-level intervals from the outer bootstrap wrapped around the whole
     three-way pipeline, where that run is available */
  const TN = (NUM.threeway_nested && NUM.threeway_nested.colon) ? NUM.threeway_nested : null;
  /* raw percentile interval, then the deflated companion where the outer-sampling
     component is estimable; a dash where it is not (see the note) */
  const ivs2 = z => "[" + f(z.ci80[0],2) + " to " + f(z.ci80[1],2) + "]" +
    (z.ci80_deflated ? " / [" + f(z.ci80_deflated[0],2) + " to " + f(z.ci80_deflated[1],2) + "]" : " / \u2014") +
    "  tails " + f(z.ci[0],1) + "\u2013" + f(z.ci[1],1);
  const tn = (key, a, b) => TN && TN.colon[key] && TN.rott[key]
    ? [f(a,3) + " " + ivs2(TN.colon[key]), f(b,3) + " " + ivs2(TN.rott[key])]
    : [f(a,3), f(b,3)];
  add(table(["quantity","colon","Rotterdam (descriptive)"],
   [["three-way splits (point estimate)", f0(A.R), f0(B.R)],
    ["outer resamples x inner splits (ranges only)",
     TN ? TN.colon.B + " x " + TN.colon.R : "\u2014", TN ? TN.rott.B + " x " + TN.rott.R : "\u2014"],
    ["(a) selection third \u2014 empirical, optimistic", "", ""],
    ["      dominating subsets (median)", f0(A.dom_sel), f0(B.dom_sel)],
    ["      rule undominated", tn("front_sel", A.front_sel, B.front_sel)[0], tn("front_sel", A.front_sel, B.front_sel)[1]],
    ["(b) pre-selected subsets on the untouched third \u2014 internally validated", "", ""],
    ["      of those dominators, number still dominating (median)", f0(A.n_survive), f0(B.n_survive)],
    ["      replication rate", tn("repro", A.repro, B.repro)[0], tn("repro", A.repro, B.repro)[1]],
    ["      replication rate, margin required on the selection third", tn("reproM", A.reproM, B.reproM)[0], tn("reproM", A.reproM, B.reproM)[1]],
    ["      lowest-hazard-ratio dominator carries over", tn("best_holds", A.best_holds, B.best_holds)[0], tn("best_holds", A.best_holds, B.best_holds)[1]],
    ["      rule undominated by every pre-selected subset", tn("front_conf", A.front_conf, B.front_conf)[0], tn("front_conf", A.front_conf, B.front_conf)[1]],
    ["      largest endpoint movement, half vs full outer count",
     TN ? f(Math.max.apply(null, ["repro","reproM","front_conf","best_holds"].map(k => (TN.colon[k]||{}).conv||0)),3) : "\u2014",
     TN ? f(Math.max.apply(null, ["repro","reproM","front_conf","best_holds"].map(k => (TN.rott[k]||{}).conv||0)),3) : "\u2014"],
    /* Reviewer round 7: the endpoint Monte Carlo error was reported in Table S3 but
       not here, although this is the table drawn from the smaller outer count and so
       the one where it matters most. */
    ["      largest Monte Carlo error of an endpoint itself",
     TN ? f(Math.max.apply(null, ["repro","reproM","front_conf","best_holds","front_sel","front_test"]
       .filter(k => (TN.colon[k]||{}).ci_se).map(k => Math.max(TN.colon[k].ci_se[0], TN.colon[k].ci_se[1]))),3) : "\u2014",
     TN ? f(Math.max.apply(null, ["repro","reproM","front_conf","best_holds","front_sel","front_test"]
       .filter(k => (TN.rott[k]||{}).ci_se).map(k => Math.max(TN.rott[k].ci_se[0], TN.rott[k].ci_se[1]))),3) : "\u2014"],
    ["(c) fresh scan of all 512 on the test third \u2014 descriptive only", "", ""],
    ["      dominating subsets (median)", f0(A.dom_test), f0(B.dom_test)],
    ["      rule undominated", tn("front_test", A.front_test, B.front_test)[0], tn("front_test", A.front_test, B.front_test)[1]]],
   [5000, 2200, 2160],
   "Only block (b) evaluates the rule on patients that took no part in choosing its comparator. It is an internally validated sample-split estimate, not a confirmatory result in an independent cohort, since the same patients are reused across splits. Block (a) is the empirical oracle whose optimism is being measured; block (c) is a second empirical oracle on a different third, reported so a reader can see that the counts are a property of any part of these cohorts rather than evidence about the rule. Point estimates come from the repeated three-way splits in the first row. The ranges in block (b) come from an outer bootstrap over patients wrapped around the whole fit / select / test procedure and are read exactly as in Table S3: central 80% as observed, then after the slash with the estimated inner Monte Carlo component removed, then, after the word tails, the 2.5 to 97.5 per cent span to one decimal, and none of the three is a confidence interval. The two dashes are on the lowest-hazard-ratio dominator, whose estimated inner Monte Carlo variance is at least its total spread across resamples. That means its patient-level variance component is not identifiable at this Monte Carlo precision. An earlier version of this note read it as the inner term accounting for the whole spread; that was wrong, and no conclusion should be drawn from it in either direction. Each outer replicate uses " + (TN ? f0(TN.colon.R) : "25") + " inner splits against the " + f0(A.R) + " and " + f0(B.R) + " behind the point estimates, so the observed spread carries inner Monte Carlo variance that patient sampling alone would not. As elsewhere the bootstrap supplies spread only and never a point estimate. The export checks that the bootstrap\u2019s own observed-data replicate agrees with the repeated-split estimate to within the Monte Carlo noise of a " + (TN ? f0(TN.colon.R) : "25") + "-split estimator, and it passes; but that tolerance is wide, and the gap it tolerates is large in absolute terms \u2014 the two differ by up to " + (NUM.threeway_nested && NUM.threeway_nested.max_gap ? f(NUM.threeway_nested.max_gap,2) : "\u2014") + " across these quantities. We report the size rather than leaving a reader to infer from a passing check that the two agree closely, because they do not. These rates are poorly determined at a third of a cohort. So are the wider endpoints: the row above gives their Monte Carlo standard error, obtained by resampling the " + (TN ? TN.colon.B : 100) + " outer replicates, which is why the central 80% range leads and the wider span is printed to one decimal."));
}

add(H1("Table S3d. Restricted-mean horizon"));
add(P("The horizon must lie inside the observed follow-up of both arms of every candidate protocol. The table gives, at four horizons per cohort, the agreement between the hazard-ratio and restricted-mean decompositions; the share of patients still under observation at each horizon is given in the Results. The horizons used in the main text are marked."));
if (NUM.horizon) {
  const mk = (T, tau0) => T.map(r => [f0(r.tau) + (r.tau === tau0 ? "  (main text)" : ""),
    f(r.same,3), f(r.jac,3), f(r.ham,2), f(r.rmF,1), f(r.rm1,1), f(r.rm2,1)]);
  add(table(["horizon (days)","same set","Jaccard","mean Hamming","RMST: full","HR rule","RMST rule"],
    mk(NUM.horizon.colon, NUM.horizon.tau_colon).concat(mk(NUM.horizon.rott, NUM.horizon.tau_rott)),
    [2200, 1100, 1050, 1300, 1300, 1200, 1210],
    "Upper block colon, lower block Rotterdam. Hamming is the number of criteria on which the two selections differ, out of the nine in each cohort's protocol. The two decompositions disagree at every horizon tried, so the disagreement is a property of the estimands and not of the horizon; the exact agreement rate is horizon-dependent."));
}

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
   "Spreading the enrichment raises success at one fitting size and not demonstrably at the others: against arrangement A, arrangement B gains " + (CD ? f(CD.B_dil1_enr2.rows[2].diff,2) + " [" + f(CD.B_dil1_enr2.rows[2].lo,2) + ", " + f(CD.B_dil1_enr2.rows[2].hi,2) + "] and arrangement C " + f(CD.C_dil1_enr4.rows[2].diff,2) + " [" + f(CD.C_dil1_enr4.rows[2].lo,2) + ", " + f(CD.C_dil1_enr4.rows[2].hi,2) + "]" : "\u2014") + " at 6 000, while at 600 both point estimates run the other way (" + (CD ? f(CD.B_dil1_enr2.rows[0].diff,2) + " and " + f(CD.C_dil1_enr4.rows[0].diff,2) : "\u2014") + ") with intervals containing zero. Halving the diluting coefficient (A against D) reduces success from " + f(CN.A_dil1_enr1.rows[3].p_lower,2) + " to " + f(CN.D_dil2_enr1.rows[3].p_lower,2) + " at the largest size, but it also roughly halves the attainable improvement in the hazard ratio, so the coefficient and the size of the prize are confounded in this design and neither can be assigned the reduction on its own. Monte Carlo standard error is at most " + f(Math.max.apply(null, Object.keys(CN).map(k => Math.max.apply(null, CN[k].rows.map(r => r.se)))),3) + "."));
}

add(H1("Table S4b. Success against a criterion-specific signal-to-noise ratio (a separate run)"));
add(P("Four arrangements of the same total effect modification, each at three fitting sizes. This is a SEPARATE simulation from Table S4: it uses its own fitting sizes, a smaller scoring set and fewer replicates, so the success probabilities for the identically named arrangements are not comparable cell by cell with that table and are not meant to be. Only the ordering within this table is interpreted. The signal is the population Shapley value of the most diluting criterion; the noise is the standard deviation of its estimate at that fitting size; the scoring set is fixed at 40 000 patients, against 60 000 in Table S4. If a signal-to-noise ratio governed the requirement, cells with similar ratios would show similar success whatever the arrangement and whatever the sample size. Twelve cells cannot establish that, and this is reported as a direction rather than as evidence."));
if (NUM.snr_curve) {
  add(table(["arrangement / fitting size","population signal","SD of the estimate","signal-to-noise","P(lower hazard ratio)"],
    NUM.snr_curve.cells.map(r => [["A dilution 1, enrichment 1","B dilution 1, enrichment 2","C dilution 1, enrichment 4","D dilution 2, enrichment 1"][r.arr-1] + " / " + f0(r.n),
      f(r.phi_pop,4), f(r.sd,4), f(r.snr,2), f(r.win,2) + (r.se !== undefined ? " (" + f(r.se,2) + ")" : "")]),
    [3600, 1700, 1700, 1400, 1960],
    "Monte Carlo standard errors are in parentheses, from each cell's own replicate count; they are large enough that the ordering within this table should not be read cell by cell. Spearman correlation with success, pooled over all " + NUM.snr_curve.cells.length + " cells at " + NUM.snr_curve.nrep + " replicates each: " + f(NUM.snr_curve.sp_snr,2) + " for the signal-to-noise ratio against " + f(NUM.snr_curve.sp_n,2) + " for fitting size alone. The pooled figure should not be read as evidence for the ratio. Within an arrangement the ratio is a monotone function of the fitting size, so the within-arrangement association (" + (isFinite(NUM.snr_curve.sp_within) ? f(NUM.snr_curve.sp_within,2) : "—") + " after adjusting for arrangement) restates that success rises with sample size. The informative comparison is between arrangements at a fixed size, where it is " + (isFinite(NUM.snr_curve.sp_between) ? f(NUM.snr_curve.sp_between,2) : "—") + " at the largest size tried, over " + NUM.snr_curve.n_arr + " arrangements of which " + NUM.snr_curve.n_flat + " shows no variation in success across sizes. This table is exploratory and does not establish a governing quantity."));
}

add(H1("Text S1. Complete specification of every generating mechanism"));
add(P("No parameter below was estimated from either cohort. All were set a priori. Z denotes a vector of independent standard normal covariates, A the treatment indicator, and E the vector of eligibility indicators.", {after:160}));

add(P("S1.1 Training-size sweep (Figure 2)", {b:true, after:70}));
MONO && add(MONO("p = 8 criteria; per-criterion retention (0.85, 0.75, 0.70, 0.90, 0.80, 0.85, 0.75, 0.90)"));
add(MONO("Z_k ~ N(0,1), k = 1..8, independent      threshold_k = Phi^-1(retention_k)"));
add(MONO("E_k = 1{ Z_k <= threshold_k }            A ~ Bernoulli(0.5)"));
add(MONO("gamma = (-0.35, -0.25, +0.30, 0, 0, 0, 0, 0)   [criteria 1,2 enrich; 3 dilutes]"));
add(MONO("linear predictor  eta = log(0.75)*A + sum_k 0.55*Z_k + A * sum_k gamma_k * E_k"));
add(MONO("T ~ Exponential(rate = 0.20 * exp(eta))  C ~ Exponential(rate = 0.05)"));
add(MONO("observed time = min(T, C), event = 1{T <= C}   tau = 8, min per arm = 3"));
add(P("Fitting sizes 300, 1000, 3000, 5167 and 20 000 with 300 replicates each; scoring set fixed at 100 000 patients generated once with seed 999; population reference enumerated at N = 300 000.", {after:170}));

add(P("S1.2 Three assignment arms (Figure 3)", {b:true, after:70}));
add(MONO("Outcome model identical to S1.1 in all three arms."));
add(MONO("arm A  randomised            A ~ Bernoulli(0.5)"));
add(MONO("arm B  confounded, adjusted  A ~ Bernoulli( logit^-1( Z . alpha ) ),"));
add(MONO("                             alpha = (0.6, 0.5, 0.4, 0, 0, 0, 0, 0)"));
add(MONO("                             propensity model uses V1..V8"));
add(MONO("arm C  one confounder unmeasured: assignment as arm B,"));
add(MONO("                             propensity model uses V2..V8 only"));
add(P("250 replicates per cell; arm A additionally carries a 300-patient cell at 300 replicates, and arm C has no 20 000 cell. Because the outcome model is common, the true causal contrast is identical in all three arms; what differs across arms is the population limit of the weighted estimator.", {after:170}));

add(P("S1.3 Non-collapsibility sweep (Figure 4)", {b:true, after:70}));
add(MONO("N = 300 000, tau = 5, conditional log hazard ratio bA = log(0.6)"));
add(MONO("Z ~ N(0,1)   A ~ Bernoulli(0.5)"));
add(MONO("T ~ Exponential(rate = 0.25 * exp(bA*A + bZ*Z)),  bZ swept over"));
add(MONO("   0, 0.3, 0.6, 0.9, 1.2, 1.5, 1.8"));
add(MONO("criterion under study: Z <= 0 (retains half the cohort)"));
add(P("The conditional hazard ratio is exp(bA) = 0.6 in every stratum of Z at every point on the sweep, so the criterion changes no individual's relative benefit. bZ = 0 is the falsification point: with no prognostic heterogeneity there is nothing to collapse over and the artefact must vanish.", {after:170}));

add(P("S1.4 Fractional factorial over the threshold (Table S2)", {b:true, after:70}));
add(MONO("2^(6-2) resolution IV, generators E = ABC and F = ABD, 16 runs."));
add(MONO("A  number of criteria p                6        vs   8"));
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

add(P("S1.6 One primary analysis, and the checks that enforce it", {b:true, after:70}));
add(P("The observed-cohort point estimates that the paper’s claims rest on — the out-of-sample comparison in Table 1, the matched statistics at all four tolerances on both estimands, the frontier and dominance counts, and the restricted-mean rule variant — are produced by a single script in one pass per cohort and written to one result file, which the manuscript reads at build time. Other tables come from their own scripts, named in each caption — the cohort and overlap tables, the tie counts, the three-way split, the horizon sweep and the weighting comparison — and where one of those recomputes a quantity that also appears in the primary file, the caption says over what run. The nested bootstrap supplies uncertainty only and never a point estimate. That does not make the two agree: the bootstrap resamples an estimator built on far fewer inner splits than the point estimate uses, so its own observed-data replicate is a noisier version of the same quantity and differs from the reported point by a visible amount. Table S3c gives the size of that difference and Table S1e the convergence behaviour behind it.", {after:120}));
add(MONO("colon      time, status   tau = 1825 d   500 splits"));
add(MONO("Rotterdam  dtime, death   tau = 2555 d   400 splits"));
add(P("Six checks run whenever the numbers are exported and stop the build if violated. Three are on the exported numbers: the Rotterdam endpoint must be the death time paired with the death indicator; the horizons must be 1825 and 2555 days; and the primary and nested estimates of the same quantity must agree to within what Monte Carlo variation could explain. The fourth is on the source, because a check on the numbers alone would not have caught the error that prompted it: every analysis script is scanned and the export refuses if any line pairs the relapse-free time with the death indicator, or calls a Rotterdam dataset at the colon horizon. The fifth refuses to run if any of the five superseded result objects reappears in the read path. The sixth asserts " + (NUM.integers ? f0(Object.keys(NUM.integers).length) : "the") + " integer counts — both cohort sizes, the criterion and subset counts, both horizons, every split and resample count including those of the three-way design, the simulation replicate counts and the number of factorial scenarios — against the analysis output, because the provenance check over the manuscript sources tests decimals and percentages but not bare integers.", {after:120}));
add(P("The provenance check itself has limits we state rather than leave in the code. It matches whitelisted constants on their value and not on where they appear, so a design constant's value would also pass if it were typed as a result. It skips strings passed to the monospaced-text helper, which is what allows the generating-model specification above to be typed out; those are model definitions rather than results, but they are not checked. It reads decimals and percentages, so a figure written in words, or in exponent form, is outside its reach. It skips strings that are bare result-object keys, and it skips digit patterns inside a digital object identifier or a journal citation. The earlier response letters are exempt as a historical record of what was said at the time and are reported as exempt on every run.", {after:170}));

add(H1("Figure S1. Full-page study design"));
add(P("Figure 1 of the main text at full width.", {after:120}));
add(new Paragraph({spacing:{after:200}, alignment:AlignmentType.CENTER,
  children:[new d.ImageRun({data: fs.readFileSync("/home/claude/repo/figures/fig_design.png"),
    type:"png", transformation:{width:660, height:336}})]}));

add(new Paragraph({children:[new d.PageBreak()]}));
add(H1("Figure S2. Full-page criteria plate plot"));
add(P("The colon criteria plate plot at full page size, reproducing Figure 5 of the main text.", {after:120}));
add(new Paragraph({spacing:{after:100}, alignment:AlignmentType.CENTER,
  children:[new d.ImageRun({data: fs.readFileSync("/home/claude/repo/figures/fig2_plate3.png"),
    type:"png", transformation:{width:600, height:713}})]}));

add(new Paragraph({children:[new d.PageBreak()]}));
add(H1("Figure S3. Propensity distributions inside the full protocol"));
add(P("Estimated propensity scores by treatment arm within the full protocol of each cohort, with the 0.05 and 0.95 truncation bounds marked and the common-support region indicated. The Rotterdam panel shows the near-separation that makes its weighted estimates descriptive rather than causal."));
add(new Paragraph({spacing:{after:200}, alignment:AlignmentType.CENTER,
  children:[new d.ImageRun({data: fs.readFileSync("/home/claude/repo/figures/fig_overlap.png"),
    type:"png", transformation:{width:620, height:248}})]}));

const doc = new Document({sections:[{properties:{page:{size:{width:12240,height:15840},
  margin:{top:1000,bottom:1000,left:1080,right:1080}}}, children: body}]});
Packer.toBuffer(doc).then(b => { fs.writeFileSync("supplement.docx", b);
  console.log("supplement written", b.length, "bytes"); });
