const fs = require("fs");
const d = require("docx");
const { Document, Packer, Paragraph, TextRun, AlignmentType,
        Table, TableRow, TableCell, WidthType, ShadingType, BorderStyle } = d;

const CN  = "Noto Serif CJK SC";
const CNB = "Noto Sans CJK SC";
const NUM = JSON.parse(fs.readFileSync("/home/claude/repo/analysis/out/numbers.json","utf8"));
const FA = NUM.factorial, BY = FA.by, RB = NUM.random, DP = NUM.dependence,
      RC = NUM.recovery, E = NUM.efficiency, PA = NUM.pareto, CONC = NUM.concentration,
      FX = NUM.fixedn || {};
const PR = NUM.primary || {}, C = PR.colon || {}, RT = PR.rott || {},
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
  spacing: { after: o.after ?? 78, line: 262 },
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
  spacing: { after: 60, line: 268 }, alignment: AlignmentType.JUSTIFIED,
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

/* ---------------------------------------------------------------- title */
add(new Paragraph({ spacing:{after:40}, alignment: AlignmentType.CENTER,
  children:[new TextRun({ text:"数据驱动放宽临床试验入组标准：这项工作做了什么",
                          size:28, bold:true, font:CNB })]}));
add(new Paragraph({ spacing:{after:200}, alignment: AlignmentType.CENTER,
  children:[new TextRun({ text:"三页解读 · 第二轮大修版（中心结论已再次改变）",
                          size:17, font:CN, color:"666666" })]}));

/* ---------------------------------------------------------------- 1 */
add(H("一、一句话"));
add(P("Trial Pathfinder（Liu 等，Nature 2021）用 Shapley 值找出「限制了人数却没带来疗效」的入组标准并放宽，宣称由此既能多纳入病人、又能得到更好的疗效估计。我们把这两个承诺分开做了样本外检验，四轮审稿之后的结论是：**多纳入病人这一条主要由规则的构造决定**——把规则放到「所有 512 个子集」里去比，在相同入组人数下它是否还有优势，**这两个队列的规模判不出来**：点估计在 colon 是 " + pct(C["hr0.1"]) + "、Rotterdam 是 " + pct(RT["hr0.1"]) + "，但把不确定性做到病人层面之后，区间都包含 0.5。它落在「人数—风险比」经验前沿上的比例只有 " + pct(C.front_hr) + " 和 " + pct(RT.front_hr) + "；不过这个前沿本身是从同一批留出数据里挑最优挑出来的，带乐观偏倚，我们另外量化了这个偏倚有多大。至于疗效估计要多少数据才够，我们的答案是**给不出来**，而且我们也**说不出决定它的是哪个量**——第三轮我们曾说是「最强的那条稀释性标准」，这一条已经撤回。这是一个否定性结论，也是我们认为最有用的一条。", { after: 140 }));

/* ---------------------------------------------------------------- 2 */
add(H("二、原文做了什么，我们问了什么"));
add(P("Trial Pathfinder 把每条入组标准看成合作博弈的参与者，用 Shapley 值分摊各自对疗效估计的边际贡献，值为负的保留、其余放宽；在一个肺癌真实世界数据库上它同时放大了合格人群、降低了风险比。"));
add(P("我们注意到三件事：已有评价都是样本内的；「更多病人」和「更好估计」被当成一对报告，但没有理由认为两者需要同样多的数据、甚至是同一类命题；风险比不可折叠，缩小人群本身就会让它移动。"));

/* ---------------------------------------------------------------- 3 */
add(H("三、怎么做的"));
add(B("样本外", "按治疗组和事件分层随机对半分，只在一半上选标准，再把方案拿到另一半上评分，重复 400–500 次。"));
add(B("全子集对照", "既然规则保留的是标准的子集，「比完整方案纳入更多」不可能有别的结果。所以把全部 512 个子集都在留出的一半上评分，在**相同入组人数**下比较，并看规则离可达前沿有多远。"));
add(B("嵌套自助", "重复划分用的是同一批病人，跨划分标准误低估了总体不确定性。外层对队列自助抽样（按病人 ID 划分，避免泄漏），把算法稳定性和总体不确定性分开。"));
add(B("因子设计模拟", "评分集固定 10 万人、真值已知，只让拟合集变化；再用分辨率 IV 部分因子设计在六个因子上各取两水平共 16 个情景，报告**固定样本量下的成功概率**。"));
add(P("两个公开队列做基准：colon（辅助结肠癌随机试验，n = 619，完整方案保留 176 人 / 56 事件）和 Rotterdam（乳腺癌登记队列，n = 2982，保留 419 人 / 191 事件）。事件数比人数小得多，也更要紧。"));

