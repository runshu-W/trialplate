import json, numpy as np, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
import csv

plt.rcParams.update({
    "font.family": "Noto Sans CJK JP",
    "axes.unicode_minus": False,
    "axes.edgecolor": "#8A8A8A", "axes.linewidth": 0.8,
    "xtick.color": "#444", "ytick.color": "#444",
    "xtick.labelsize": 8.5, "ytick.labelsize": 8.5,
    "axes.labelsize": 9.5, "axes.titlesize": 10.5,
})
BLUE="#1A4B7A"; RED="#C1443B"; GREY="#9AA5B1"; LGREY="#D6DCE2"; GREEN="#2E7D68"; ORANGE="#D08327"
N = json.load(open("/home/claude/repo/analysis/out/numbers.json"))
W = 6.6; DPI = 200
def save(fig, name):
    fig.savefig(name, dpi=DPI, bbox_inches="tight", facecolor="white")
    plt.close(fig); print("wrote", name)

# ---------------------------------------------------------------- 图 1 设计
def box(ax,x,y,w,h,t,fc="#FFFFFF",ec=BLUE,fs=8.5,bold=False,tc="#222"):
    ax.add_patch(FancyBboxPatch((x,y),w,h,boxstyle="round,pad=0.012,rounding_size=0.02",
                                fc=fc,ec=ec,lw=1.0))
    ax.text(x+w/2,y+h/2,t,ha="center",va="center",fontsize=fs,color=tc,
            fontweight="bold" if bold else "normal",linespacing=1.5)
def arrow(ax,x1,y1,x2,y2,c=GREY,style="-|>",lw=1.0,ls="-"):
    ax.add_patch(FancyArrowPatch((x1,y1),(x2,y2),arrowstyle=style,mutation_scale=11,
                                 color=c,lw=lw,linestyle=ls,shrinkA=1,shrinkB=1))

fig,ax = plt.subplots(figsize=(W,2.45))
ax.set_xlim(0,1); ax.set_ylim(0,1); ax.axis("off")
box(ax,0.005,0.40,0.125,0.28,"一个队列\n(colon /\nRotterdam)",fc="#F4F7FA",fs=8.0)
arrow(ax,0.135,0.54,0.178,0.54)
box(ax,0.185,0.56,0.135,0.22,"拟合半样本",fc="#EAF1F7",fs=8.2)
box(ax,0.185,0.26,0.135,0.22,"留出半样本",fc="#EAF1F7",fs=8.2)
ax.text(0.2525,0.815,"按治疗组与事件分层随机对半",ha="center",fontsize=7.4,color="#666")
arrow(ax,0.325,0.67,0.368,0.67)
box(ax,0.375,0.56,0.185,0.22,"跑规则：Shapley 值\n为负的标准保留",fc="#FFFFFF",ec=RED,fs=8.2)
arrow(ax,0.4675,0.555,0.4675,0.485,c=RED,ls=(0,(3,2)))
ax.text(0.482,0.522,"选出的方案",fontsize=7.4,color=RED,va="center")
arrow(ax,0.325,0.37,0.368,0.37)
box(ax,0.375,0.26,0.185,0.22,"在留出半样本上打分\n与完整方案对比",fc="#FFFFFF",ec=BLUE,fs=8.2)
arrow(ax,0.565,0.37,0.607,0.37)
box(ax,0.613,0.26,0.135,0.22,"两个承诺\n各自的结果",fc="#EAF1F7",fs=8.2)
ax.annotate("", xy=(0.20,0.175), xytext=(0.735,0.175),
            arrowprops=dict(arrowstyle="<|-|>",color=GREY,lw=0.9))
ax.text(0.4675,0.115,"整套流程重复 %d 次（Rotterdam %d 次）" % (N["primary"]["colon"]["R"], N["primary"]["rott"]["R"]),
        ha="center",fontsize=7.8,color="#555")
ax.add_patch(FancyBboxPatch((0.175,0.155),0.585,0.68,boxstyle="round,pad=0.006,rounding_size=0.02",
                            fc="none",ec=ORANGE,lw=0.9,ls=(0,(4,3))))
arrow(ax,0.765,0.50,0.815,0.50,c=ORANGE)
box(ax,0.822,0.26,0.175,0.50,"外层：\n按病人 ID 对整个\n队列自助重抽 %d 次，\n每次把左边整套\n流程重跑一遍" % N["nested"]["colon"]["B"],
    fc="#FDF6EC",ec=ORANGE,fs=8.0)
save(fig,"f1_design.png")

