const M = require('./make.js');
require('./part2.js')(M);
require('./part3.js')(M);
/* ---- declarations, then references ---- */
M.add(M.H1("Declarations"));
const DECL = [
 ["Ethics approval and consent to participate","Not applicable. Both datasets are fully de-identified, publicly distributed with the R package survival, and were previously published; no new human-subjects data were collected."],
 ["Consent for publication","Not applicable."],
 ["Availability of data and materials","Both cohorts ship with the R package survival and require no application. All analysis code, the R package trialplate, and the machine-readable file of every number quoted in this paper are in the study repository [URL to be supplied at acceptance; an anonymous reviewer link is available on request]. An archived release with a DOI will be deposited on acceptance."],
 ["Competing interests","To be completed by the authors."],
 ["Funding","To be completed by the authors."],
 ["Authors' contributions","To be completed by the authors."],
 ["Acknowledgements","We thank the reviewers, whose comments identified two errors in an earlier version and led to the analyses in sections 1 and 3 of the Results."],
];
DECL.forEach(([h, t]) => M.add(M.P([M.R(h + ". ", {b:true}), M.R(t)], {after:110, size:20})));
M.add(M.refList());
const {Document, Packer, fs} = M;
const doc = new Document({
  styles: {default: {document: {run: {font: "Calibri", size: 22}}},
    paragraphStyles: [
      {id:"Heading1", name:"Heading 1", basedOn:"Normal", next:"Normal", quickFormat:true,
       run:{size:28, bold:true, color:"10375F", font:"Calibri"}},
      {id:"Heading2", name:"Heading 2", basedOn:"Normal", next:"Normal", quickFormat:true,
       run:{size:24, bold:true, color:"333333", font:"Calibri"}}]},
  sections: [{
    properties: {page: {size: {width: 12240, height: 15840},
                        margin: {top: 1440, right: 1440, bottom: 1440, left: 1440}}},
    children: M.body}]});
const unused = M.REFS.filter(r => !M.USED.has(r.k)).map(r => r.k);
if (unused.length) console.warn("WARNING uncited references:", unused.join(", "));
Packer.toBuffer(doc).then(b => { fs.writeFileSync("/home/claude/ms/trialplate_manuscript.docx", b);
  console.log("written", b.length, "bytes;", M.USED.size, "of", M.REFS.length, "references cited"); });