/* ---------------------------------------------------------------- 4 */
add(H("四、五个发现"));

add(SUB("1. 「多纳入病人」主要是构造性的；规则很少落在经验前沿上，但这个前沿本身是乐观的"));
add(P("500 次划分里，合格人数的最小差值恰好是 0，从不为负——这正是子集关系决定的。文献一直在报的那个 0.978「承诺兑现率」，衡量的是规则移除起约束作用的标准的频率，而不是移除得对不对。"));
add(P("公平的对照是把**全部 512 个子集**都在留出的那一半上评分（第一轮用「随机去掉同样条数」不公平，因为两者纳入的人数差很多）。在合格人数相差 10% 以内的子集中，规则的风险比更低的比例是 " + pct(C["hr0.1"]) + "（colon）和 " + pct(RT["hr0.1"]) + "（Rotterdam）" + (NS.colon ? "，病人层面的区间分别是 [" + f(Math.max(0,C["hr0.1"]-1.96*NS.colon["hr0.1"].sd_outer),2) + ", " + f(Math.min(1,C["hr0.1"]+1.96*NS.colon["hr0.1"].sd_outer),2) + "] 和 [" + f(Math.max(0,RT["hr0.1"]-1.96*NS.rott["hr0.1"].sd_outer),2) + ", " + f(Math.min(1,RT["hr0.1"]+1.96*NS.rott["hr0.1"].sd_outer),2) + "]" : "") + "；在 RMST 上是 " + pct(C["rm0.1"]) + " 和 " + pct(RT["rm0.1"]) + "。**所有这些区间都包含 0.5**——既证不出优势，也证不出没有优势。这是我们第三轮之后最重要的一处措辞改动。"));
add(P("前沿分析：如果存在另一个子集，纳入人数不少于规则、风险比不高于规则，就说规则被支配了。规则**落在前沿上的比例只有 " + pct(C.front_hr) + " 和 " + pct(RT.front_hr) + "**，中位有 " + f0(C.n_dom) + " 和 " + f0(RT.n_dom) + " 个子集支配它。"));
add(P("但审稿人第三轮指出：这个前沿是**在同一批留出数据上从 512 个带噪声的估计里挑最优挑出来的**，带「胜者诅咒」式的乐观偏倚。真值已知的模拟给出量级：表面支配者里只有 " + (FO?pct(FO.true_frac):"—") + " 在总体上真的支配，" + (FO?pct(FO.repro):"—") + " 能在另一半独立数据上重现。" + (TW ? "第四轮我们又在真实队列里做了**三分法**（一份拟合、一份挑支配者、一份完全没用过的做检验）：colon 中位 " + f0(TW.colon.dom_sel) + " 个表面支配者里，只有 " + pct(TW.colon.repro) + " 在没用过的那份上仍然支配；不过规则落在前沿上的比例本身变化不大（" + pct(TW.colon.front_sel) + " → " + pct(TW.colon.front_test) + "）。" : "") + "所以现在的说法是：规则离**这个带乐观偏倚的经验最优**有相当距离；它离真正的最优方案有多远，这两个队列答不了。"));

