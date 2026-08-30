## trialplate :: figures --------------------------------------------------------
## Visual grammar inherited from Ren et al. (2026) nmaplateplot; re-targeted from
## treatment-pair contrasts to criterion-pair interactions, and carrying TWO
## benefit estimands (upper = hazard ratio, lower = RMST) instead of one benefit
## plus one cost. Patient cost moves to the diagonal background, so the figure
## shows benefit-vs-cost and HR-vs-RMST at the same time.

.circ <- function(x, y, r, col, border = NA, lwd = 1) {
  th <- seq(0, 2*pi, length.out = 84)
  polygon(x + r*cos(th), y + r*sin(th), col = col, border = border, lwd = lwd)
}
## 45-degree hatch clipped to the cell. Two densities:
##   dense  - the cell is an arithmetic identity (one criterion implies the other)
##   sparse - the cell has near-zero interaction LEVERAGE, i.e. the two criteria
##            are too permissive for a "both-required" interaction to show up at
##            all. The estimate is still drawn, but the reader is told the cell
##            is structurally starved of signal rather than empirically null.
.hatch <- function(x, y, h = .5, col = "#AEB6BF", step = .10, lwd = .8) {
  for (o in seq(-2*h, 2*h, by = step)) {
    x0 <- x - h; y0 <- y + o + h; x1 <- x + h; y1 <- y + o - h
    ## clip the 45-degree line y = (y0) - (t) to the square
    tl <- max(0, y0 - (y + h)); tr <- min(2*h, y0 - (y - h))
    if (tr <= tl) next
    segments(x0 + tl, y0 - tl, x0 + tr, y0 - tr, col = col, lwd = lwd)
  }
}
PAL_R <- c("#8E1626","#C0392F","#E28A82","#F2DAD6")   # q < .001 / .01 / .05 / ns
PAL_B <- c("#10375F","#2B6CAB","#83AAD3","#D6DEE7")
.band <- function(q) if (is.na(q)) 4L else if (q < .001) 1L else if (q < .01) 2L else if (q < .05) 3L else 4L
.pcol <- function(q, dir) (if (dir >= 0) PAL_R else PAL_B)[.band(q)]
.costcol <- function(pct) {   # % of the cohort a criterion costs, 0-100
  grDevices::colorRampPalette(c("#FBFBF7","#F6E3B8","#E9A257","#C2532F"))(101)[
    pmin(100, pmax(0, round(pct))) + 1]
}

