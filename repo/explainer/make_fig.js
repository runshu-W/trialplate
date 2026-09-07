const fs = require("fs");
const d = require("docx");
const { Document, Packer, Paragraph, TextRun, AlignmentType,
        Table, TableRow, TableCell, WidthType, ShadingType, BorderStyle } = d;

const CN  = "Noto Serif CJK SC";
const CNB = "Noto Sans CJK SC";
const NUM = JSON.parse(fs.readFileSync("/home/claude/repo/analysis/out/numbers.json","utf8"));
const FA = NUM.factorial, BY = FA.by,
      RC = NUM.recovery, E = NUM.efficiency, CONC = NUM.concentration,
      FX = NUM.fixedn || {};
const PR = NUM.primary || {}, C = PR.colon || {}, RT = PR.rott || {},
      TN = (NUM.threeway_nested && NUM.threeway_nested.colon) ? NUM.threeway_nested : null,
      NS = NUM.nested || {}, FO = NUM.frontier_opt || null,
      TW = NUM.threeway || null, HZ = NUM.horizon || null, SC = NUM.snr_curve || null;
const f = (x,k=3) => (x===null||x===undefined) ? "—" : Number(x).toFixed(k);
const f0 = x => f(x,0);
const pct = (x,k=1) => (100*Number(x)).toFixed(k) + "%";

const kids = [];
const add = (x) => Array.isArray(x) ? kids.push(...x) : kids.push(x);

// **text** becomes a real bold run rather than literal asterisks
const runs = (t, o = {}) => String(t).split("**").map((seg, i) =>
  new TextRun({ text: seg, size: o.size ?? 19, font: (i % 2) ? CNB : CN,
                bold: !!(i % 2), color: o.color })).filter(r => r);
const P = (t, o = {}) => new Paragraph({
  spacing: { after: o.after ?? 46, line: 236 },
  alignment: AlignmentType.JUSTIFIED,
  children: runs(t, o)
});
const H = (t) => new Paragraph({
  spacing: { before: 170, after: 78 },
  children: [ new TextRun({ text: t, size: 21, bold: true, font: CNB, color: "1A4B7A" }) ]
});
const SUB = (t) => new Paragraph({
  spacing: { before: 110, after: 55 },
  children: [ new TextRun({ text: t, size: 19, bold: true, font: CNB }) ]
});
const B = (mark, t) => new Paragraph({
  spacing: { after: 44, line: 250 }, alignment: AlignmentType.JUSTIFIED,
  indent: { left: 300, hanging: 300 },
  children: [
    new TextRun({ text: mark + "  ", size: 19, bold: true, font: CNB, color: "1A4B7A" }),
    ...runs(t)
  ]
});
const CELL = (t, o = {}) => new TableCell({
  width: { size: o.w, type: WidthType.DXA },
  shading: o.head ? { type: ShadingType.CLEAR, fill: "EEF2F6" } : undefined,
  margins: { top: 55, bottom: 55, left: 85, right: 85 },
  children: [ new Paragraph({ spacing:{after:0,line:250},
    alignment: o.right ? AlignmentType.RIGHT : AlignmentType.LEFT,
    children: [ new TextRun({ text: String(t), size: o.size ?? 17, font: o.head ? CNB : CN, bold: !!o.head }) ] }) ]
});
const TBL = (head, rows, widths, note, sz) => {
  const trs = [ new TableRow({ tableHeader:true, cantSplit:true,
    children: head.map((h,i)=>CELL(h,{w:widths[i],head:true,right:i>0,size:sz})) }) ];
  rows.forEach(r => trs.push(new TableRow({ cantSplit:true,
    children: r.map((c,i)=>CELL(c,{w:widths[i],right:i>0,size:sz})) })));
  const out = [ new Table({ columnWidths: widths, width:{size:widths.reduce((a,b)=>a+b,0), type:WidthType.DXA},
    rows: trs,
    borders:{ top:{style:BorderStyle.SINGLE,size:4,color:"AAAAAA"},
              bottom:{style:BorderStyle.SINGLE,size:4,color:"AAAAAA"},
              left:{style:BorderStyle.NONE}, right:{style:BorderStyle.NONE},
              insideHorizontal:{style:BorderStyle.SINGLE,size:2,color:"DDDDDD"},
              insideVertical:{style:BorderStyle.NONE} } }) ];
  if (note) out.push(new Paragraph({ spacing:{after:150},
    children: runs(note, {size:15, color:"666666"}) }));
  else out.push(new Paragraph({ spacing:{after:130} }));
  return out;
};

