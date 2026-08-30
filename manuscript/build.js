const M = require('./make.js');
require('./part2.js')(M);
require('./part3.js')(M);
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
Packer.toBuffer(doc).then(b => { fs.writeFileSync("/home/claude/ms/trialplate_manuscript.docx", b);
  console.log("written", b.length, "bytes"); });
