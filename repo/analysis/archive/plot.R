## trialplate :: the criteria plate plot --------------------------------------
## Visual grammar inherited from Ren et al. (2026) nmaplateplot:
##   concentric circles = point estimate + interval bound, colour = significance,
##   two triangles = two outcomes, diagonal = ranking score.
## Re-targeted here from treatment-pair contrasts to CRITERION-PAIR interactions.

.circ <- function(x, y, r, col, border = NA, lwd = 1) {
  th <- seq(0, 2*pi, length.out = 72)
  polygon(x + r*cos(th), y + r*sin(th), col = col, border = border, lwd = lwd)
}
.pcol <- function(p, dir, alpha = 1) {
  ## dir = +1 -> red family, -1 -> blue family; intensity by p-value band
  b <- if (is.na(p)) 4 else if (p < .001) 1 else if (p < .01) 2 else if (p < .05) 3 else 4
  reds  <- c("#9E1B32", "#CE3B4B", "#E8837F", "#F0D3D0")
  blues <- c("#123E75", "#2E6DAF", "#7FA9D6", "#D2DCE8")
  grDevices::adjustcolor(if (dir >= 0) reds[b] else blues[b], alpha.f = alpha)
}
.crs_col <- function(s) {                      # diagonal background, CRS 0-100
  grDevices::colorRampPalette(c("#F7F7F2", "#FCE9B8", "#F2A65A", "#D1495B"))(101)[
    pmin(100, pmax(0, round(s))) + 1]
}

plateplot_criteria <- function(sm, labels = NULL, order_by = "HR",
   title = "", sub = "", rmax = 0.40, cex_lab = 0.62, cex_num = 0.55) {
  p  <- length(sm$names)
  nm <- sm$names; lab <- if (is.null(labels)) nm else labels[nm]
  ord <- order(-sm[[order_by]]$CRS)
  nm <- nm[ord]; lab <- lab[ord]
  U <- sm$HR; L <- sm$N
  sub_m <- function(M) M[ord, ord, drop = FALSE]
  UI <- sub_m(U$I); UIlo <- sub_m(U$I_lo); UIhi <- sub_m(U$I_hi); UIp <- sub_m(U$I_p)
  LI <- sub_m(L$I); LIlo <- sub_m(L$I_lo); LIhi <- sub_m(L$I_hi); LIp <- sub_m(L$I_p)
  sU <- U$CRS[ord]; sL <- L$CRS[ord]
  ## common radius scale per triangle (outer bound drives the scale)
  scU <- max(abs(c(UIlo, UIhi)), na.rm = TRUE); scL <- max(abs(c(LIlo, LIhi)), na.rm = TRUE)

  op <- par(mar = c(0.4, 0.4, 2.4, 0.4), xpd = NA); on.exit(par(op))
  plot(NA, xlim = c(0.3, p + 0.7), ylim = c(p + 0.7, 0.3), asp = 1,
       axes = FALSE, xlab = "", ylab = "")
  ## triangle backgrounds
  polygon(c(.5,p+.5,p+.5), c(.5,.5,p+.5), col = "#FFF9E8", border = NA)   # upper
  polygon(c(.5,.5,p+.5),   c(.5,p+.5,p+.5), col = "#F2F6FA", border = NA) # lower
  for (k in 0:p) { lines(c(.5,p+.5), c(k+.5,k+.5), col="white", lwd=1.4)
                   lines(c(k+.5,k+.5), c(.5,p+.5), col="white", lwd=1.4) }

  for (i in 1:p) for (j in 1:p) {
    x <- j; y <- i
    if (i == j) {
      rect(x-.5, y-.5, x+.5, y+.5, col = .crs_col((sU[i]+sL[i])/2), border = "white", lwd=1.4)
      text(x, y-0.16, nm[i], cex = cex_lab + .06, font = 2)
      text(x, y+0.20, sprintf("%.0f | %.0f", sU[i], sL[i]), cex = cex_num, col = "#333333")
    } else {
      up <- i < j
      v  <- if (up) UI[i,j] else LI[i,j]; if (!is.finite(v) || v == 0) next
      lo <- if (up) UIlo[i,j] else LIlo[i,j]; hi <- if (up) UIhi[i,j] else LIhi[i,j]
      pv <- if (up) UIp[i,j]  else LIp[i,j];  sc <- if (up) scU else scL
      far  <- if (abs(hi) > abs(lo)) hi else lo      # bound further from null
      near <- if (abs(hi) > abs(lo)) lo else hi      # bound nearer null
      dir  <- sign(v); sig <- is.finite(pv) && pv < 0.05
      .circ(x, y, rmax*abs(far)/sc,  .pcol(pv, dir))                   # outer
      .circ(x, y, rmax*abs(v)/sc,    "#8C8C8C")                        # point est.
      if (sig) .circ(x, y, rmax*abs(near)/sc, "white")                 # inner
    }
  }
  title(main = title, cex.main = 1.0, line = 0.9)
  mtext(sub, side = 3, line = -0.2, cex = 0.66, col = "#555555")
  invisible(list(order = nm, scale_upper = scU, scale_lower = scL))
}

