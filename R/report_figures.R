# report_figures.R -- Figures 1-3 of report/report.md, from existing results only
# (no simulations are run). Base R only. Run from the repository root:
#   Rscript R/report_figures.R
# Reads results/sr08/results_all.rds (per-setting results for each rebuild variant) and
# docs/three_way.md (the published values and the original 2009 program, per cell).
# Writes report/figures/fig1_published_vs_reproduced.png, fig2_which_detail.png and
# fig3_where_correction_matters.png (PNG, 300 dpi).

res <- readRDS("results/sr08/results_all.rds")
fig_dir <- "report/figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

grey <- "grey45"; light <- "grey75"; blue <- "#1f5fa8"

# --- The 71 cells of Tables B1-B4, labelled as in docs/three_way.md ----------------------
cells_of <- function(d) {
  b1 <- do.call(rbind, lapply(c("d1", "Nt", "ratio", "B", "a", "s2t"), function(v) {
    m <- tapply(d$pct_red, d[[v]], mean)
    data.frame(cell = paste0(v, ".B1 ", v, "=", names(m)), value = as.numeric(m))
  }))
  two <- function(tab, v) {
    m <- aggregate(list(value = d$pct_red), by = list(s2t = d$s2t, lev = d[[v]]), FUN = mean)
    data.frame(cell = paste0(tab, " s2t=", m$s2t, " ", v, "=", m$lev), value = m$value)
  }
  rbind(b1, two("B2", "d1"), two("B3", "B"), two("B4", "a"))
}

# docs/three_way.md, section "All cells": paper and original_2009 (whole points)
tw <- readLines("docs/three_way.md", encoding = "UTF-8")
rows <- tw[seq(which(tw == "## All cells") + 3, length(tw))]
rows <- rows[grepl("^\\| ", rows) & !grepl("^\\| (---|cell )", rows)]
parts <- lapply(strsplit(rows, "\\|"), function(p) trimws(p[-1]))
tw_cells <- data.frame(cell = sapply(parts, `[`, 1),
                       paper = as.numeric(sapply(parts, `[`, 2)),
                       original = as.numeric(sapply(parts, `[`, 3)),
                       baseline_tw = as.numeric(sapply(parts, `[`, 4)))
stopifnot(nrow(tw_cells) == 71)

cells <- function(variant) {
  x <- cells_of(res[[paste0("results_", variant)]])
  setNames(x$value, x$cell)[tw_cells$cell]
}
corrected <- cells("intercept_TRUE")
seed2009  <- cells("sens_seed_2009")
stopifnot(!anyNA(corrected), max(abs(round(corrected) - tw_cells$baseline_tw)) <= 1)

# --- Figure 1: published vs reproduced, by cell -------------------------------------------
png(file.path(fig_dir, "fig1_published_vs_reproduced.png"), width = 6.5, height = 5.2,
    units = "in", res = 300)
par(mar = c(4.2, 4.6, 1, 1), las = 1, cex = 0.95)
lim <- range(c(tw_cells$paper, tw_cells$original, corrected))
plot(NA, xlim = lim, ylim = lim, xlab = "Published reduction in ISB (%)",
     ylab = "Reproduced reduction in ISB (%)", bty = "l")
abline(0, 1, col = light, lwd = 1.5)
points(tw_cells$paper, tw_cells$original, pch = 16, col = grey, cex = 0.9)
points(tw_cells$paper, corrected, pch = 16, col = blue, cex = 0.9)
legend("topleft", bty = "n", pch = 16, col = c(grey, blue),
       legend = c("Original 2009 program, run in 2026", "Rebuild, corrected"))
text(-8, -12, "45° line", pos = 4, col = grey, cex = 0.85)
invisible(dev.off())

# --- Figure 2: which detail closes the gap ------------------------------------------------
# Mean absolute difference from the original 2009 program over the 71 cells. The first three
# were computed from the unrounded 2026 run of the original program (docs/three_way.md,
# docs/replication_verdict.md); three_way.md gives its cells only to whole points, which
# would add about 0.25 to a difference near zero. The seed replicate is computed here from
# those whole-point cells; the check below shows the same calculation gives the documented
# value for the corrected rebuild.
mad_doc <- c("Rebuild, corrected" = 3.9, "Caliper after loop" = 10.5,
             "Caliper after loop +\nflag update" = 0.11)
mad_seed <- mean(abs(seed2009 - tw_cells$original))
stopifnot(abs(mean(abs(corrected - tw_cells$original)) - mad_doc[[1]]) < 0.1)
mad <- c(mad_doc, "Seed replicate\n(corrected, seed 2009)" = mad_seed)
noise <- abs(seed2009 - corrected)
noise_mean <- mean(noise); noise_max <- max(noise)

png(file.path(fig_dir, "fig2_which_detail.png"), width = 6.5, height = 3.6,
    units = "in", res = 300)
