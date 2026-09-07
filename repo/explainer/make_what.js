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
  spacing: { after: o.after ?? 52, line: 240 },
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
      LF = NUM.leverage_forms, OV = NUM.overlap;
const r80 = z => "[" + f(z.ci80[0],2) + "–" + f(z.ci80[1],2) + "]";
const wid = z => f(z.ci80[1] - z.ci80[0], 2);

/* ---------------------------------------------------------------- title */
add(new Paragraph({ spacing:{after:40}, alignment: AlignmentType.CENTER,
  children:[new TextRun({ text:"这篇文章讲了什么",
                          size:28, bold:true, font:CNB })]}));
add(new Paragraph({ spacing:{after:170}, alignment: AlignmentType.CENTER,
  children:[new TextRun({ text:"三页内容提要 · 只讲文章的主张与证据，不讲修改历程",
                          size:17, font:CN, color:"666666" })]}));

/* 1 */
add(H("一、一句话"));
add(P("Trial Pathfinder（Liu 等，Nature 2021）用 Shapley 值挑出「限制了人数、却没给疗效估计带来好处」的入组标准并放宽，宣称由此**同时**得到更多病人和更好的疗效估计。我们把这两个承诺**拆开**做样本外检验，结论是：**前一条基本由方法的构造决定，后一条这两个公开队列判不出来**；而且**单靠队列人数、事件数或有效样本量，定不出「多少数据才够」的通用门槛**。这是一篇否定性的方法学论文。"));

/* 2 */
add(H("二、为什么值得重做一遍"));
add(P("三点。第一，已有的评价都是**样本内**的——在同一批病人身上选标准、又在同一批病人身上打分，这是乐观偏倚的经典场景。第二，「更多病人」和「更好估计」被当成一对结果一起报告，但没有理由认为两者需要同样多的数据，甚至它们根本不是同一类命题。第三，风险比**不可折叠**：只要缩小人群，即使每一层里的条件效应完全没变，风险比也会移动。"));

/* 3 */
add(H("三、怎么做的"));
add(B("样本外", "按治疗组和事件分层随机对半分，只在一半上跑规则选标准，把选出的方案拿到**另一半**上打分，重复 " + f0(C.R) + "（colon）和 " + f0(RT.R) + "（Rotterdam）次。"));
add(B("全子集对照", "规则保留的是标准的一个子集，所以「比完整方案纳入更多人」不可能有别的结果。我们把全部 " + f0(E.nsub) + " 个子集都在留出那一半上打分，在**相同入组人数**下比较，并看规则离可达前沿有多远。"));
add(B("嵌套重抽", "重复划分用的是同一批病人，跨划分的标准误低估总体不确定性。外层按**病人 ID** 对队列自助抽样（避免同一病人的副本落到划分两侧），尝试把划分噪声和病人抽样变异近似分开——对有些量，后者在我们能负担的蒙特卡洛精度下并不可辨识。"));
add(B("模拟与因子设计", "真值已知、评分集固定 10 万人，只让拟合集大小变化；再用分辨率 IV 部分因子设计在六个因子上各取两水平，共 " + f0(FX.n_scenarios/4) + " 个情景，报告固定样本量下的成功概率。"));
add(P("两个公开队列做基准：**colon**（辅助结肠癌随机试验，n = " + f0(CF.colon.n) + "，完整方案保留 " + f0(CF.colon.full_n) + " 人、" + f0(CF.colon.full_events) + " 事件）和 **Rotterdam**（乳腺癌登记队列，n = " + f0(CF.rott.n) + "，保留 " + f0(CF.rott.full_n) + " 人、" + f0(CF.rott.full_events) + " 事件）。事件数比人数小得多，也更要紧。"));

/* 4 */
add(H("四、五个发现"));

add(SUB("1. 「多纳入病人」主要是构造性的"));
add(P("规则保留的是完整方案标准的子集，所以合格人数只增不减——" + f0(C.R) + " 次划分里最小差值恰好是 0，从不为负。文献常报的那个「承诺兑现率」衡量的是规则**移除了起约束作用的标准**的频率，而不是移除得对不对。真正要问的是：在**同样多的人**下，它的疗效估计是否更好。"));

add(SUB("2. 相同入组人数下的优势：这两个队列判不出来"));
add(P("在合格人数相差 10% 以内的子集中，规则的风险比更低的比例是 " + pct(C["hr0.1"]) + "（colon）和 " + pct(RT["hr0.1"]) + "（Rotterdam）；换成 RMST 差是 " + pct(C["rm0.1"]) + " 和 " + pct(RT["rm0.1"]) + "，两个队列**方向相反**。重抽病人时，中间 80% 的范围是 " + r80(NS.colon["hr0.1"]) + " 和 " + r80(NS.rott["hr0.1"]) + "，宽度分别是 " + wid(NS.colon["hr0.1"]) + " 和 " + wid(NS.rott["hr0.1"]) + "。我们把它当作**统计量对队列构成有多敏感**来报告，不当作检验；文中没有做过任何有校准的总体层面比较。"));