const CF = NUM.criteria.head, PS1 = NUM.ps_specs["Rotterdam (registry) M1"],
      TS = NUM.trainsize.rows, CFD = NUM.confound, CL = NUM.confound_limits,
      LOSO = FX.currency_loso || null;
const r80 = z => "[" + f(z.ci80[0],2) + "–" + f(z.ci80[1],2) + "]";
const wid = z => f(z.ci80[1] - z.ci80[0], 2);

const IMG = (file, w, h) => new Paragraph({
  spacing: { before: 40, after: 30 }, alignment: AlignmentType.CENTER,
  children: [ new d.ImageRun({ data: fs.readFileSync("/home/claude/cn/" + file),
                               type: "png", transformation: { width: w, height: h } }) ] });
const CAP = (t) => new Paragraph({
  spacing: { after: 110 }, alignment: AlignmentType.JUSTIFIED,
  indent: { left: 180, right: 180 },
  children: runs(t, { size: 15, color: "666666" }) });

/* ---------------------------------------------------------------- title */
add(new Paragraph({ spacing:{after:40}, alignment: AlignmentType.CENTER,
  children:[new TextRun({ text:"这项工作做了什么", size:28, bold:true, font:CNB })]}));
add(new Paragraph({ spacing:{after:150}, alignment: AlignmentType.CENTER,
  children:[new TextRun({ text:"五张图 · 数据驱动放宽临床试验入组标准的一次样本外复查",
                          size:17, font:CN, color:"666666" })]}));

add(P("Trial Pathfinder（Liu 等，Nature 2021）用 Shapley 值挑出「限制了人数、却没给疗效估计带来好处」的入组标准并放宽，宣称由此**同时**得到更多病人和更好的疗效估计。我们把这两个承诺**拆开**做样本外检验。结论是否定性的：**前一条基本由方法的构造决定，后一条这两个公开队列判不出来**；而且**单靠队列人数、事件数或有效样本量，定不出「多少数据才够」的通用门槛**。"));

/* ---- 1 ---- */
add(H("一、怎么做的"));
add(P("已有的评价都是**样本内**的——在同一批病人身上选标准、又在同一批病人身上打分，这是乐观偏倚的经典场景。我们把选和评分分开："));
add(IMG("f1_design.png", 620, 239));
add(CAP("**图 1　研究设计。**按治疗组和事件分层随机对半，只在拟合半样本上跑规则，把选出的方案拿到留出半样本上打分，与完整方案对比。重复划分用的是同一批病人，跨划分的标准误低估总体不确定性，所以外层再按**病人 ID**（而不是按行）对整个队列自助重抽，尝试把划分噪声和病人抽样变异近似分开——对有些量，后者在我们能负担的蒙特卡洛精度下并不可辨识。两个公开队列：colon（辅助结肠癌随机试验，n = " + f0(CF.colon.n) + "，完整方案保留 " + f0(CF.colon.full_n) + " 人 / " + f0(CF.colon.full_events) + " 事件）与 Rotterdam（乳腺癌登记队列，n = " + f0(CF.rott.n) + "，保留 " + f0(CF.rott.full_n) + " 人 / " + f0(CF.rott.full_events) + " 事件）。事件数比人数小得多，也更要紧。"));

/* ---- 2 ---- */
add(H("二、「多纳入病人」是构造性的，真正该问的是同样人数下谁更好"));
add(P("规则保留的是完整方案标准的一个子集，合格人数只增不减——" + f0(C.R) + " 次划分里最小差值恰好是 0，从不为负。所以「比完整方案纳入更多」不可能有别的结果。公平的对照是把全部 " + f0(E.nsub) + " 个子集都在留出的那一半上评分，在**相同入组人数**下比较，并看规则离可达前沿有多远："));
add(IMG("f2_subsets.png", 604, 303));
add(CAP("**图 2　一次划分里的全部 " + f0(E.nsub) + " 个子集**（colon，" + f0(C.R) + " 次划分中的第一次，未经挑选）。横轴是留出半样本上的合格人数，纵轴是对数风险比，越低越好。规则（红星）比完整方案（蓝方块）多纳入了病人，但对数风险比反而更高；绿色区域里有 44 个子集**两个维度都不比它差、且至少一个维度更好**（即支配它）。这一次划分的 44 个略低于 " + f0(C.R) + " 次划分的平均 " + f0(C.n_dom) + " 个。整体上规则落在可达前沿上的比例只有 " + pct(C.front_hr) + "（colon）和 " + pct(RT.front_hr) + "（Rotterdam）。"));