par(mar = c(4.2, 11.5, 1, 1), las = 1, cex = 0.95)
ord <- c(3, 1, 4, 2)
y <- seq_along(ord)
plot(mad[ord], y, log = "x", xlim = c(0.08, 15), ylim = c(0.5, length(ord) + 0.5),
     pch = 16, cex = 1.3, col = ifelse(ord == 3, blue, grey), yaxt = "n", bty = "l", ylab = "",
     xlab = "Mean absolute difference from the original program\n(percentage points, log scale)")
axis(2, at = y, labels = names(mad)[ord], tick = FALSE, cex.axis = 0.9)
abline(v = c(noise_mean, noise_max), lty = 2, col = grey)
text(noise_mean, length(ord) + 0.45, sprintf("seed noise, mean (%.1f)", noise_mean),
     pos = 4, cex = 0.75, col = grey, offset = 0.3)
text(noise_max, length(ord) + 0.45, sprintf("seed noise, max (%.2f)", noise_max),
     pos = 4, cex = 0.75, col = grey, offset = 0.3)
legend(0.21, 3.35, bty = "n", pch = 16, col = c(blue, grey), cex = 0.75,
       legend = c("both details", "other variants"))
mad_lab <- c("3.9", "10.5", "0.11", sprintf("%.1f", mad_seed))
text(mad[ord], y, mad_lab[ord], pos = 3, cex = 0.8,
     col = ifelse(ord == 3, blue, grey), offset = 0.5)
invisible(dev.off())

# --- Figure 3: where the correction matters ------------------------------------------------
diff <- corrected - tw_cells$paper
tab <- sub(" .*$", "", tw_cells$cell)
keep <- tab %in% c("B2", "B3", "B4")
s2t <- ifelse(keep, suppressWarnings(as.numeric(sub("^.*s2t=([^ ]+) .*$", "\\1", tw_cells$cell))), NA)
i_max <- which(keep)[which.max(diff[keep])]
i_min <- which(keep)[which.min(diff[keep])]

png(file.path(fig_dir, "fig3_where_correction_matters.png"), width = 6.5, height = 4,
    units = "in", res = 300)
par(mfrow = c(1, 3), mar = c(4.2, 1, 2, 0.5), oma = c(0, 3.6, 0, 0), las = 1, cex = 0.9)
ylim <- range(diff[keep]) + c(-3, 4)
for (tb in c("B2", "B3", "B4")) {
  idx <- which(tab == tb)
  idx <- idx[order(s2t[idx], seq_along(idx))]
  x <- seq_along(idx) + (match(s2t[idx], c(0.5, 1, 1.5)) - 1)
  plot(NA, xlim = range(x) + c(-0.5, 0.5), ylim = ylim, xaxt = "n", yaxt = "n", bty = "l",
       xlab = "", main = paste("Table", tb), font.main = 1, cex.main = 1)
  if (tb == "B2") axis(2) else axis(2, labels = FALSE)
  abline(h = 0, col = light, lwd = 1.5)
  for (s in c(0.5, 1, 1.5)) {
    k <- s2t[idx] == s
    lines(x[k], diff[idx][k], col = light)
    points(x[k], diff[idx][k], pch = 16, col = grey, cex = 0.9)
    mtext(bquote(sigma[t]^2 == .(s)), side = 1, line = 0.8, at = mean(x[k]), cex = 0.6)
  }
  mtext(switch(tb, B2 = quote(delta[1] ~ "(0\u20131.25) within" ~ sigma[t]^2),
               B3 = quote("B (0.5\u20131.5) within" ~ sigma[t]^2),
               B4 = quote("a (\u22121 to 1) within" ~ sigma[t]^2)), side = 1, line = 2.4, cex = 0.62)
  for (i in c(i_max, i_min)) if (i %in% idx) {
    xi <- x[match(i, idx)]
    points(xi, diff[i], pch = 16, col = blue, cex = 1.1)
    par_txt <- sub("-", "\u2212", sub("=", " = ", sub("^.* ", "", tw_cells$cell[i])))
    d_txt <- sub("-", "\u2212", sprintf("%+.0f", diff[i]))
    lab <- bquote(.(tb) * "," ~ sigma[t]^2 == .(s2t[i]) * "," ~ .(par_txt) * ":" ~ .(d_txt))
    if (diff[i] > 0) text(xi, diff[i], lab, pos = 2, col = blue, cex = 0.75, offset = 0.4, xpd = NA)
    else text(xi + 0.6, diff[i] - 1.3, lab, adj = c(1, 1), col = blue, cex = 0.75, xpd = NA)  }
}
mtext("Corrected minus published (percentage points)", side = 2, line = 2.3, outer = TRUE,
      las = 0, cex = 0.75)
invisible(dev.off())

cat(sprintf("Figures written to %s/\n", fig_dir))
cat(sprintf("Seed replicate vs original: %.2f; seed noise: mean %.2f, max %.2f\n",
            mad_seed, noise_mean, noise_max))
cat(sprintf("Largest gain: %s (%+.1f); largest loss: %s (%+.1f)\n",
            tw_cells$cell[i_max], diff[i_max], tw_cells$cell[i_min], diff[i_min]))