# ---------------------------------------------------------------- 图 2 全子集
rows=list(csv.DictReader(open("subsets_colon.csv")))
n=np.array([float(r["n"]) for r in rows]); h=np.array([float(r["loghr"]) for r in rows])
isr=np.array([r["is_rule"]=="1" for r in rows]); isf=np.array([r["is_full"]=="1" for r in rows])
dom=np.array([r["dominates"]=="1" for r in rows])
other=~(isr|isf|dom)
fig,ax=plt.subplots(figsize=(W,3.0))
ax.scatter(n[other],h[other],s=9,c=LGREY,edgecolors="none",label="其余子集",zorder=2)
ax.scatter(n[dom],h[dom],s=13,c=GREEN,edgecolors="none",alpha=.85,
           label="支配规则的子集（%d 个）"%dom.sum(),zorder=3)
ax.scatter(n[isf],h[isf],s=52,marker="s",c="white",edgecolors=BLUE,linewidths=1.4,zorder=5)
ax.scatter(n[isr],h[isr],s=95,marker="*",c=RED,edgecolors="white",linewidths=.6,zorder=6)
o=np.argsort(-n); fx,fy=[],[]; best=np.inf
for i in o:
    if h[i]<best: best=h[i]; fx.append(n[i]); fy.append(h[i])
ax.step(fx,fy,where="post",color=BLUE,lw=1.0,ls=(0,(4,2)),zorder=4,label="可达前沿")
nr=n[isr][0]; hr=h[isr][0]
ax.add_patch(plt.Rectangle((nr,ax.get_ylim()[0]),max(n)-nr,hr-ax.get_ylim()[0],
                           fc=GREEN,alpha=.06,zorder=1))
ax.set_xlabel("留出半样本上的合格人数"); ax.set_ylabel("留出半样本上的对数风险比")
nf=n[isf][0]; hf=h[isf][0]
ax.annotate("完整方案", xy=(nf,hf), xytext=(nf+9,hf-0.055), fontsize=8, color=BLUE,
            arrowprops=dict(arrowstyle="-",color=BLUE,lw=.7))
ax.annotate("规则选出的方案", xy=(nr,hr), xytext=(nr-58,hr+0.075), fontsize=8, color=RED,
            arrowprops=dict(arrowstyle="-",color=RED,lw=.7))
ax.legend(fontsize=7.6,frameon=False,loc="lower right",ncol=2,handletextpad=.4,columnspacing=1.1)
for s in ("top","right"): ax.spines[s].set_visible(False)
ax.grid(axis="y",color="#EEE",lw=.7)
ax.set_axisbelow(True)
save(fig,"f2_subsets.png")

# ---------------------------------------------------------------- 图 3 重抽范围
NS=N["nested"]; P=N["primary"]
items=[("P(比完整方案纳入更多)","more"),("P(样本外风险比更低)","lower"),
       ("相同人数下风险比更低","hr0.1"),("相同人数下 RMST 更好","rm0.1"),
       ("落在人数—风险比前沿上","front_hr")]
fig,ax=plt.subplots(figsize=(W,2.7))
ys=np.arange(len(items))[::-1]
for j,(lab,k) in enumerate(items):
    y=ys[j]
    for c,off,col in ((("colon"),+0.16,BLUE),(("rott"),-0.16,ORANGE)):
        z=NS[c][k]; pt=P[c][k]
        ax.plot(z["ci"],[y+off]*2,color=col,lw=1.0,alpha=.45,zorder=2)
        ax.plot(z["ci80"],[y+off]*2,color=col,lw=3.4,solid_capstyle="butt",alpha=.9,zorder=3)
        ax.plot([pt],[y+off],marker="|",ms=9,mew=1.6,color="white",zorder=5)
        ax.plot([pt],[y+off],marker="o",ms=4.2,color=col,zorder=4)
ax.axvline(0.5,color=RED,lw=.9,ls=(0,(4,3)),zorder=1)
ax.text(0.5,len(items)-0.42,"0.5",color=RED,fontsize=8,ha="center")
ax.set_yticks(ys); ax.set_yticklabels([l for l,_ in items],fontsize=8.5)
ax.set_xlim(-0.02,1.02); ax.set_xlabel("比例")
for s in ("top","right","left"): ax.spines[s].set_visible(False)
ax.tick_params(axis="y",length=0)
ax.grid(axis="x",color="#EEE",lw=.7); ax.set_axisbelow(True)
from matplotlib.lines import Line2D
ax.legend(handles=[Line2D([],[],color=BLUE,lw=3.4,label="colon"),
                   Line2D([],[],color=ORANGE,lw=3.4,label="Rotterdam"),
                   Line2D([],[],color="#777",lw=1.0,alpha=.5,label="2.5–97.5% 尾段")],
          fontsize=7.8,frameon=False,ncol=3,loc="lower center",bbox_to_anchor=(0.5,-0.42))
save(fig,"f3_ranges.png")