add(SUB("2. 疗效估计这条承诺：观察到的比例偏低，但这既不能说明没守住，也不能说明守住了"));
add(TBL(["样本外对比","colon (n=619)","Rotterdam (n=2982)"],
 [["终点；截断时间；划分次数", C.time_var+"，"+C.status_var+"；"+f0(C.tau)+" 天；"+C.R, RT.time_var+"，"+RT.status_var+"；"+f0(RT.tau)+" 天；"+RT.R],
  ["多纳入人数","+"+f0(C.d_n),"+"+f0(RT.d_n)],
  ["风险比之差；P(更低)",(C.d_hr>0?"+":"")+f(C.d_hr,3)+"；"+f(C.lower,3),(RT.d_hr>0?"+":"")+f(RT.d_hr,3)+"；"+f(RT.lower,3)],
  ["RMST 之差；P(更大)",(C.d_rm>0?"+":"")+f(C.d_rm,1)+" 天；"+f(C.greater,3),(RT.d_rm>0?"+":"")+f(RT.d_rm,1)+" 天；"+f(RT.greater,3)],
  ["P(更低) 的 95% 区间","[" + f(DP.colon.ci_lower[0],2) + ", " + f(DP.colon.ci_lower[1],2) + "]",
                          "[" + f(DP.rott.ci_lower[0],2) + ", " + f(DP.rott.ci_lower[1],2) + "]"]],
 [2900,2300,2300],
 "最后一行来自嵌套自助（" + DP.colon.B + " 次外层重抽 × " + DP.colon.R_IN + " 次内层划分）。第二轮审稿指出我们原来的实现有泄漏：自助样本里同一个病人的多个副本可能被分到划分的两侧。改成按病人 ID 划分后区间反而变窄了。跨划分标准误 " + f(DP.colon.naive_lower,4) + "，其中真正的跨队列成分是 " + f(DP.colon.between_lower,3) + "——是前者的 **" + f(DP.colon.ratio_between_lower,0) + " 倍**。"));
add(P("区间几乎覆盖了整个取值范围：colon 这个队列分不清「十次里有九次守住」和「一次都守不住」。" + f(C.lower,3) + " 和 " + f(RT.lower,3) + " 是这两个数据集的性质，不是对方法成功率的估计；**用它们下「承诺没守住」的判断是过头的**，第四轮审稿在这点上是对的，全文已改。"));

add(SUB("3. 关键不是队列多大——但关键到底是什么，我们说不出来"));
add(P("第一轮我们说：16 个情景里 9 个在 18000 人以内达不到阈值，删失几乎全落在「效应修饰是否集中」这个因子上。审稿人指出两个问题。一是只用「能观察到阈值」的 6 个情景算离散度，是有选择偏倚的；改用**固定样本量下的成功概率**（16 个情景全都有值，不存在删失）后，我们原来说的「事件数、有效样本量比人数更不稳」**不成立**——按三种口径分箱，组内离散度分别是 " + f(FX.spread_patients,2) + "、" + f(FX.spread_events,2) + "、" + f(FX.spread_ess,2) + "，无法区分。这条建议已撤回。"));
add(P("二是「集中 vs 分散」这个对比本身可能是机械的：我们把每条标准的系数直接除以份数，分散那一臂的**稀释系数**也跟着从 0.32 掉到 0.128，而稀释正是规则必须检出的东西（只有放宽一条「选进了获益更少的人」的标准，风险比才会降）。审稿人是对的。"));
if (CONC && CONC.A_dil1_enr1) {
  const g = k => CONC[k].rows.map(r => f(r.p_lower,2)).join(" / ");
  add(P("我们另做一组模拟把两者拆开：总效应修饰固定为 0.85，只改分布方式。稀释系数固定 0.30 时，在 600/2000/6000/18000 人处的成功概率，富集集中在一条是 " + g("A_dil1_enr1") + "，摊到两条是 " + g("B_dil1_enr2") + "，摊到四条是 " + g("C_dil1_enr4") + "；把总量不变的稀释劈成两半后变成 " + g("D_dil2_enr1") + "。"));
add(P("第三轮和第四轮又推翻了我们从这组数字里读出的两条结论。一是我们说「把富集摊薄没关系」，**加上蒙特卡洛区间之后它其实是有帮助的**：在 6000 人处提高了 0.21，区间 [0.08, 0.34]。二是我们说「决定数据量的是最强稀释系数的大小」，**这一条也撤回**：把稀释系数减半的同时，可达的改进幅度也差不多减半了（0.0203 → 0.0098），系数和「奖品」在这个设计里是绑在一起的，谁的功劳分不开。现在只保留更弱的说法：数据量要求取决于稀释信号相对于噪声的强度，而这个强度正是分析本身要估计的东西，所以无条件的门槛给不出来——和功效计算要先假定效应量是同一种处境。正文表 2 现已标注为**敏感性分析**，不再当作可以读出样本量要求的设计曲线。我们试过的最有希望的候选量是「标准特异的信噪比」（最强稀释标准的总体 Shapley 值除以它在该拟合规模下估计的标准差）：在 12 个模拟格子上它对成功率的排序（Spearman " + (SC?f(SC.sp_snr,2):"—") + "）好于单纯的样本量（" + (SC?f(SC.sp_n,2):"—") + "）。但 12 个格子不足以确立一个决定性的量，而且信噪比本身就随样本量上升、两者在设计上相关，所以只作为方向报告。"));
}
add(P("所以真正决定数据需求的是**最强那条稀释性标准的系数大小**。而这恰恰是分析本身要估计的量——正性/重叠、逻辑蕴含、交互杠杆都能事前算，唯独它不能。因此无论用人数、事件数还是有效样本量，都给不出一个事前的数据需求。这就是本文的中心结论，它是否定性的。"));

