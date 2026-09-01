const d = require('docx');
const {Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType, Table, TableRow,
       TableCell, WidthType, ShadingType, BorderStyle, PageBreak, convertInchesToTwip} = d;
const fs = require('fs');

const W = 9360;                                  // content width, US Letter with 1" margins
const P = (t, o = {}) => new Paragraph({
  spacing: {after: o.after ?? 140, line: o.line ?? 300},
  alignment: o.align, indent: o.indent,
  children: (Array.isArray(t) ? t : [new TextRun({text: t, italics: o.i, bold: o.b, size: o.size ?? 22,
                                                  font: "Calibri", color: o.color})]),
});
const H = (t, lvl) => new Paragraph({heading: lvl, spacing: {before: 280, after: 130},
  children: [new TextRun({text: t, font: "Calibri"})]});
const H1 = t => H(t, HeadingLevel.HEADING_1);
const H2 = t => H(t, HeadingLevel.HEADING_2);
const R  = (t, o={}) => new TextRun({text: t, bold: o.b, italics: o.i, size: 22, font: "Calibri",
                                     superScript: o.sup});

function table(head, rows, widths, note) {
  const cell = (txt, opt = {}) => new TableCell({
    width: {size: opt.w, type: WidthType.DXA},
    shading: opt.head ? {type: ShadingType.CLEAR, fill: "EDF1F5"} : undefined,
    margins: {top: 60, bottom: 60, left: 90, right: 90},
    children: [new Paragraph({spacing: {after: 0, line: 260},
      alignment: opt.right ? AlignmentType.RIGHT : AlignmentType.LEFT,
      children: [new TextRun({text: String(txt), bold: opt.head, size: 19, font: "Calibri"})]})]});
  const trs = [new TableRow({tableHeader: true,
    children: head.map((h, i) => cell(h, {w: widths[i], head: true, right: i > 0}))})];
  rows.forEach(r => trs.push(new TableRow({
    children: r.map((c, i) => cell(c, {w: widths[i], right: i > 0}))})));
  const out = [new Table({columnWidths: widths, width: {size: W, type: WidthType.DXA}, rows: trs,
    borders: {top:{style:BorderStyle.SINGLE,size:6,color:"9AA4AF"},
              bottom:{style:BorderStyle.SINGLE,size:6,color:"9AA4AF"},
              left:{style:BorderStyle.NONE},right:{style:BorderStyle.NONE},
              insideHorizontal:{style:BorderStyle.SINGLE,size:2,color:"D7DEE5"},
              insideVertical:{style:BorderStyle.NONE}}})];
  if (note) out.push(P(note, {size: 18, after: 240, color: "555555"}));
  else out.push(P("", {after: 200}));
  return out;
}

const body = [];
const add = (...x) => x.forEach(e => Array.isArray(e) ? body.push(...e) : body.push(e));

/* ---------------- title page ---------------- */
add(new Paragraph({spacing:{after:220}, children:[new TextRun({
  text:"What data-driven relaxation of trial eligibility criteria can and cannot promise: an out-of-sample evaluation, and why reliability was not determined by cohort size alone across the mechanisms examined",
  bold:true, size:30, font:"Calibri"})]}));
add(P([R("Author One"), R("1", {sup:true}), R(", Author Two"), R("2", {sup:true}),
       R(", Corresponding Author"), R("1,*", {sup:true})], {after: 100}));
add(P([R("1 ", {sup:true}), R("Affiliation to be completed. "), R("2 ", {sup:true}),
       R("Affiliation to be completed.")], {size: 20, after: 100}));
add(P([R("* Correspondence: ", {b:true}), R("runshu.wang@gmail.com")], {size: 20, after: 320}));