/* ---- 3 ---- */
add(H("三、相同人数下的优势：这两个队列判不出来"));
add(P("在合格人数相差 10% 以内的子集中，规则的风险比更低的比例是 " + pct(C["hr0.1"]) + "（colon）和 " + pct(RT["hr0.1"]) + "（Rotterdam）；换成 RMST 差是 " + pct(C["rm0.1"]) + " 和 " + pct(RT["rm0.1"]) + "，**两个队列方向相反**。关键在于这些点估计有多稳："));
add(IMG("f3_ranges.png", 596, 293));
add(CAP("**图 3　重抽病人时各个量的移动幅度。**粗线是中间 80% 的范围，细线是 2.5–97.5% 的尾段，圆点是点估计。入组承诺（第一行）很稳，因为它是构造性的；其余各行的范围都宽到占去单位区间的四分之一到大半，即对队列里恰好是哪些病人相当敏感。**这些不是置信区间**：外层每次重抽只做 " + f0(NS.colon.R) + " 次内层划分（点估计用 " + f0(C.R) + " 次），压缩校正只匹配二阶矩、不保证还原分位数，覆盖率也没有对着已知总体验证过。所以全文没有任何结论建立在「范围是否跨过 0.5」之上，也没有做过任何有校准的总体层面比较——我们只用它说明**统计量移动了多少**。"));

/* ---- 4 ---- */
add(H("四、经验前沿本身是乐观的"));
add(P("图 2 里的前沿是在**同一批留出数据**上从 " + f0(E.nsub) + " 个带噪声的估计里挑最优挑出来的，带「胜者诅咒」式的乐观偏倚。真值已知的模拟给出量级：表面支配者只有 " + pct(FO.true_frac) + " 在总体上真的支配，" + pct(FO.repro) + " 能在另一半独立数据上重现。在真实队列里我们用三分法把挑选和评价彻底分开："));
add(IMG("f4_threeway.png", 620, 220));
add(CAP("**图 4　三分法。**(a) 第一份拟合规则，第二份挑出支配它的子集，**这些子集固定之后**再拿到从未用过的第三份上重新评价。(b) 在挑选那一份上，规则不被支配的比例只有 " + pct(TW.colon.front_sel) + " 和 " + pct(TW.rott.front_sel) + "；换成未用过的那一份，是 " + pct(TW.colon.front_conf) + " 和 " + pct(TW.rott.front_conf) + "。方向不变——大多数划分里规则仍被支配——但只报挑选那一份的数会把差距夸大近一个量级。预选支配者在未用过那份上仍然支配的比例是 " + pct(TW.colon.repro) + " 和 " + pct(TW.rott.repro) + "。"));

/* ---- 5 ---- */
add(H("五、「多少数据才够」没有通用答案"));
add(P("疗效承诺要多少数据才守得住？在真值已知的单一机制里，这个门槛是清楚的；换一个机制，曲线就换一个位置："));
add(IMG("f5_size.png", 596, 269));
add(CAP("**图 5　拟合集大小与成功概率。**蓝线是单一机制下的曲线，从 " + f0(TS[0].n) + " 人的 " + f(TS[0].p_lower,3) + " 升到 " + f0(TS[TS.length-1].n) + " 人的 " + f(TS[TS.length-1].p_lower,3) + "。橙色竖条是分辨率 IV 部分因子设计的 " + f0(FX.n_scenarios/4) + " 个情景在同一固定拟合规模下的跨度（依次位于 600、2000、6000、18 000 人），横杠是中位数。同一个样本量下，不同机制的成功概率可以从接近 0 到接近 1。跨情景的标准差在 " + f(FX.sd_min,2) + " 到 " + f(FX.sd_max,2) + " 之间；改用事件数或有效样本量分箱也没有把这个离散度压下去（" + f(FX.spread_patients,2) + "、" + f(FX.spread_events,2) + "、" + f(FX.spread_ess,2) + "）——这三个数只是**在这一种分箱方式下数值相近**，不能证明三种「信息货币」等价。"));
add(P("混杂会把门槛推高，而且方向反直觉：同一个结局模型下，随机化那一臂在 5167 人处成功率是 " + f(CFD.rand_5167,3) + "，正确调整的混杂臂只有 " + f(CFD.adj_5167,3) + "；而**漏掉一个混杂因子**反而把表观可靠性拉回随机化水平（" + f(CFD.unmeas_5167,3) + "），同时把估计量的总体极限抬高 " + pct(CL.inflation,1) + "、把选对标准的比例从 " + f(CFD.rec_rand_5167,3) + " 压到 " + f(CFD.rec_unmeas_5167,3) + "。**表面上更可靠恰恰是偏倚的症状**。"));