add(SUB("4. 低于阈值时，选出的方案会比原方案略差"));
add(P("用「后悔值」来衡量。先把它定义清楚：这是在对数风险比这一个目标上，所选方案与「使风险比最低的那个子集」之间的差距，不考虑人数、安全性或任何别的临床目标；不同方案对应不同目标人群，所以「后悔值更大」意思是离最低风险比更远，不等于对病人更差。完整方案自己的后悔值是 " + f(NUM.recovery_full_regret,4) + "。规则在 " + f0(RC[0].n) + " 个拟合病人时的后悔值是 " + f(RC[0].regret,4) + "，**比完整方案还大**；约 1000 人处打平；到 " + f0(RC[RC.length-1].n) + " 人降到 " + f(RC[RC.length-1].regret,4) + "。也就是说，对这个规模的队列，在这一个目标上，预期结果不是「改进幅度较小」，而是**得到一个略微更偏离最优的方案**，并且把更多病人纳入其中。这是关于一个生成模型、一个单目标的陈述，不是说该方案在临床上更差。"));

add(SUB("5. 混杂调整不充分时，方法看起来更成功，实际选得更差"));
add(P("三条臂共享同一个结局模型，所以真实因果效应在三条臂里完全一样，变的只是治疗分配和能调整什么。正确调整混杂后，5167 人处的成功概率从随机化的 0.937 降到 0.808——大约需要两倍样本。但从倾向性模型里漏掉一个混杂因子，概率回到 0.936，看上去和随机化一样好。真相是：被检测的那个量本身被偏倚放大了（0.0310 → 0.0408，大 32%），而**正确选中标准集的概率同时从 0.280 掉到 0.116**。看起来一样可靠，但正确选中率下降了一半以上。"));
add(P("推论：在真实世界数据上看到方法「表现良好」，不是调整充分的证据。可用的敏感性分析是比较不同丰富程度的调整集、看差距是否随调整变充分而缩小——但这只在新增变量确实是混杂因子时成立；加进工具变量会放大偏倚，加进对撞因子会制造偏倚。它是一个值得留意的警报，不是一个能定案的检验。"));

/* ---------------------------------------------------------------- 5 */
add(H("五、四轮审稿指出的错误"));
add(B("错误一", "原稿说 Shapley 效率公理在风险比尺度上只近似成立，**不成立**：穷举枚举下任何尺度都精确成立（验证到 " + E.err_log.toExponential(1) + " 和 " + E.err_hr.toExponential(1) + "）。尺度决定的只是分解哪个总量。"));
add(B("错误二", "「多纳入病人」被当成经过验证的收益来写，其实是构造性的（见发现 1）。已全文改写并补上随机放宽对照。"));
add(B("漏查", "Rotterdam 在完整方案内存在**正性假设问题**：419 人里 132 个倾向值顶在截断边界，加权有效样本量只有名义的 37%；化疗几乎只给了年轻绝经前女性。该队列现在全部按描述性报告，因果解读只靠随机化队列和模拟。"));

add(B("错误三", "第二轮：嵌套自助有泄漏——自助样本里同一病人的副本可能落到划分两侧。已按病人 ID 划分并加断言，重算后区间变窄。"));
add(B("错误四", "第二轮：只用「能观察到阈值」的 6 个情景算离散度有选择偏倚，据此得出的「事件数比人数更不稳」**不成立**，已撤回。"));
add(B("错误五", "第二轮：非可折叠性一节写「被选中的低风险人群有更多绝对生存空间可赚」，**方向反了**——RMST 差 0.664→0.599、0.425→0.322，低风险人群绝对获益**更少**。"));

