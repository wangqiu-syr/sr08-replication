# Smoke test: run R/sr08_appendixB.R on a tiny grid (2 replications, 5 imputations) in
# three configurations and print timings and summary statistics. Takes about a minute.
# Run from the repo root: Rscript R/run_smoke.R
options(warn = 1)
r_dir <- normalizePath("R", mustWork = TRUE)

run_sr08 <- function(reps = 2, J = 5) {
  source(file.path(r_dir, "sr08_appendixB.R"))
  g <- subset(sr08_grid(), d1 %in% c(0, 1) & Nt == 100 & ratio == 2 & B %in% c(1, 1.5) & a %in% c(0, 1) & s2t %in% c(.5, 1.5))
  out <- list()
  for (cfg in list(c(TRUE, "stuart"), c(FALSE, "stuart"), c(TRUE, "linear"))) {
    t0 <- proc.time()[[3]]
    r <- tryCatch(sr08_run(g, reps = reps, J = J, seed = 2026, intercept = as.logical(cfg[1]), a0 = cfg[2]), error = function(e) e)
    tag <- paste0("intercept=", cfg[1], ", a0=", cfg[2])
    if (inherits(r, "error")) { cat(tag, "ERROR:", conditionMessage(r), "\n"); next }
    cat(tag, "| sec:", round(proc.time()[[3]] - t0, 1), "| mean %red:", round(mean(r$pct_red), 2),
        "| pooled %red:", round(100 * (1 - mean(r$mean_isb) / mean(r$mean_iisb)), 2), "| C1 share:", round(mean(r$pct_c1), 3), "\n")
    out[[tag]] <- r
  }
  invisible(out)
}

if (sys.nframe() == 0) {   # Rscript R/run_smoke.R
  cat("========== sr08_appendixB.R (tiny grid) ==========\n")
  run_sr08()
}