add(SUB("3. 规则很少落在前沿上，但那个前沿本身是乐观的"));
add(P("若存在另一个子集，纳入人数不少于规则、风险比不高于规则，就说规则被支配。规则落在前沿上的比例只有 " + pct(C.front_hr) + " 和 " + pct(RT.front_hr) + "，平均有 " + f0(C.n_dom) + " 和 " + f0(RT.n_dom) + " 个子集支配它。但这个前沿是在**同一批留出数据**上从 " + f0(E.nsub) + " 个带噪声的估计里挑最优挑出来的，带「胜者诅咒」式的乐观偏倚：真值已知的模拟里，表面支配者只有 " + pct(FO.true_frac) + " 在总体上真的支配，" + pct(FO.repro) + " 能在另一半独立数据上重现。"));
add(P("在真实队列里我们用**三分法**把这件事做干净：第一份拟合规则，第二份挑出支配它的子集，**这些子集固定之后**再拿到从未用过的第三份上重新评价。规则不被任何预选子集支配的比例是 " + pct(TW.colon.front_conf) + "（colon）和 " + pct(TW.rott.front_conf) + "（Rotterdam），而同一设计下挑选份上的经验口径只有 " + pct(TW.colon.front_sel) + " 和 " + pct(TW.rott.front_sel) + "。预选支配者在未用过那份上仍然支配的比例是 " + pct(TW.colon.repro) + " 和 " + pct(TW.rott.repro) + "。方向不变——大多数划分里规则仍被支配——但只报挑选份上的数会把差距夸大一个量级。"));

add(SUB("4. 疗效估计这条承诺：既不能说守住，也不能说没守住"));
add(P("样本外风险比更低的比例，colon 是 " + f(C.lower,3) + "、Rotterdam 是 " + f(RT.lower,3) + "。重抽病人时它们的中间 80% 范围是 " + r80(NS.colon.lower) + " 和 " + r80(NS.rott.lower) + "，跨过大半个单位区间。所以这两个数是**这两份数据集的性质**，不是对方法成功率的估计；用它们下「承诺没守住」的判断是过头的。相比之下入组承诺稳得多（" + r80(NS.colon.more) + "），因为它是构造性的。"));

add(SUB("5. 「多少数据才够」没有通用答案"));
add(P("在已知真值的模拟里门槛是清楚的：拟合集从 " + f0(TS[0].n) + " 人到 " + f0(TS[TS.length-1].n) + " 人，疗效承诺的成功率从 " + f(TS[0].p_lower,3) + " 升到 " + f(TS[TS.length-1].p_lower,3) + "。但换一个机制，这条曲线就换一个位置。跨 16 个情景，同一固定样本量下成功率的标准差在 " + f(FX.sd_min,2) + " 到 " + f(FX.sd_max,2) + " 之间；改用事件数或有效样本量分箱也没有把这个离散度压下去（" + f(FX.spread_patients,2) + "、" + f(FX.spread_events,2) + "、" + f(FX.spread_ess,2) + "）。这三个数只是**在这一种分箱方式下数值相近**，不能证明三种「信息货币」等价。混杂会把门槛推高：同一个结局模型下，随机化那一臂在 5167 人处成功率是 " + f(CFD.rand_5167,3) + "，正确调整的混杂臂只有 " + f(CFD.adj_5167,3) + "；而**漏掉一个混杂因子**反而把表观可靠性拉回随机化水平（" + f(CFD.unmeas_5167,3) + "），同时把估计量的总体极限抬高 " + pct(CL.inflation,1) + "、把选对标准的比例从 " + f(CFD.rec_rand_5167,3) + " 压到 " + f(CFD.rec_unmeas_5167,3) + "。也就是说，**表面上更可靠恰恰是偏倚的症状**。"));

add(SUB("核心数字一览"));
{
  const cell = (pt, z, k) => z ? (pct(pt,1) + "  " + r80(z)) : pct(pt,k===undefined?1:k);
  add(TBL(["量（方括号内为重抽病人的中间 80% 范围）","colon","Rotterdam"],
   [["全队列：n / 完整方案保留人数 / 事件", f0(CF.colon.n)+" / "+f0(CF.colon.full_n)+" / "+f0(CF.colon.full_events), f0(CF.rott.n)+" / "+f0(CF.rott.full_n)+" / "+f0(CF.rott.full_events)],
    ["评分半样本上：完整方案 → 规则的合格人数（均值）", f0(C.n_full)+" \u2192 "+f0(C.n_rule), f0(RT.n_full)+" \u2192 "+f0(RT.n_rule)],
    ["P(比完整方案纳入更多)", cell(C.more, NS.colon.more), cell(RT.more, NS.rott.more)],
    ["P(样本外风险比更低)", cell(C.lower, NS.colon.lower), cell(RT.lower, NS.rott.lower)],
    ["相同人数下风险比更低（10% 带）", cell(C["hr0.1"], NS.colon["hr0.1"]), cell(RT["hr0.1"], NS.rott["hr0.1"])],
    ["相同人数下 RMST 更好（10% 带）", cell(C["rm0.1"], NS.colon["rm0.1"]), cell(RT["rm0.1"], NS.rott["rm0.1"])],
    ["落在人数—风险比前沿上", cell(C.front_hr, NS.colon.front_hr), cell(RT.front_hr, NS.rott.front_hr)],
    ["三分法：不被任何预选子集支配", pct(TW.colon.front_conf) + "  " + r80(TN.colon.front_conf), pct(TW.rott.front_conf) + "  " + r80(TN.rott.front_conf)],
    ["三分法：同一设计挑选份上的经验口径", pct(TW.colon.front_sel), pct(TW.rott.front_sel)],
    ["三分法：预选支配者在未用份上重现", pct(TW.colon.repro) + "  " + r80(TN.colon.repro), pct(TW.rott.repro) + "  " + r80(TN.rott.repro)]],
   [4000, 2900, 2900],
   "点估计来自 " + f0(C.R) + "（colon）／" + f0(RT.R) + "（Rotterdam）次重复划分，三分法为 " + f0(TW.colon.R) + "／" + f0(TW.rott.R) + " 次。方括号是外层按病人 ID 自助抽样后中间 80% 的范围，**不是置信区间**：覆盖率未经验证，全文没有结论建立在它是否跨过某个值之上。Rotterdam 涉及风险比的结果只作描述。", 16));
}