add(B("错误六", "第三轮：我们写「把富集摊薄没关系」，其实是有帮助的（+0.21，区间 [0.08, 0.34]），已改。同一节里「稀释系数是决定性的量」也撤回，因为系数和可达改进幅度在设计上是绑定的。"));
add(B("错误七（最严重）", "第四轮：审稿人指出正文和补充材料对同一个量给出不同的数，我们上一轮把它解释成蒙特卡洛噪声。查下来真正的原因要糟得多——第二、三轮新增的 **11 个脚本把 Rotterdam 的终点写成了「无复发生存时间 + 死亡指示」在 1825 天截断**，而表 1 用的是正确的「死亡时间 + 死亡指示」在 2555 天截断。时间和事件指示不配对，会把事件时间系统性地缩短。这不是两次运行的差异，是两个不同的终点。已全部改正并重算。"));
add(B("结构性补救", "现在所有真实队列的点估计都由**一个脚本 analysis/primary.R 一次算出**并写进同一个结果文件，摘要、正文、表 1、补充材料全部从它读数，没有一处手抄；嵌套自助只负责不确定性。导出时有三条断言（终点配对、截断时间、两套估计的一致性），违反即中止构建。"));

/* ---------------------------------------------------------------- 6 */
add(H("六、三个能被单独拿走用的副产品"));
add(B("交互杠杆", "闭式量 L = 1 − p(ij)/p(i) − p(ij)/p(j) + p(ij)，只用入组率、不用结局数据。原稿把「杠杆低」说成「结构上测不出」**不够准确**：它是按已知因子的衰减，信号仍取决于效应大小和样本量。真正测不出的只有逻辑蕴含。AND/OR/XOR 三种形式的系数分别是 (1−q)²、−(1−q)²、−2(1−q)²。"));
add(B("蕴含检测器", "若标准 i 逻辑上蕴含 j，这对的交互是算术恒等式，是唯一无论样本量多大都无信息的格子，必须从检验族里剔除。"));
add(B("双估计量并行", "同时报告风险比和 RMST 差。条件风险比固定为 0.6 的模拟里，一条标准没改变任何人的相对获益，它在对数风险比上的 Shapley 值却随预后异质性从 −0.0008 长到 −0.066；异质性为零时假象消失。RMST 差的移动则是真实的。"));

/* ---------------------------------------------------------------- 7 */
add(H("七、这篇文章的定位"));
add(P("它不是在说 Trial Pathfinder 错了。原文的做法在它自己的数据规模上有其道理，我们复制出来的规则在总体层面确实收敛到最优标准集。我们做的是：把两个被捆绑报告的承诺拆开，指出一个是构造性的、另一个的成立与否**这个规模的公开队列判不出来**；说明数据量要求为什么不能无条件地给；并提供三个动手前就能算的诊断量。"));

/* ---------------------------------------------------------------- 8 */
add(H("八、可能会被问到的三个问题"));
add(SUB("既然规则在入组上不优于随机放宽，那它的价值在哪里？"));
add(P("因为入组人数通常不是唯一目的。随机放宽确实能多招人，但招进来的人群里疗效估计会更差（colon 平均风险比 " + f(RB.colon.hr_rand,3) + " vs 规则的 " + f(RB.colon.hr_rule,3) + "，Rotterdam " + f(RB.rott.hr_rand,3) + " vs " + f(RB.rott.hr_rule,3) + "）。规则换来的可能是估计质量，代价是比它能做到的少招一些人。需要说清楚的是：在**相同入组人数**下它是否仍有这个优势，这两个队列的规模判不出来（区间都包含 0.5）。我们认为这个取舍值得明确报告，而只跟完整方案比时它不会显现出来。"));
add(SUB("实际操作上我该怎么做？"));
add(P("四步。（1）先把出于安全性、耐受性、给药可行性、药理考虑的标准标记为**不可放宽**。（2）看结局之前先算交互杠杆和逻辑蕴含。（3）检查完整方案内部的正性/重叠。（4）判断方案里有没有一条标准集中了足够差异获益；没有的话，就只报告人群扩大，不报告疗效改善。"));

const doc = new Document({
  sections: [{
    properties: { page: {
      size: { width: 12240, height: 15840 },
      margin: { top: 760, bottom: 720, left: 1000, right: 1000 }
    }},
    children: kids
  }]
});
Packer.toBuffer(doc).then(b => {
  fs.writeFileSync("/home/claude/cn/文章解读_中文.docx", b);
  console.log("written", b.length, "bytes");
});