/* every quoted number is read from the analysis outputs, never transcribed */
const NUM = JSON.parse(fs.readFileSync("/home/claude/repo/analysis/out/numbers.json","utf8"));
const _pc = (x, k) => (100*x).toFixed(k===undefined?1:k) + "%";
const _PRC = (NUM.primary||{}).colon || {}, _PRR = (NUM.primary||{}).rott || {};
const _FO = NUM.frontier_opt || {}, _TW = NUM.threeway || null,
      _CL = NUM.confound_limits || null, _CFD = NUM.confound || null;
const f3 = x => Number(x).toFixed(3);
const _f2 = x => Number(x).toFixed(2);
const _CNC = NUM.concentration || {};

/* ---------------- abstract ---------------- */
add(H1("Abstract"));
add(P([R("Background. ", {b:true}), R(
"Rules that relax clinical-trial eligibility criteria using real-world data make two promises: that more patients become eligible, and that the estimated treatment effect does not suffer. To our knowledge neither has been evaluated out of sample, and no guidance exists on how much data such a rule needs.")]));
add(P([R("Methods. ", {b:true}), R(
"We implemented the published rule — retain every criterion whose Shapley value on the log hazard ratio is negative — and evaluated it by repeated stratified sample splitting in two fully public cohorts: a randomised adjuvant colon-cancer trial (n = 619) and the Rotterdam breast-cancer registry (n = 2982). Because the eligible count is monotone in the criteria removed, the rule was compared not against the full protocol alone but against all 512 subsets scored on the held-out half, matched on eligible count and placed against the empirical held-out frontier, whose optimism is quantified separately in simulation. Every out-of-sample quantity passes through an outer bootstrap split by patient identifier, whose intervals are approximate: they carry the Monte Carlo variance of the inner splits and their coverage has not been established. Simulation with a fixed 100 000-patient scoring set isolated fitting-cohort size in one generating mechanism, and a resolution-IV factorial in six factors varied that mechanism, reported as success probability at fixed sizes, and a further sweep varied how a fixed total of effect modification is arranged.")]));
add(P([R("Results. ", {b:true}), R(
"Matched on eligible count and carried through patient-level resampling, the rule reached a lower hazard ratio than a comparable subset in " + _pc(_PRC["hr0.1"]) + " of colon comparisons and " + _pc(_PRR["hr0.1"]) + " in Rotterdam, averaging within-split proportions with equal weight, and was near one half on the restricted mean difference; every interval contains one half, so neither an advantage nor its absence is established. Its choice was almost never on the empirical held-out frontier, but that frontier is optimistic: in simulation only " + _pc(_FO.true_frac) + " of apparently dominating subsets genuinely dominate at the population and " + _pc(_FO.repro) + " reproduce on an independent half, and in a three-way split of the cohorts themselves, where the comparator subsets are fixed on separate data before evaluation, the rule is left undominated in " + (_TW ? _pc(_TW.colon.front_conf) + " of colon and " + _pc(_TW.rott.front_conf) + " of Rotterdam splits, against " + _pc(_TW.colon.front_sel) + " and " + _pc(_TW.rott.front_sel) + " judged on the selection third of that same design" : "a substantially larger share of splits") + ". A variant selecting on the restricted mean difference agrees with the published rule on the criterion set in " + _pc(_PRC.same_set) + " of colon splits and showed no clear or consistent advantage out of sample: the probability of improvement was higher for it on the restricted mean difference and lower on the hazard ratio, with the paired difference between the two rules, carried through the same outer bootstrap, not establishing an advantage for either; no equivalence margin was prespecified. The observed proportion of splits in which the data-driven protocol reached a lower out-of-sample hazard ratio than the original was below one half in colon (" + _PRC.lower.toFixed(3) + ") and close to one half in Rotterdam (" + _PRR.lower.toFixed(3) + "); with patient-level intervals this establishes neither failure nor success of the effect-estimate promise. Across the factorial the success probability varied by between " + _f2((NUM.fixedn||{}).sd_min) + " and " + _f2((NUM.fixedn||{}).sd_max) + " in standard deviation across the fixed sample sizes, and the descriptive dispersion measure we used was similar for the three currencies in these 16 scenarios, which does not establish that they are equivalent. Halving the diluting signal across two criteria cut success from " + _f2(_CNC.A_dil1_enr1.rows[3].p_lower) + " to " + _f2(_CNC.D_dil2_enr1.rows[3].p_lower) + " at 18 000 fitting patients, but it also roughly halves the attainable improvement, so the two cannot be separated in that design. Omitting one confounder returned apparent reliability to randomised levels while inflating the estimator's population limit by " + (_CL ? _pc(_CL.inflation,1) : "\u2014") + " and cutting correct selection from " + (_CFD ? f3(_CFD.rec_rand_5167) : "\u2014") + " to " + (_CFD ? f3(_CFD.rec_unmeas_5167) : "\u2014") + ".")]));
add(P([R("Conclusions. ", {b:true}), R(
"Data-driven relaxation widens the eligible population, but that widening follows largely from the structure of the rule, and whether the procedure adds anything at matched inclusiveness is not resolved by cohorts of this size. The direction of the point estimates differs between the two estimands: on the hazard ratio the rule is favoured in both cohorts, while on absolute benefit the two cohorts point opposite ways. No universal data requirement could be determined from cohort size, event count or effective sample size alone across the mechanisms simulated; a requirement can in principle be stated conditionally on an assumed minimum diluting signal, as a power calculation is stated on an assumed minimum effect, but we do not supply that conditional statement here. Incomplete adjustment can make the procedure appear more reliable while its selection is less accurate.")]));
add(P([R("Keywords: ", {b:true}), R(
"eligibility criteria; trial emulation; real-world data; Shapley value; non-collapsibility; restricted mean survival time; out-of-sample evaluation; sample size")], {after: 260}));

