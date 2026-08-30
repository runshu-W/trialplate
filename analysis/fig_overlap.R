## Reviewer round 2, major point 7. The propensity distributions by arm inside
## the full protocol, so a reader can see the overlap problem rather than take
## our word for it, together with the trimmed common-support region that defines
## the target population under the M4 specification.
source("analysis/_setup.R")
ALLS <- function(E, S) { r <- E[, S[1]]; for (j in S[-1]) r <- r & E[, j]; r }
OI <- c(blue="#0072B2", vermilion="#D55E00"); HAIR <- "#C9CFD6"; GREY <- "#7A828A"

png("analysis/out/fig_overlap.png", width = 1900, height = 760, res = 200)
par(mfrow = c(1, 2), mar = c(4.2, 4.3, 3.0, 1.0), mgp = c(2.5, .7, 0), las = 1)
for (nm in c("colon","rott")) {
  pr <- if (nm=="colon") tp_prepare(colon_data(), colon_criteria, "trt","time","status", colon_ps, tau=1825)
        else             tp_prepare(rott_data(),  rott_criteria,  "trt","rtime","death", rott_ps, tau=1825)
  k <- ALLS(pr$E, seq_len(pr$p)); tr <- pr$trt[k]
  e <- fast_logit(pr$X[k,,drop=FALSE], tr)
  br <- seq(0, 1, by = 0.05)
  h1 <- hist(e[tr==1], breaks=br, plot=FALSE); h0 <- hist(e[tr==0], breaks=br, plot=FALSE)
  ym <- max(h1$density, h0$density) * 1.15
  plot(NA, xlim=c(0,1), ylim=c(0,ym), axes=FALSE, xlab="estimated propensity score",
       ylab="density", main="")
  axis(1); axis(2); box(col=HAIR)
  rect(h0$breaks[-length(h0$breaks)], 0, h0$breaks[-1], h0$density,
       col=adjustcolor(OI["blue"], .45), border="white")
  rect(h1$breaks[-length(h1$breaks)], 0, h1$breaks[-1], h1$density,
       col=adjustcolor(OI["vermilion"], .45), border="white")
  abline(v=c(0.05,0.95), col=GREY, lty=3)
  lo <- max(min(e[tr==1]), min(e[tr==0])); hi <- min(max(e[tr==1]), max(e[tr==0]))
  segments(lo, ym*0.90, hi, ym*0.90, col="black", lwd=2)
  text((lo+hi)/2, ym*0.83, sprintf("common support %.2f-%.2f", lo, hi), cex=.62)
  ess <- { et <- pmin(pmax(e,.05),.95); w <- tr/et + (1-tr)/(1-et); sum(w)^2/sum(w^2) }
  mtext(sprintf("%s, full protocol (n = %d)", if (nm=="colon") "colon, randomised" else "Rotterdam, registry", sum(k)),
        3, line=1.3, cex=.8, font=2)
  mtext(sprintf("ESS %.0f (%.0f%% of nominal); %d at the 0.05/0.95 bound",
        ess, 100*ess/sum(k), sum(e<=.05 | e>=.95)), 3, line=.25, cex=.6, col=GREY)
  legend(if (nm=="colon") "topright" else "topleft", bty="n", cex=.68, inset=c(0,0.02),
    legend=c("control","treated"), fill=adjustcolor(c(OI["blue"],OI["vermilion"]), .45), border="white")
}
dev.off(); say("fig_overlap.png written")
