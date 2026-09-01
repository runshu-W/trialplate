## Figures 2-5, regenerated from the stored result objects. Reviewer minor
## points 5 and 8: every simulated probability now carries a Monte Carlo
## interval, and the palette is colourblind-safe (Okabe-Ito), with line type
## and plotting symbol varying alongside colour so that nothing depends on hue
## alone. Previously these figures were produced by ad-hoc code that was not
## committed; that is fixed here.
source("analysis/_setup.R")

## Okabe-Ito, safe under deuteranopia, protanopia and tritanopia
OI <- c(blue = "#0072B2", vermilion = "#D55E00", green = "#009E73",
        orange = "#E69F00", purple = "#CC79A7", sky = "#56B4E9",
        yellow = "#F0E442", black = "#000000")
GREY <- "#7A828A"; HAIR <- "#C9CFD6"

wilson <- function(k, n, z = 1.96) {           # Monte Carlo interval on a proportion
  if (!n) return(c(NA, NA))
  ph <- k/n; d <- 1 + z^2/n
  c(max(0, (ph + z^2/(2*n) - z*sqrt(ph*(1-ph)/n + z^2/(4*n^2)))/d),
    min(1, (ph + z^2/(2*n) + z*sqrt(ph*(1-ph)/n + z^2/(4*n^2)))/d))
}
ebar <- function(x, lo, hi, col, w = 0.03) {
  segments(x, lo, x, hi, col = col, lwd = 1.5)
  segments(x*(1-w), lo, x*(1+w), lo, col = col, lwd = 1.5)
  segments(x*(1-w), hi, x*(1+w), hi, col = col, lwd = 1.5)
}
## the horizontal axis is logarithmic in every panel that uses axl(); this is
## stated in the captions as well (reviewer round 2, minor point on axis scaling)
axl <- function(v) axis(1, at = v, labels = format(v, big.mark = " ", trim = TRUE), cex.axis = .8)

## ================= Figure 3 : training size =================
ts <- readRDS("analysis/out/sim_trainsize.rds")
n  <- vapply(ts, `[[`, numeric(1), "n_train")
R  <- vapply(ts, `[[`, numeric(1), "R")
pl <- vapply(ts, `[[`, numeric(1), "p_lower_hr")
pm <- vapply(ts, `[[`, numeric(1), "p_more_n")
px <- vapply(ts, `[[`, numeric(1), "p_exact_rule")

png("analysis/out/fig_trainsize.png", width = 1900, height = 820, res = 200)
par(mfrow = c(1,2), mar = c(4.2, 4.3, 3.0, 1.0), mgp = c(2.5, .7, 0), las = 1)

plot(n, pm, log = "x", type = "n", ylim = c(0, 1.02), axes = FALSE,
     xlab = "patients available to FIT the rule (log scale)", ylab = "P(promise kept, out of sample)")
axl(n); axis(2); box(col = HAIR)
abline(h = 0.8, col = HAIR, lwd = 1.2, lty = 3)
for (i in seq_along(n)) { ci <- wilson(round(pm[i]*R[i]), R[i]); ebar(n[i], ci[1], ci[2], OI["green"]) }
lines(n, pm, col = OI["green"], lwd = 2.2, lty = 1)
points(n, pm, pch = 21, bg = OI["green"], col = "white", cex = 1.4)
for (i in seq_along(n)) { ci <- wilson(round(pl[i]*R[i]), R[i]); ebar(n[i], ci[1], ci[2], OI["vermilion"]) }
lines(n, pl, col = OI["vermilion"], lwd = 2.2, lty = 2)
points(n, pl, pch = 22, bg = OI["vermilion"], col = "white", cex = 1.4)
## Reviewer round 2, point 6: the observed cohort points previously appeared to
## land precisely on the simulated curve, with none of the uncertainty the
## nested resampling had just reported. They now carry their outer-bootstrap
## intervals, which span most of the unit interval, so the figure no longer
## suggests a precise agreement.
## Reviewer round 5, major point 1. This panel plotted the observed values as
## literals, and they were the pre-correction ones computed with the mismatched
## Rotterdam endpoint, while it read its intervals from a result object that has
## since been retired. Both now come from the primary analysis and the nested
## bootstrap, and only the half-split points are shown because that is the split
## the primary analysis uses.
PRM <- readRDS("analysis/out/primary_colon.rds"); PRR_ <- readRDS("analysis/out/primary_rott.rds")
NSC <- readRDS("analysis/out/nested_colon.rds"); NSR <- readRDS("analysis/out/nested_rott.rds")
obs_pt <- function(z) mean(z$M[, "lower"], na.rm = TRUE)
obs_ci <- function(z) { x <- z$M[-1, "lower"]; unname(stats::quantile(x[is.finite(x)], c(.025, .975))) }
n_fit_c <- floor(0.5 * 619); n_fit_r <- floor(0.5 * 2982)
cc <- obs_ci(NSC); cr <- obs_ci(NSR)
ebar(n_fit_c, cc[1], cc[2], OI["blue"]); ebar(n_fit_r, cr[1], cr[2], OI["purple"])
points(n_fit_c, obs_pt(PRM), pch = 23, bg = OI["blue"],   col = "white", cex = 1.6)
points(n_fit_r, obs_pt(PRR_), pch = 25, bg = OI["purple"], col = "white", cex = 1.4)
legend("bottomright", bty = "n", cex = .72,
  legend = c("more patients (simulated)", "lower hazard ratio (simulated)",
             "randomised cohort, observed", "registry cohort, observed"),
  col = c(OI["green"], OI["vermilion"], OI["blue"], OI["purple"]),
  pt.bg = c(OI["green"], OI["vermilion"], OI["blue"], OI["purple"]),
  pch = c(21, 22, 23, 25), lty = c(1, 2, NA, NA), lwd = 2)