/* ---- 6 ---- */
add(H("六、明确不主张什么"));
add(P("这篇稿子的价值有一半在边界上。我们**不**说 Trial Pathfinder 是错的——总体层面上我们复现的规则确实收敛到最优标准集。我们**不**说疗效承诺没守住，只说这两个队列判不出来。我们**不**说「无条件的数据量要求不存在」，只说在所考察的机制里、单靠队列规模定不出来，而且我们也说不出决定它的是哪个量。我们**不**把病人重抽范围当作置信区间。Rotterdam 的重叠很差（完整方案的 " + f0(PS1.n) + " 人里有 " + f0(PS1.n_trunc) + " 人的倾向值压在截断边界上，加权后有效样本量只剩 " + pct(PS1.ess_frac,0) + "），所以它所有涉及风险比的结果都只作描述。两个队列都不大，事件数分别只有 " + f0(CF.colon.full_events) + " 和 " + f0(CF.rott.full_events) + "，「判不出来」在相当程度上是**这两份数据的局限**，不是对方法的判决。"));

/* ---- 7 ---- */
add(H("七、给要动手做的人的四步"));
add(P("（1）先把出于安全性、耐受性、给药可行性的标准标记为**不可放宽**，它们不进入优化。（2）看结局之前先算**交互杠杆**（闭式量 L = 1 − p(ij)/p(i) − p(ij)/p(j) + p(ij)，只用入组率、不碰结局数据）和**逻辑蕴含**，把注定无信息的格子去掉。（3）检查完整方案内部的正性／重叠——重叠不好的话，后面所有因果读法都不成立。（4）判断方案里有没有一条标准集中了足够的差异获益；没有的话，就只报告人群扩大，**不报告疗效改善**。"));

/* ---- 8 ---- */
add(H("八、核心数字一览"));
{
  const cell = (pt, z) => z ? (pct(pt,1) + "  " + r80(z)) : pct(pt,1);
  add(TBL(["量（方括号内为重抽病人的中间 80% 范围）","colon","Rotterdam"],
   [["全队列 n / 完整方案保留人数 / 事件", f0(CF.colon.n)+" / "+f0(CF.colon.full_n)+" / "+f0(CF.colon.full_events),
                                          f0(CF.rott.n)+" / "+f0(CF.rott.full_n)+" / "+f0(CF.rott.full_events)],
    ["评分半样本：完整方案 \u2192 规则的合格人数", f0(C.n_full)+" \u2192 "+f0(C.n_rule), f0(RT.n_full)+" \u2192 "+f0(RT.n_rule)],
    ["P(比完整方案纳入更多)", cell(C.more, NS.colon.more), cell(RT.more, NS.rott.more)],
    ["P(样本外风险比更低)", cell(C.lower, NS.colon.lower), cell(RT.lower, NS.rott.lower)],
    ["相同人数下风险比更低（10% 带）", cell(C["hr0.1"], NS.colon["hr0.1"]), cell(RT["hr0.1"], NS.rott["hr0.1"])],
    ["相同人数下 RMST 更好（10% 带）", cell(C["rm0.1"], NS.colon["rm0.1"]), cell(RT["rm0.1"], NS.rott["rm0.1"])],
    ["落在人数—风险比前沿上", cell(C.front_hr, NS.colon.front_hr), cell(RT.front_hr, NS.rott.front_hr)],
    ["三分法：不被任何预选子集支配", pct(TW.colon.front_conf)+"  "+r80(TN.colon.front_conf), pct(TW.rott.front_conf)+"  "+r80(TN.rott.front_conf)],
    ["三分法：同一设计挑选份上的经验口径", pct(TW.colon.front_sel), pct(TW.rott.front_sel)],
    ["三分法：预选支配者在未用份上重现", pct(TW.colon.repro)+"  "+r80(TN.colon.repro), pct(TW.rott.repro)+"  "+r80(TN.rott.repro)],
    ["RMST 规则与发表规则选出同一标准集", pct(C.same_set), pct(RT.same_set)]],
   [4100, 2850, 2850],
   "点估计来自 " + f0(C.R) + "／" + f0(RT.R) + " 次重复划分（三分法 " + f0(TW.colon.R) + "／" + f0(TW.rott.R) + " 次）；方括号是外层按病人 ID 自助重抽 " + f0(NS.colon.B) + " 次后中间 80% 的范围，**不是置信区间**。全部数字由 analysis/out/numbers.json 一处导出，本文档生成时直接读取。", 16));
}

const doc = new Document({
  sections: [{
    properties: { page: {
      size: { width: 12240, height: 15840 },
      margin: { top: 620, bottom: 560, left: 860, right: 860 }
    }},
    children: kids
  }]
});
Packer.toBuffer(doc).then(b => {
  fs.writeFileSync("/home/claude/cn/这项工作做了什么_图解_中文.docx", b);
  console.log("written", b.length, "bytes");
});