## ---- the criteria plate plot ----------------------------------------------
plate_criteria <- function(sm, fit, leverage = NULL, lev_min = 0.05,
                           order_by = "HR", hide_ns = FALSE, top_k = NULL,
                           rmax = .40, title = "", sub = "") {
  p <- length(sm$names)
  ord <- order(-sm[[order_by]]$phi * if (order_by == "HR") 1 else -1)
  if (!is.null(top_k) && top_k < p) ord <- ord[seq_len(top_k)]
  k <- length(ord); nm <- sm$names[ord]
  sub_m <- function(M) M[ord, ord, drop = FALSE]
  U <- sm$HR; L <- sm$RMST
  UI<-sub_m(U$I); Ulo<-sub_m(U$I_lo); Uhi<-sub_m(U$I_hi); Uq<-sub_m(U$I_q)
  LI<-sub_m(L$I); Llo<-sub_m(L$I_lo); Lhi<-sub_m(L$I_hi); Lq<-sub_m(L$I_q)
  det <- sub_m(sm$determined)
  lowlev <- if (is.null(leverage)) matrix(FALSE, k, k) else sub_m(leverage) < lev_min
  costs <- 100 * (1 - exp(sm$N$phi[ord]))          # % of cohort lost, per criterion
  dHR   <- 100 * (exp(sm$HR$phi[ord]) - 1)
  dRM   <- sm$RMST$phi[ord]
  scU <- max(abs(c(Ulo, Uhi)[!det[rep(TRUE, length(Ulo))]]), na.rm = TRUE)
  scL <- max(abs(c(Llo, Lhi)), na.rm = TRUE)

  op <- par(mar = c(.4,.4,2.8,.4), xpd = NA); on.exit(par(op))
  plot(NA, xlim = c(.3, k+.7), ylim = c(k+.7, .3), asp = 1, axes = FALSE, xlab = "", ylab = "")
  polygon(c(.5,k+.5,k+.5), c(.5,.5,k+.5), col = "#FFFAEE", border = NA)   # upper: HR
  polygon(c(.5,.5,k+.5),   c(.5,k+.5,k+.5), col = "#F1F5F9", border = NA) # lower: RMST
  for (g in 0:k) { lines(c(.5,k+.5), c(g+.5,g+.5), col="white", lwd=1.5)
                   lines(c(g+.5,g+.5), c(.5,k+.5), col="white", lwd=1.5) }
  for (i in 1:k) for (j in 1:k) {
    x <- j; y <- i
    if (i == j) {
      rect(x-.5,y-.5,x+.5,y+.5, col = .costcol(costs[i]), border = "white", lwd = 1.5)
      text(x, y-.20, nm[i], cex = .70, font = 2)
      text(x, y+.06, sprintf("%+.1f%%", dHR[i]), cex = .55, col = "#7A2230")
      text(x, y+.28, sprintf("%+.0f d",  dRM[i]), cex = .55, col = "#1B3F63")
    } else if (det[i,j]) {
      .hatch(x, y, step = .09, col = "#9AA4AF")          # arithmetic identity
    } else {
      if (lowlev[i,j]) .hatch(x, y, step = .26, col = "#D3D9E0", lwd = .55)
      up <- i < j
      v  <- if (up) UI[i,j] else LI[i,j]; if (!is.finite(v) || v == 0) next
      lo <- if (up) Ulo[i,j] else Llo[i,j]; hi <- if (up) Uhi[i,j] else Lhi[i,j]
      qq <- if (up) Uq[i,j]  else Lq[i,j];  sc <- if (up) scU else scL
      if (hide_ns && (is.na(qq) || qq >= .05)) next
      far  <- if (abs(hi) > abs(lo)) hi else lo
      near <- if (abs(hi) > abs(lo)) lo else hi
      .circ(x, y, rmax*abs(far)/sc, .pcol(qq, sign(v)))
      .circ(x, y, rmax*abs(v)/sc,   "#8A8A8A")
      if (!is.na(qq) && qq < .05) .circ(x, y, rmax*abs(near)/sc, "white")
    }
  }
  title(main = title, cex.main = 1.02, line = 1.2)
  mtext(sub, side = 3, line = .1, cex = .66, col = "#555555")
  invisible(list(order = nm, scale_upper = scU, scale_lower = scL))
}

## ---- legend, laid out on its own device region ----------------------------
plate_legend <- function(scU, scL, cex = .62) {
  op <- par(mar = c(.2,.6,.2,.6), xpd = NA); on.exit(par(op))
  plot(NA, xlim = c(0,100), ylim = c(-1,30), axes = FALSE, xlab = "", ylab = "")
  lab <- function(x, y, t) text(x, y, t, adj = 0, cex = cex*.84, font = 2, col = "#666666")

  ## col 1: anatomy of one plate
  lab(0, 29, "ONE PLATE")
  .circ(6, 19, 6.0, PAL_R[2]); .circ(6, 19, 3.5, "#8A8A8A"); .circ(6, 19, 1.6, "white")
  text(14, 24.0, "outer   bound of the 95% BCa interval further from 0", adj = 0, cex = cex*.86)
  text(14, 19.0, "middle  Shapley interaction point estimate",            adj = 0, cex = cex*.86)
  text(14, 14.0, "inner   nearer bound, drawn only when BH q < 0.05",     adj = 0, cex = cex*.86)

  ## col 2: significance bands
  lab(0, 8.5, "BH-ADJUSTED q")
  bands <- c("<.001","<.01","<.05","n.s.")
  for (b in 1:4) {
    rect(20 + (b-1)*5.4, 4.2, 24.4 + (b-1)*5.4, 7.2, col = PAL_B[b], border = "white")
    rect(20 + (b-1)*5.4, 0.4, 24.4 + (b-1)*5.4, 3.4, col = PAL_R[b], border = "white")
    text(22.2 + (b-1)*5.4, 8.8, bands[b], cex = cex*.68)
  }
  text(43.5, 5.7, "I < 0  antagonistic", adj = 0, cex = cex*.82, col = "#10375F")
  text(43.5, 1.9, "I > 0  synergistic",  adj = 0, cex = cex*.82, col = "#8E1626")

  ## col 3: hatching
  lab(62, 29, "HATCHED CELLS")
  rect(62, 21.5, 68, 26.5, border = "#D7DEE5")
  .hatch(65, 24, h = 2.5, step = .55, col = "#9AA4AF", lwd = .7)
  text(70, 24, "one criterion implies the other:", adj = 0, cex = cex*.8)
  text(70, 21.2, "the cell is arithmetic, not evidence", adj = 0, cex = cex*.74, col = "#777777")
  rect(62, 13.0, 68, 18.0, border = "#D7DEE5")
  .hatch(65, 15.5, h = 2.5, step = 1.2, col = "#C9D0D8", lwd = .6)
  text(70, 15.5, "leverage < 0.05: the pair is too", adj = 0, cex = cex*.8)
  text(70, 12.7, "permissive for an interaction to show", adj = 0, cex = cex*.74, col = "#777777")

  ## bottom band: the diagonal
  lab(62, 8.5, "DIAGONAL")
  for (b in 0:4) rect(62 + b*3.6, 3.4, 65.6 + b*3.6, 6.4, col = .costcol(b*25), border = "white")
  text(63.0, 1.6, "0%", cex = cex*.66); text(78.6, 1.6, "100%", cex = cex*.66)
  text(81.5, 5.4, "background = % of cohort excluded", adj = 0, cex = cex*.8)
  text(81.5, 2.0, "red = effect on HR,  blue = on RMST", adj = 0, cex = cex*.8)

  text(0, -0.8, sprintf("radius scale:  upper max |I| = %.3f (log HR)    lower max |I| = %.1f (days)", scU, scL),
       adj = 0, cex = cex*.74, col = "#777777")
  invisible(NULL)
}