mtext("One promise is robust; the other has a threshold in THIS mechanism", 3, line = 1.3, cex = .80, font = 2)
mtext("simulated points: Monte Carlo intervals. observed cohorts: outer-bootstrap intervals", 3, line = .25, cex = .58, col = GREY)

plot(n, px, log = "x", type = "n", ylim = c(0, max(px)*1.15), axes = FALSE,
     xlab = "patients available to FIT the rule (log scale)", ylab = "P(exactly the right criterion set)")
axl(n); axis(2); box(col = HAIR)
for (i in seq_along(n)) { ci <- wilson(round(px[i]*R[i]), R[i]); ebar(n[i], ci[1], ci[2], OI["orange"]) }
lines(n, px, col = OI["orange"], lwd = 2.2); points(n, px, pch = 21, bg = OI["orange"], col = "white", cex = 1.4)
mtext("Why the two promises differ", 3, line = 1.3, cex = .82, font = 2)
mtext("the patient gain needs no correct selection; the hazard-ratio gain does", 3, line = .25, cex = .62, col = GREY)
dev.off(); say("fig_trainsize.png written")

## ================= Figure 4 : confounding arms =================
## Reviewer major point 7: the three arms share one outcome model, so the TRUE
## causal contrast is identical in all three. What differs is the population
## limit of the weighted estimator under each adjustment. The right panel is
## labelled accordingly.
tab <- readRDS("analysis/out/confound_table.rds")
R_CF <- 250
arms <- unique(tab$arm)
CL <- c(OI["blue"], OI["orange"], OI["vermilion"]); LT <- c(1, 2, 4); PC <- c(21, 22, 24)
## Reviewer round 5, major point 1. These three values were typed in here and
## again in the Results, from a run that no longer matches the script in the
## repository. Both now read the same result file.
LIMIT <- local({
  z <- tryCatch(readRDS("analysis/out/confound_limits.rds"), error = function(e) NULL)
  if (is.null(z)) stop("run analysis/confound_limits.R first: figures must not carry literals")
  unname(z[, "gap"])
})
HRFULL <- local({
  z <- readRDS("analysis/out/confound_limits.rds"); unname(z[, "hr_full"])
})
RECOV <- local({                            # exact recovery at n = 5167, from the table
  vapply(arms, function(a) tab$rec[tab$arm == a & tab$n == 5167][1], numeric(1))
})

png("analysis/out/fig_confound.png", width = 1900, height = 800, res = 200)
par(mfrow = c(1, 3), mar = c(4.2, 4.3, 3.0, 0.8), mgp = c(2.5, .7, 0), las = 1)

## panel 1: reliability curve
nn <- sort(unique(tab$n))
plot(range(nn), c(0.3, 1.02), log = "x", type = "n", axes = FALSE,
     xlab = "patients available to FIT the rule (log scale)", ylab = "P(lower hazard ratio, out of sample)")