/* 5 */
add(H("五、文章明确不主张什么"));
add(P("这一节很重要，因为这篇稿子的价值有一半在边界上。我们**不**说 Trial Pathfinder 是错的——总体层面上我们复现的规则确实收敛到最优标准集。我们**不**说疗效承诺没守住，只说这两个队列判不出来。我们**不**说「无条件的数据量要求不存在」，只说在所考察的机制里、单靠队列规模定不出来，而且我们也说不出决定它的是哪个量。我们**不**把病人重抽范围当作置信区间：它们的覆盖率没有对着已知总体验证过，流程里还有 Shapley 取符号和前沿挑选两个非光滑步骤，所以全文没有任何结论建立在「范围是否跨过 0.5 或 0」之上；等效性方面只说明未预设等效界值、也未做等效性检验。Rotterdam 的重叠很差（完整方案的 " + f0(PS1.n) + " 人里有 " + f0(PS1.n_trunc) + " 人的倾向值压在截断边界上，加权后有效样本量只剩 " + pct(PS1.ess_frac,0) + "），所以它所有涉及风险比的结果都只作描述。"));

/* 6 */
add(H("六、三个能被单独拿走用的副产品"));
add(B("交互杠杆", "闭式量 L = 1 − p(ij)/p(i) − p(ij)/p(j) + p(ij)，**只用入组率、不碰结局数据**，动手前就能算。AND／OR／XOR 三种形式的系数分别是 (1−q)²、−(1−q)²、−2(1−q)²。杠杆低不等于「结构上测不出」，而是按已知因子的衰减。"));
add(B("蕴含检测器", "若标准 i 逻辑上蕴含 j，这对的交互是算术恒等式，无论样本量多大都无信息，必须从检验族里剔除。"));
add(B("双估计量并行", "同时报风险比和 RMST 差。条件风险比固定为 0.6 的模拟里，一条没有改变任何人相对获益的标准，其对数风险比 Shapley 值却随预后异质性从 " + f(NUM.noncollapse.rows[0].phi_logHR,4) + " 移到 " + f(NUM.noncollapse.rows[NUM.noncollapse.rows.length-1].phi_logHR,3) + "（大体随异质性增大，但不严格单调）；异质性为零时假象消失。这就是不可折叠性在这套流程里的具体表现。"));

/* 7 */
add(H("七、给要动手做的人的四步"));
add(P("（1）先把出于安全性、耐受性、给药可行性的标准标记为**不可放宽**，它们不进入优化。（2）看结局之前先算交互杠杆和逻辑蕴含，把注定无信息的格子去掉。（3）检查完整方案内部的正性／重叠——重叠不好的话，后面所有因果读法都不成立。（4）判断方案里有没有一条标准集中了足够的差异获益；没有的话，就只报告人群扩大，**不报告疗效改善**。"));

/* 8 */
add(H("八、局限"));
add(P("两个队列都不大，事件数分别只有 " + f0(CF.colon.full_events) + " 和 " + f0(CF.rott.full_events) + "，所以「判不出来」在相当程度上是**这两份数据的局限**，不是对方法的判决——这一点我们反复写明。标准是从可得协变量构造的，不是任何试验的方案原文，所以这研究的是**流程的一般行为**，不是对某个试验入组标准的评价。模拟只覆盖我们能想到的机制，因子设计只有 16 个固定设计点。"));

const doc = new Document({
  sections: [{
    properties: { page: {
      size: { width: 12240, height: 15840 },
      margin: { top: 640, bottom: 600, left: 900, right: 900 }
    }},
    children: kids
  }]
});
Packer.toBuffer(doc).then(b => {
  fs.writeFileSync("/home/claude/cn/文章讲了什么_中文.docx", b);
  console.log("written", b.length, "bytes");
});