## ---- dual relaxation frontier ---------------------------------------------
frontier_dual <- function(fit, main = "") {
  V <- fit$V; ok <- V[,"feasible"] == 1
  n <- exp(V[ok,"logN"]); hr <- exp(V[ok,"logHR"]); rm <- V[ok,"rmstD"]
  fr <- function(y, better_low) { o <- order(-n); ys <- y[o]; ns <- n[o]
    k <- if (better_low) ys == cummin(ys) else ys == cummax(ys); list(n = ns[k], y = ys[k]) }
  fh <- fr(hr, TRUE); fm <- fr(rm, FALSE)
  full <- which.max(rowSums(!is.na(V[,1:2, drop=FALSE]))*0 + seq_len(nrow(V)))  # last row = all criteria
  n0 <- exp(V[nrow(V),"logN"]); h0 <- exp(V[nrow(V),"logHR"]); r0 <- V[nrow(V),"rmstD"]
  ## the protocol each estimand would pick, at >= the original cohort size
  bh <- which(n >= n0)[which.min(hr[n >= n0])]; bm <- which(n >= n0)[which.max(rm[n >= n0])]
  op <- par(mfrow = c(1,2), mar = c(4.4,4.6,3.2,1.2), mgp = c(2.8,.7,0)); on.exit(par(op))
  pan <- function(y, f, ylab, better_low, star, other) {
    plot(n, y, pch = 16, cex = .30, col = "#CBD2DA", las = 1, xlab = "Eligible patients (n)",
         ylab = ylab, main = "", cex.main = 1)
    lines(f$n, f$y, type = "s", col = "#10375F", lwd = 2.2)
    points(f$n, f$y, pch = 16, cex = .62, col = "#10375F")
    points(n0, if (better_low) h0 else r0, pch = 23, bg = "#C0392F", cex = 1.6)
    points(n[star],  y[star],  pch = 21, bg = "#F0C419", cex = 1.7, lwd = 1.4)
    points(n[other], y[other], pch = 24, bg = "#FFFFFF", col = "#8E1626", cex = 1.3, lwd = 1.6)
  }
  pan(hr, fh, "Hazard ratio, overall survival", TRUE,  bh, bm)
  mtext("selected on HR", side = 3, line = .4, cex = .78, font = 2)
  legend("topright", bty = "n", cex = .66,
    legend = c("original protocol", "optimum on HR", "optimum on RMST", "frontier"),
    pch = c(23,21,24,NA), lty = c(NA,NA,NA,1), lwd = c(NA,NA,NA,2.2),
    pt.bg = c("#C0392F","#F0C419","#FFFFFF",NA), col = c("black","black","#8E1626","#10375F"))
  pan(rm, fm, "RMST difference (days)", FALSE, bm, bh)
  mtext("selected on RMST", side = 3, line = .4, cex = .78, font = 2)
  mtext(main, side = 3, line = -1.4, outer = TRUE, cex = .9, font = 2)
  invisible(list(hr_pick = bh, rmst_pick = bm, n = n, hr = hr, rmst = rm))
}