axl(nn); axis(2); box(col = HAIR); abline(h = .8, col = HAIR, lty = 3)
for (k in seq_along(arms)) {
  z <- tab[tab$arm == arms[k], ]
  for (i in seq_len(nrow(z))) { ci <- wilson(round(z$p[i]*R_CF), R_CF); ebar(z$n[i], ci[1], ci[2], CL[k]) }
  lines(z$n, z$p, col = CL[k], lwd = 2.2, lty = LT[k])
  points(z$n, z$p, pch = PC[k], bg = CL[k], col = "white", cex = 1.4)
}
legend("bottomright", bty = "n", cex = .68, legend = c("randomised", "confounded, correctly adjusted",
  "confounded, one confounder unmeasured"), col = CL, pt.bg = CL, pch = PC, lty = LT, lwd = 2)
mtext("Adjusted confounding raises the requirement", 3, line = 1.3, cex = .78, font = 2)
mtext("unmeasured confounding returns it to randomised levels", 3, line = .25, cex = .58, col = GREY)

## panel 2: the estimator limit, not the causal truth
bp <- barplot(LIMIT, col = CL, border = "white", names.arg = c("A", "B", "C"), ylim = c(0, max(LIMIT)*1.35),
  ylab = "population limit of the estimated gap in log HR")
abline(h = LIMIT[1], col = GREY, lty = 3)
text(bp, LIMIT + max(LIMIT)*.06, sprintf("%.4f", LIMIT), cex = .8)
text(bp, LIMIT/2, sprintf("HR %.3f", HRFULL), cex = .66, col = "white")
mtext(sprintf("Unmeasured confounding INFLATES it by %.0f%%", 100*(LIMIT[3]/LIMIT[1] - 1)), 3, line = 1.3, cex = .78, font = 2)
mtext("the true causal gap is IDENTICAL in all three arms", 3, line = .25, cex = .58, col = GREY)

## panel 3: recovery falls while apparent reliability does not
bp <- barplot(RECOV, col = CL, border = "white", names.arg = c("A", "B", "C"), ylim = c(0, max(RECOV)*1.35),
  ylab = "P(exactly the right criterion set) at n = 5167")
text(bp, RECOV + max(RECOV)*.06, sprintf("%.3f", RECOV), cex = .8)
mtext("and the selection actually gets WORSE", 3, line = 1.3, cex = .78, font = 2)
mtext(paste(sprintf("%.3f", vapply(arms, function(a) tab$p[tab$arm == a & tab$n == 5167][1], numeric(1))),
            collapse = " / "), 3, line = .25, cex = .58, col = GREY)
mtext("apparent reliability at n = 5167 against this", 3, line = -0.4, cex = .5, col = GREY)
dev.off(); say("fig_confound.png written")

## ================= Figure 5 : non-collapsibility sweep =================
sw <- readRDS("analysis/out/sim_sweep.rds")
png("analysis/out/fig_sim.png", width = 1900, height = 800, res = 200)
par(mfrow = c(1, 2), mar = c(4.4, 4.6, 3.0, 1.0), mgp = c(2.7, .7, 0), las = 1)
plot(sw$bZ, sw$phi_logHR, type = "o", pch = 21, bg = OI["vermilion"], col = OI["vermilion"],
     lwd = 2.2, cex = 1.3, axes = FALSE, xlab = expression(paste("prognostic strength  ", beta[2])),
     ylab = expression(paste(phi, "  on log HR")))
axis(1); axis(2); box(col = HAIR); abline(h = 0, col = HAIR, lwd = 1.3, lty = 3)
mtext("HR: an artefact that grows with heterogeneity", 3, line = 1.3, cex = .8, font = 2)
mtext("the conditional effect is identical in every stratum at every point", 3, line = .25, cex = .62, col = GREY)
plot(sw$bZ, sw$phi_rmstD, type = "o", pch = 22, bg = OI["blue"], col = OI["blue"],
     lwd = 2.2, cex = 1.3, axes = FALSE, xlab = expression(paste("prognostic strength  ", beta[2])),
     ylab = expression(paste(phi, "  on RMST difference (time units)")))
axis(1); axis(2); box(col = HAIR); abline(h = 0, col = HAIR, lwd = 1.3, lty = 3)
mtext("RMST: tracks a real change in absolute benefit", 3, line = 1.3, cex = .8, font = 2)
mtext("the selected low-risk group genuinely has less room to gain", 3, line = .25, cex = .62, col = GREY)
dev.off(); say("fig_sim.png written")
