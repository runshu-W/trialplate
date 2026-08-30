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
  text:"How much data does a data-driven eligibility criterion need? Out-of-sample validation of criteria relaxation in two public cohorts",
  bold:true, size:30, font:"Calibri"})]}));
add(P([R("Author One"), R("1", {sup:true}), R(", Author Two"), R("2", {sup:true}),
       R(", Corresponding Author"), R("1,*", {sup:true})], {after: 100}));
add(P([R("1 ", {sup:true}), R("Affiliation to be completed. "), R("2 ", {sup:true}),
       R("Affiliation to be completed.")], {size: 20, after: 100}));
add(P([R("* Correspondence: ", {b:true}), R("runshu.wang@gmail.com")], {size: 20, after: 320}));

/* ---------------- abstract ---------------- */
add(H1("Abstract"));
add(P([R("Background. ", {b:true}), R(
"Rules that relax clinical-trial eligibility criteria using real-world data make two separate promises: that more patients become eligible, and that the estimated treatment effect does not suffer. The two promises have been reported together, but neither has been validated out of sample, and no guidance exists on how much data such a rule needs before its output can be acted upon.")]));
add(P([R("Methods. ", {b:true}), R(
"We implemented the published selection rule — retain every criterion whose Shapley value on the log hazard ratio is negative, relax the rest — and evaluated it by sample splitting in two fully public individual-level cohorts: a randomised adjuvant colon-cancer trial (n = 619) and the Rotterdam breast-cancer registry (n = 2982). The rule was fitted on one split and the resulting protocol scored against the original full protocol on the other. A simulation with a fixed test set of 100 000 patients isolated the effect of fitting-cohort size, and three arms sharing one outcome model separated randomised assignment, confounded assignment with correct adjustment, and confounded assignment with one confounder unmeasured. Both benefit estimands were carried throughout, the log hazard ratio and the difference in restricted mean survival time, because the hazard ratio is non-collapsible.")]));
add(P([R("Results. ", {b:true}), R(
"The eligibility promise held in both cohorts and at every simulated fitting size (probability 0.94 to 1.00). The effect-estimate promise did not hold in either cohort (probability 0.270 and 0.497 of a lower out-of-sample hazard ratio) but this was a function of fitting-cohort size, not of the rule: in simulation the probability rose from 0.273 at 300 fitting patients to 0.937 at 5167, and the curve predicted the observed value in the randomised cohort at a split it had not been fitted to (predicted 0.339, observed 0.336). Confounded assignment that was correctly adjusted for lowered the probability at 5167 patients from 0.937 to 0.808. Confounded assignment with one confounder unmeasured returned the curve to randomised levels (0.936) while inflating the true population gap it was detecting by 32%. The rule recovered the exactly correct criterion set in only 28% of replicates at 5167 patients, which is why the two promises diverge: enrolling more patients does not require a correct selection, improving the effect estimate does.")]));
add(P([R("Conclusions. ", {b:true}), R(
"Data-driven relaxation of eligibility criteria reliably widens the eligible population and this is a sufficient case for it. The accompanying improvement in the effect estimate requires a fitting cohort of roughly 3000 patients under randomisation and about twice that under confounding, and below that threshold it is in-sample selection. Apparent success on observational data is not evidence that adjustment was adequate — incomplete adjustment makes the procedure look better. We provide the threshold curve, two diagnostics computable before any outcome is examined, and an R package.")]));
add(P([R("Keywords: ", {b:true}), R(
"eligibility criteria; trial emulation; real-world data; Shapley value; non-collapsibility; restricted mean survival time; out-of-sample validation; sample size")], {after: 260}));

module.exports = {d, body, add, P, H1, H2, R, table, W, Document, Packer, Paragraph, TextRun,
                  HeadingLevel, AlignmentType, fs};
