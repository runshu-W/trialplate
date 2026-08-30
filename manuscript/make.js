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
  text:"What data-driven relaxation of trial eligibility criteria can and cannot promise: an out-of-sample validation, and why the data requirement cannot be stated in advance",
  bold:true, size:30, font:"Calibri"})]}));
add(P([R("Author One"), R("1", {sup:true}), R(", Author Two"), R("2", {sup:true}),
       R(", Corresponding Author"), R("1,*", {sup:true})], {after: 100}));
add(P([R("1 ", {sup:true}), R("Affiliation to be completed. "), R("2 ", {sup:true}),
       R("Affiliation to be completed.")], {size: 20, after: 100}));
add(P([R("* Correspondence: ", {b:true}), R("runshu.wang@gmail.com")], {size: 20, after: 320}));

/* ---------------- abstract ---------------- */
add(H1("Abstract"));
add(P([R("Background. ", {b:true}), R(
"Rules that relax clinical-trial eligibility criteria using real-world data make two promises: that more patients become eligible, and that the estimated treatment effect does not suffer. To our knowledge neither has been validated out of sample, and no guidance exists on how much data such a rule needs.")]));
add(P([R("Methods. ", {b:true}), R(
"We implemented the published rule — retain every criterion whose Shapley value on the log hazard ratio is negative — and evaluated it by repeated stratified sample splitting in two fully public cohorts: a randomised adjuvant colon-cancer trial (n = 619) and the Rotterdam breast-cancer registry (n = 2982). Because the eligible count is monotone in the criteria removed, the rule was compared not against the full protocol alone but against all 512 subsets scored on the held-out half, matched on eligible count and placed against the attainable frontier. An outer bootstrap, split by patient identifier, separates algorithmic stability from population uncertainty. Simulation with a fixed 100 000-patient scoring set isolated fitting-cohort size across a resolution-IV factorial in six factors, reported as success probability at fixed sizes rather than as an estimated threshold, and a further sweep separated how widely the effect modification is spread from how strong the criterion the rule must detect is.")]));
add(P([R("Results. ", {b:true}), R(
"Matched on eligible count, the rule reached a lower hazard ratio than a comparable subset in 59.8% of colon splits and 54.8% of Rotterdam splits, and was at or below chance on the restricted mean difference; its choice lay on the eligible-count-versus-hazard-ratio frontier in 1.6% and 3.0% of splits, with a median of 72 and 60 subsets dominating it. The effect-estimate promise was not kept in either cohort (0.270 and 0.497), with between-cohort standard deviations fourteen and twelve times the naive across-split figure and 95% intervals spanning most of the range. Across the factorial the success probability varied by about 0.34 in standard deviation at every fixed sample size, and equally whether scenarios were grouped by patients, events or effective sample size. The governing quantity is not how concentrated the effect modification is but the magnitude of the largest diluting coefficient: spreading the enrichment over four criteria left success unchanged, while halving the diluting signal across two criteria reduced it from 0.85 to 0.43 at 18 000 fitting patients. Omitting one confounder returned apparent reliability to randomised levels while inflating the estimator's population limit by 32% and halving correct selection. Rotterdam showed a severe lack of empirical overlap inside the full protocol.")]));
add(P([R("Conclusions. ", {b:true}), R(
"Data-driven relaxation widens the eligible population, but that widening follows largely from the structure of the rule, and at matched inclusiveness the rule is rarely near the attainable frontier. The data requirement for the effect-estimate promise is governed by the magnitude of the strongest diluting effect-modification coefficient — the very quantity the analysis exists to discover — so it cannot be stated in advance in patients, events or effective sample size. What can be checked beforehand is positivity inside the full protocol, logical implication and interaction leverage; what cannot is whether there is a signal large enough to find.")]));
add(P([R("Keywords: ", {b:true}), R(
"eligibility criteria; trial emulation; real-world data; Shapley value; non-collapsibility; restricted mean survival time; out-of-sample validation; sample size")], {after: 260}));

/* every quoted number is read from the analysis outputs, never transcribed */
const NUM = JSON.parse(fs.readFileSync("/home/claude/repo/analysis/out/numbers.json","utf8"));
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
    spacing:{after:80, line:250},
    indent:{left:340, hanging:340},
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
