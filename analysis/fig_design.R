## Figure 1: the study design. The one thing a reader must take away is that the
## rule is FITTED on one half and the protocol it produces is SCORED on the other,
## so neither protocol had a hand in choosing itself.
## Pure graphics -- no data, no package. Run from the repository root.
dir.create("analysis/out", showWarnings = FALSE, recursive = TRUE)
png("analysis/out/fig_design.png", width = 2200, height = 1120, res = 200)
op <- par(mar = c(0,0,0,0), xpd = NA); on.exit(par(op))
plot(NA, xlim = c(0, 220), ylim = c(0, 112), axes = FALSE, xlab = "", ylab = "", asp = 1)

INK<-"#131A22"; MUT<-"#6B7783"; HAIR<-"#C3CBD4"
BLU<-"#10375F"; BLUF<-"#E3EAF3"; RED<-"#8E1626"; GRN<-"#2F6B4F"; GRNF<-"#E4F0EA"
OCH<-"#B87D23"; OCHF<-"#FBF2DE"

box <- function(x,y,w,h,fill,border) rect(x-w/2,y-h/2,x+w/2,y+h/2,col=fill,border=border,lwd=1.5)
lab <- function(x,y,t,cex=.62,col=INK,font=1) text(x,y,t,cex=cex,col=col,font=font)
arr <- function(x0,y0,x1,y1,col=MUT,lwd=1.6) arrows(x0,y0,x1,y1,length=.07,angle=22,col=col,lwd=lwd)

## ---------- inputs ----------
box(30,102,52,13,"#F4F6F8",HAIR)
lab(30,105.6,"Public cohort",.70,INK,2)
lab(30,101.0,"colon  n = 619  (randomised trial)",.55,MUT)
lab(30, 97.6,"Rotterdam  n = 2982  (registry)",.55,MUT)

box(94,102,58,13,"#F4F6F8",HAIR)
lab(94,105.6,"9 eligibility criteria",.70,INK,2)
lab(94,101.0,"encoded as filters; no logical implications",.55,MUT)
lab(94, 97.6,"full protocol retains 28% / 14%",.55,MUT)
arr(56.5,102,64.5,102)

## ---------- the split ----------
arr(94,95.2,94,89.5)
box(94,84,36,9,BLUF,BLU); lab(94,84,"random split, R times",.64,BLU,2)
arr(82,80.5,50,71); arr(106,80.5,138,71)

## ---------- fit ----------
box(44,63,64,12,"#FFFFFF",BLU)
lab(44,66.3,"FIT   one half",.68,BLU,2)
lab(44,61.6,"enumerate all 2^9 criteria subsets, exactly",.53,MUT)
lab(44,58.3,"Shapley value of each criterion on log HR",.53,MUT)
arr(44,56.7,44,50.5)
box(44,44,64,11,GRNF,GRN)
lab(44,47.0,"the published rule",.62,GRN,2)
lab(44,42.6,"keep every criterion with Shapley < 0, relax the rest",.53,INK)
arr(44,38.3,44,32.5)
box(44,27,46,9,"#FFFFFF",GRN); lab(44,27,"data-driven protocol",.62,GRN,2)

## ---------- score ----------
box(144,63,64,12,"#FFFFFF",RED)
lab(144,66.3,"SCORE   the other half",.68,RED,2)
lab(144,61.6,"these patients had no part in the selection",.53,MUT)
lab(144,58.3,"both protocols scored here, side by side",.53,MUT)
box(144,27,46,9,"#FFFFFF",MUT); lab(144,27,"original full protocol",.62,MUT,2)
arr(144,56.7,144,32.5)

## ---------- comparison ----------
arr(68,27,120,27,RED,2); lab(94,30.4,"compare",.60,RED,2)
box(94,13,140,16,"#FFFFFF",INK)
lab(94,18.6,"three out-of-sample quantities",.66,INK,2)
lab(41,13.4,"eligible patients",.57,GRN,2); lab(41, 9.6,"promise 1",.51,MUT)
lab(94,13.4,"hazard ratio",.57,RED,2);     lab(94, 9.6,"promise 2",.51,MUT)
lab(147,13.4,"RMST difference",.57,BLU,2); lab(147,9.6,"descriptive",.51,MUT)
segments(67.5,7.5,67.5,19.5,col=HAIR); segments(120.5,7.5,120.5,19.5,col=HAIR)

## ---------- simulation, its own column ----------
box(197,60,38,76,OCHF,OCH)
lab(197,94,"in parallel",.56,OCH,2)
lab(197,89,"SIMULATION",.70,OCH,2)
lab(197,84,"truth known",.55,OCH,3)
lab(197,77,"scoring set held at",.52,INK)
lab(197,74,"100 000, so the axis",.52,INK)
lab(197,71,"is fitting size alone",.52,INK)
segments(181,64,213,64,col=OCH,lty=3)
lab(197,59,"three assignment",.52,INK)
lab(197,56,"mechanisms sharing",.52,INK)
lab(197,53,"one outcome model",.52,INK)
lab(197,47,"randomised",.52,MUT)
lab(197,44,"confounded, adjusted",.52,MUT)
lab(197,41,"confounded, one",.52,MUT)
lab(197,38,"confounder unseen",.52,MUT)
dev.off(); cat("fig_design.png written\n")