const f = (x, k = 3) => (x === null || x === undefined || Number.isNaN(x)) ? "[pending]" : Number(x).toFixed(k);
const f0 = x => f(x, 0);
const pct = (x, k = 1) => (x === null || x === undefined) ? "[pending]" : (100*Number(x)).toFixed(k) + "%";

/* ---- citations: CITE("key","key2") emits a superscript "1,2" and records use ---- */
const REFS = require("./refs.js");
const REFIDX = Object.fromEntries(REFS.map((r,i)=>[r.k, i+1]));
const USED = new Set();
const CITE = (...keys) => {
  const nums = keys.map(k => { if (!(k in REFIDX)) throw new Error("unknown reference key: "+k);
                               USED.add(k); return REFIDX[k]; }).sort((a,b)=>a-b);
  return new TextRun({text: nums.join(","), size: 22, font: "Calibri", superScript: true});
};
const refList = () => {
  const out = [H1("References")];
  REFS.forEach((r,i) => out.push(new Paragraph({
    spacing:{after:40, line:228},
    indent:{left:300, hanging:300},
    children:[new TextRun({text:(i+1)+". ", size:19, font:"Calibri", bold:true}),
              new TextRun({text:r.t, size:19, font:"Calibri"})]})));
  return out;
};

const FIGDIR = "/home/claude/repo/figures/";
// 正文宽度 9360 DXA = 6.5 in；按 96 dpi 折 624 px，留 4 px 余量
const FIG = (file, wpx, hpx, caption) => ([
  new Paragraph({spacing:{before:200, after:60}, alignment: AlignmentType.CENTER,
    children:[new d.ImageRun({data: fs.readFileSync(FIGDIR + file), type:"png",
                              transformation:{width:wpx, height:hpx}})]}),
  new Paragraph({spacing:{after:220}, children:[
    new TextRun({text: caption, size:19, font:"Calibri", color:"444444"})]})
]);

module.exports = {d, body, add, P, H1, H2, R, table, FIG, W, NUM, f, f0, pct, CITE, refList, REFS, USED, Document, Packer, Paragraph, TextRun,
                  HeadingLevel, AlignmentType, fs};