## ---- relaxation frontier ---------------------------------------------------
## For every criteria subset, the achievable (eligible N, HR) pair; the
## upper-left frontier is the set of non-dominated protocols.
frontier_plot <- function(fit, title = "") {
  N <- exp(fit$V[, "logN"]); H <- exp(fit$V[, "logHR"])
  k <- is.finite(N) & is.finite(H)
  N <- N[k]; H <- H[k]
  o <- order(-N); Ns <- N[o]; Hs <- H[o]
  keep <- Hs == cummin(Hs)
  op <- par(mar = c(4, 4.2, 2.4, 1)); on.exit(par(op))
  plot(N, H, pch = 16, cex = .28, col = "#C8CDD4",
       xlab = "Eligible patients (n)", ylab = "Hazard ratio, overall survival",
       main = title, cex.main = 1.0, las = 1)
  lines(Ns[keep], Hs[keep], col = "#123E75", lwd = 2.2, type = "s")
  points(Ns[keep], Hs[keep], pch = 16, cex = .7, col = "#123E75")
  points(exp(fit$v_full["logN"]), exp(fit$v_full["logHR"]), pch = 23, bg = "#D1495B", cex = 1.5)
  points(exp(fit$v_empty["logN"]), exp(fit$v_empty["logHR"]), pch = 22, bg = "#F2A65A", cex = 1.5)
  legend("topright", bty = "n", cex = .72,
    legend = c("all 2^p protocols", "non-dominated frontier",
               "original protocol (all criteria)", "no criteria (whole cohort)"),
    pch = c(16, NA, 23, 22), lty = c(NA, 1, NA, NA), lwd = c(NA, 2.2, NA, NA),
    col = c("#C8CDD4", "#123E75", "black", "black"),
    pt.bg = c(NA, NA, "#D1495B", "#F2A65A"))
  invisible(data.frame(n = Ns[keep], hr = Hs[keep]))
}

## ---- legend ---------------------------------------------------------------
plate_legend <- function(scU, scL, cex = 0.62) {
  op <- par(mar = c(0.3, 1.2, 0.3, 0.3), xpd = NA); on.exit(par(op))
  plot(NA, xlim = c(0, 10), ylim = c(0, 3.2), axes = FALSE, xlab = "", ylab = "", asp = 1)
  bands <- c("p<0.001","p<0.01","p<0.05","n.s.")
  reds  <- c("#9E1B32","#CE3B4B","#E8837F","#F0D3D0")
  blues <- c("#123E75","#2E6DAF","#7FA9D6","#D2DCE8")
  text(0.0, 0.35, "significance", cex = cex, font = 2, adj = 0)
  for (k in 1:4) {
    rect(1.9 + (k-1)*0.62, 0.08, 2.4 + (k-1)*0.62, 0.58, col = blues[k], border = "white")
    rect(4.6 + (k-1)*0.62, 0.08, 5.1 + (k-1)*0.62, 0.58, col = reds[k],  border = "white")
    text(2.15 + (k-1)*0.62, 0.85, bands[k], cex = cex*0.78, srt = 0)
  }
  text(3.3, 1.25, "antagonistic  (I < 0)", cex = cex*0.85)
  text(6.0, 1.25, "synergistic  (I > 0)", cex = cex*0.85)
  ## circle key
  text(0.0, 2.35, "one plate", cex = cex, font = 2, adj = 0)
  .circ(2.4, 2.35, 0.46, "#CE3B4B"); .circ(2.4, 2.35, 0.28, "#8C8C8C"); .circ(2.4, 2.35, 0.13, "white")
  text(3.05, 2.05, "outer = bound of 95% bootstrap CI further from 0", cex = cex*0.8, adj = 0)
  text(3.05, 2.35, "middle = Shapley interaction point estimate",       cex = cex*0.8, adj = 0)
  text(3.05, 2.65, "inner  = nearer bound (drawn only if p < 0.05)",    cex = cex*0.8, adj = 0)
  text(0.0, 3.05, sprintf("radius scale: upper max |I| = %.3f   lower max |I| = %.3f", scU, scL),
       cex = cex*0.78, adj = 0, col = "#666666")
  invisible(NULL)
}