# ---------------------------------------------------------------- 图 4 三分法
TW=N["threeway"]
fig=plt.figure(figsize=(W,2.5))
axA=fig.add_axes([0.0,0.12,0.53,0.82]); axA.set_xlim(0,1); axA.set_ylim(0,1); axA.axis("off")
box(axA,0.02,0.62,0.28,0.26,"第一份\n拟合规则",fc="#EAF1F7",fs=8.2)
box(axA,0.36,0.62,0.28,0.26,"第二份\n挑出支配它的子集",fc="#EAF1F7",fs=8.2)
box(axA,0.70,0.62,0.28,0.26,"第三份\n从未用过",fc="#FDF6EC",ec=ORANGE,fs=8.2)
arrow(axA,0.305,0.75,0.355,0.75); arrow(axA,0.645,0.75,0.695,0.75)
axA.text(0.50,0.50,"子集在这一步之后就固定了",ha="center",fontsize=7.8,color=RED)
arrow(axA,0.50,0.46,0.84,0.36,c=RED,ls=(0,(3,2)))
box(axA,0.62,0.06,0.36,0.24,"在第三份上重新评价\n这些预先选定的子集",fc="#FFFFFF",ec=ORANGE,fs=8.2)
axA.text(0.0,0.30,"(a) 三分法把「挑选」和「评价」分开",fontsize=8.6,color="#333",ha="left")
axB=fig.add_axes([0.66,0.24,0.33,0.62])
lab=["colon","Rotterdam"]; x=np.arange(2); w=0.36
sel=[TW["colon"]["front_sel"],TW["rott"]["front_sel"]]
conf=[TW["colon"]["front_conf"],TW["rott"]["front_conf"]]
axB.bar(x-w/2,[s*100 for s in sel],w,color=LGREY,label="挑选那一份（乐观）")
axB.bar(x+w/2,[c*100 for c in conf],w,color=ORANGE,label="未用过那一份")
for i in range(2):
    axB.text(i-w/2,sel[i]*100+0.6,"%.1f%%"%(sel[i]*100),ha="center",fontsize=8,color="#555")
    axB.text(i+w/2,conf[i]*100+0.6,"%.1f%%"%(conf[i]*100),ha="center",fontsize=8,color=ORANGE)
axB.set_xticks(x); axB.set_xticklabels(lab,fontsize=8.5)
axB.set_ylabel("规则不被支配的划分比例 (%)",fontsize=8.0,labelpad=2)
axB.set_ylim(0,max(conf)*100*1.30)
for s in ("top","right"): axB.spines[s].set_visible(False)
axB.grid(axis="y",color="#EEE",lw=.7); axB.set_axisbelow(True)
axB.legend(fontsize=7.4,frameon=False,loc="upper center",bbox_to_anchor=(0.5,-0.13),ncol=2,handlelength=1.2)
axB.set_title("(b) 只看挑选那一份会夸大差距",fontsize=8.6,color="#333",loc="left",pad=6)
save(fig,"f4_threeway.png")

# ---------------------------------------------------------------- 图 5 样本量
TS=N["trainsize"]["rows"]; CE=N["fixedn"]["cells"]
fig,ax=plt.subplots(figsize=(W,2.6))
ax.plot([r["n"] for r in TS],[r["p_lower"] for r in TS],"-o",color=BLUE,lw=1.5,ms=4.5,
        label="单一机制（真值已知的模拟）")
ns=[CE[k]["n"] for k in CE]
for i,k in enumerate(CE):
    c=CE[k]; lo=min(c["conc_lo"],c["diff_lo"]); hi=max(c["conc_hi"],c["diff_hi"])
    ax.plot([c["n"],c["n"]],[lo,hi],color=ORANGE,lw=6,solid_capstyle="butt",alpha=.35,
            zorder=1,label="16 个情景的跨度" if i==0 else None)
    ax.plot([c["n"]],[np.median([c["conc_med"],c["diff_med"]])],marker="_",ms=13,mew=2,
            color=ORANGE,zorder=2)
ax.set_xscale("log"); ax.set_xticks([300,600,1000,2000,6000,20000])
ax.get_xaxis().set_major_formatter(matplotlib.ticker.FuncFormatter(lambda v,_:"%d"%v))
ax.set_xlabel("拟合集人数（对数刻度）"); ax.set_ylabel("疗效承诺的成功概率")
ax.set_ylim(-0.03,1.03)
ax.axhline(0.8,color="#BBB",lw=.8,ls=(0,(4,3)))
ax.text(320,0.815,"0.80",fontsize=7.5,color="#888")
for s in ("top","right"): ax.spines[s].set_visible(False)
ax.grid(axis="y",color="#EEE",lw=.7); ax.set_axisbelow(True)
ax.legend(fontsize=8,frameon=False,loc="lower right")
save(fig,"f5_size.png")
