# sr08_appendixB.R
# A clean re-implementation of Stuart & Rubin (2008, JEBS 33(3), 279-306),
# Appendix A (matching adjustment procedure) and Appendix B (simulation design),
# written from the paper's text only. Author: Qiu Wang. License: MIT.
#
# Design (Appendix B):  X_t ~ N(B/2, s2t),  X_c1 ~ N(-B/2, 2 - s2t),  C2 infinite.
#   E(Y(j) | X, D) = g_j + exp(a X) + (d0 + d1 X) D,   D_t = D_c1 = 0, D_c2 = 1,  tau = 0.
#   No residual variance: outcomes are mean responses, so bias is measured by ISB.
# Grid: d0 = 0; d1 in {0,.25,.5,.75,1,1.25}; Nt in {100,200}; Nc1/Nt in {2,5};
#   B in {.5,.75,1,1.25,1.5}; s2t in {.5,1,1.5}; a in {-1,-.5,0,.5,1}  -> 1,800 settings.
# Procedure (Appendix A): caliper match T to C1 (0.2 SD of X in T); exact C2 matches for
# matched C1 units (C1:C2) and for unmatched T (C2:T); fit Y ~ X + D on C1:C2; draw
# sigma^2 ~ Inv-chi2(n - (p+2), s^2) and d | sigma^2 ~ N(d_hat, (X'X)^-1 sigma^2);
# impute Y(0) = y(0) - d for C2 matches; J = 50 imputations; combine with Rubin's rules.

sr08_grid <- function() {
  expand.grid(d0 = 0, d1 = c(0, .25, .5, .75, 1, 1.25), Nt = c(100, 200), ratio = c(2, 5),
              B = c(.5, .75, 1, 1.25, 1.5), s2t = c(.5, 1, 1.5), a = c(-1, -.5, 0, .5, 1))
}

# a = 0 makes exp(a X) constant, so Y carries no initial bias. Two conventions:
#   a0 = "stuart": keep exp(0X) = 1 and define IISB from the X difference (the convention
#              of the original simulation program, which is not included here);
#   a0 = "linear": use the Rubin (1979) limit V(X) = X when a = 0.
mu_y <- function(x, a, d0, d1, D, g = 0, a0 = "stuart")
  g + (if (a == 0 && a0 == "linear") x else exp(a * x)) + (d0 + d1 * x) * D

# Greedy 1:1 caliper matching without replacement. Treated units are taken in the given
# order; a treated unit is matched only if its nearest unused control is within the caliper
# (caliper applied inside the loop). Returns the matched control index, or NA.
greedy_caliper <- function(xt, xc, caliper) {
  used <- logical(length(xc)); m <- rep(NA_integer_, length(xt))
  for (i in seq_along(xt)) {
    free <- which(!used); if (!length(free)) break
    j <- free[which.min(abs(xc[free] - xt[i]))]
    if (abs(xc[j] - xt[i]) <= caliper) { m[i] <- j; used[j] <- TRUE }
  }
  m
}

# Sensitivity variant: greedy 1:1 nearest unused control for EVERY treated unit first
# (no caliper in the loop), then pairs farther apart than the caliper are dropped.
# Dropped pairs' controls stay used, so later treated units could not have taken them.
greedy_after_caliper <- function(xt, xc, caliper) {
  used <- logical(length(xc)); m <- rep(NA_integer_, length(xt))
  for (i in seq_along(xt)) {
    free <- which(!used); if (!length(free)) break
    j <- free[which.min(abs(xc[free] - xt[i]))]
    m[i] <- j; used[j] <- TRUE
  }
  m[!is.na(m) & abs(xc[m] - xt) > caliper] <- NA_integer_
  m
}

# One replication at one setting. xt, xc are the covariate draws (nested design).
# intercept = TRUE is the default d model (decided Nov 2026: it tracks SR08 Tables B2-B4
# far better than the no-intercept model; see results/sr08/summary.md).
# Sensitivity options:
#   caliper = "sample": caliper_sd * sd(xt) (default); "true": caliper_sd * sqrt(s2t).
#   order   = "given":  treated units matched in draw order, i.e. random (default);
#             "high_low": treated units sorted by X, largest first.
#   caliper_when = "inside": caliper checked inside the greedy loop (default);
#             "after": match everyone greedily, then drop pairs outside the caliper.
#   recycle_flags = TRUE (needs caliper_when = "after"): reproduce how the original 2009
#             program (not included) updates the matched-control flags. A condition computed
#             over the treated units (pair outside the caliper) is used to clear flags stored
#             on the longer list of C1 units, so R recycles it by row position, regardless of
#             which treated unit a C1 unit was matched to. The C1 units still flagged (mostly
#             including the controls of rejected pairs, and missing some controls of good
#             pairs) are then used both in the C1:C2 model and as the matched controls;
#             treated units of rejected pairs also get C2 matches. Written from this
#             description of the behaviour.
sr08_rep <- function(xt, xc, s, J = 50, caliper_sd = 0.2, intercept = TRUE, a0 = "stuart",
                     caliper = "sample", order = "given", caliper_when = "inside", recycle_flags = FALSE) {
  if (order == "high_low") xt <- sort(xt, decreasing = TRUE) else if (order != "given") stop("order: ", order)
  my  <- function(x, D) mu_y(x, s$a, s$d0, s$d1, D = D, a0 = a0)
  yt  <- my(xt, 0)                                     # treatment effect is 0
  yc1 <- my(xc, 0)
  iisb <- if (s$a == 0 && a0 == "stuart") (mean(xt) - mean(xc))^2 else (mean(yt) - mean(yc1))^2

  sd_ref <- switch(caliper, sample = sd(xt), true = sqrt(s$s2t), stop("caliper: ", caliper))
  if (recycle_flags) {
    if (caliper_when != "after") stop("recycle_flags = TRUE requires caliper_when = \"after\"")
    m_all <- greedy_after_caliper(xt, xc, Inf)         # every treated unit gets a C1 match
    bad <- abs(xc[m_all] - xt) > caliper_sd * sd_ref
    has1 <- !bad
    kc <- m_all[!bad[((m_all - 1) %% length(xt)) + 1]] # C1 units left flagged after recycling
  } else {
    matcher <- switch(caliper_when, inside = greedy_caliper, after = greedy_after_caliper,
                      stop("caliper_when: ", caliper_when))
    m <- matcher(xt, xc, caliper_sd * sd_ref)          # Step 1: C1:T
    has1 <- !is.na(m)
    kc <- m[has1]
  }
  # Step 2: C1:C2. Infinite C2 gives exact matches on X for the matched C1 units.
  x12 <- c(xc[kc], xc[kc]); D12 <- rep(0:1, each = length(kc))
  y12 <- my(x12, D12)
  # Step 3: C2:T. Exact C2 matches for treated units without a C1 match.
  y2t <- my(xt[!has1], 1)

  # Step 4: model for the C1-C2 difference.
  fit <- if (intercept) lm(y12 ~ x12 + D12) else lm(y12 ~ x12 + D12 - 1)
  k <- length(coef(fit)); n12 <- length(y12)
  s2hat <- sum(resid(fit)^2) / (n12 - k)
  dhat <- coef(fit)[["D12"]]; vD <- summary(fit)$cov.unscaled["D12", "D12"]

  Q <- U <- numeric(J); yt_ord <- c(yt[has1], yt[!has1])
  for (j in seq_len(J)) {
    sig2 <- if (length(kc) > 0 && n12 > k) (n12 - k) * s2hat / rchisq(1, n12 - k) else 0  # Step 5
    d <- rnorm(1, dhat, sqrt(vD * sig2))
    y0 <- c(yc1[kc], y2t - d)                          # Step 6
    Q[j] <- mean(yt_ord) - mean(y0)                    # Step 7: ATT by difference in means
    U[j] <- if (recycle_flags) var(yt_ord) / length(yt) + var(y0) / length(yt)   # groups not paired
            else var(yt_ord - y0) / length(yt_ord)     # paired-difference variance
  }
  qbar <- mean(Q); Tvar <- mean(U) + (1 + 1 / J) * var(Q)   # Step 8: Rubin's rules
  c(iisb = iisb, isb = qbar^2, q = qbar, se = sqrt(Tvar), pct_c1 = mean(has1),
    d_hat = dhat, d_true_at_mean = s$d0 + s$d1 * mean(xt))
}

# ---- Random numbers -------------------------------------------------------------------
# Nested-draw design (as in Rubin 1979): standardized covariates are drawn once per
# replication at the largest sizes of the FULL grid and rescaled per setting, so every
# setting (and both intercept configurations) shares the same X draws.
# Imputation draws (Steps 5-6) come from one L'Ecuyer-CMRG stream per setting ID (the row
# number in sr08_grid()), so a setting's result does not depend on which worker ran it,
# on the order settings ran in, or on whether the run was resumed.
sr08_rng <- function(seed = 2008, reps = 500, n_ids = nrow(sr08_grid())) {
  RNGkind("L'Ecuyer-CMRG"); set.seed(seed)
  full <- sr08_grid(); maxNt <- max(full$Nt); maxNc <- max(full$Nt * full$ratio)
  zt <- matrix(rnorm(maxNt * reps), maxNt); zc <- matrix(rnorm(maxNc * reps), maxNc)
  seeds <- vector("list", n_ids); st <- .Random.seed
  for (g in seq_len(n_ids)) { st <- parallel::nextRNGStream(st); seeds[[g]] <- st }
  list(zt = zt, zc = zc, seeds = seeds, seed = seed, reps = reps)
}

# One setting (row `id` of the full grid). Returns a one-row summary.
# `...` are sr08_rep options (J, intercept, a0, caliper, order, caliper_when, recycle_flags).
# d0 overrides the grid's d0 = 0 (sensitivity check; recorded in the output's d0 column).
sr08_setting <- function(id, rng, ..., d0 = NULL, grid = sr08_grid()) {
  assign(".Random.seed", rng$seeds[[id]], envir = globalenv())
  s <- grid[id, ]; Nc <- s$Nt * s$ratio
  if (!is.null(d0)) s$d0 <- d0
  t0 <- proc.time()[["elapsed"]]
  r <- sapply(seq_len(rng$reps), function(k)
    sr08_rep(xt = s$B / 2 + sqrt(s$s2t) * rng$zt[seq_len(s$Nt), k],
             xc = -s$B / 2 + sqrt(2 - s$s2t) * rng$zc[seq_len(Nc), k], s = s, ...))
  data.frame(id = id, s, mean_iisb = mean(r["iisb", ]), mean_isb = mean(r["isb", ]),
             pct_red = 100 * (1 - mean(r["isb", ]) / mean(r["iisb", ])),
             pct_c1 = mean(r["pct_c1", ]), sec = proc.time()[["elapsed"]] - t0, row.names = NULL)
}

# Serial run over a grid (or a subset of its rows); used by R/run_smoke.R.
sr08_run <- function(grid = sr08_grid(), reps = 500, J = 50, seed = 2008, intercept = TRUE, a0 = "stuart", ...) {
  rng <- sr08_rng(seed, reps)
  do.call(rbind, lapply(as.integer(rownames(grid)), sr08_setting, rng = rng, J = J,
                        intercept = intercept, a0 = a0, ...))
}

# ---- Overnight-safe parallel run ----------------------------------------------------
sr08_log <- function(log_file, ...) {
  cat(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " ", ..., "\n", sep = "", file = log_file, append = TRUE)
}

# Runs settings `ids` in parallel, one checkpoint file per setting in out_dir
# (setting_XXXX.rds). Settings already on disk are skipped, so rerunning resumes.
# out_dir/meta.rds records reps/J/seed/intercept/a0; a mismatch stops the run rather than
# mixing results from different designs.
sr08_run_par <- function(ids = seq_len(nrow(sr08_grid())), out_dir, log_file, reps = 500, J = 50,
                         seed = 2008, intercept = TRUE, a0 = "stuart",
                         caliper = "sample", order = "given", caliper_when = "inside",
                         recycle_flags = FALSE, d0 = 0,
                         workers = max(1, parallel::detectCores() - 1),
                         script = sr08_script_path()) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  meta <- list(reps = reps, J = J, seed = seed, intercept = intercept, a0 = a0)
  if (caliper != "sample") meta$caliper <- caliper   # only non-defaults, so older
  if (order != "given")    meta$order   <- order     # checkpoint folders still match
  if (caliper_when != "inside") meta$caliper_when <- caliper_when
  if (recycle_flags) meta$recycle_flags <- TRUE
  if (d0 != 0) meta$d0 <- d0
  opts <- list(J = J, intercept = intercept, a0 = a0, caliper = caliper, order = order,
               caliper_when = caliper_when, recycle_flags = recycle_flags, d0 = d0)
  mf <- file.path(out_dir, "meta.rds")
  if (file.exists(mf)) {
    if (!identical(readRDS(mf), meta))
      stop(out_dir, " holds results from a different design (see meta.rds). Use another out_dir.")
  } else saveRDS(meta, mf)
  ck <- function(id) sr08_ck(out_dir, id)
  todo <- ids[!file.exists(vapply(ids, ck, ""))]
  tag <- sprintf("[%s reps=%d J=%d]", paste(names(meta)[-(1:3)], meta[-(1:3)], sep = "=", collapse = " "),
                 reps, J)
  if (seed != 2008) tag <- sub("]$", paste0(" seed=", seed, "]"), tag)
  sr08_log(log_file, tag, " start: ", length(ids), " settings, ", length(ids) - length(todo),
           " already done, ", length(todo), " to run on ", workers, " workers")
  if (length(todo)) {
    rng <- sr08_rng(seed, reps)
    cl <- parallel::makeCluster(min(workers, length(todo)))
    on.exit(parallel::stopCluster(cl), add = TRUE)
    parallel::clusterCall(cl, function(f) { source(f); invisible(NULL) }, script)
    parallel::clusterExport(cl, c("rng", "opts", "out_dir", "log_file", "tag", "ids"),
                            envir = environment())
    # Load-balanced: settings differ ~10x in cost (Nt x ratio), so hand them out one at a time.
    parallel::parLapplyLB(cl, todo, sr08_worker, chunk.size = 1)
  }
  done <- ids[file.exists(vapply(ids, ck, ""))]
  sr08_log(log_file, tag, " finished: ", length(done), "/", length(ids), " settings on disk")
  do.call(rbind, lapply(done, function(id) readRDS(ck(id))))
}

sr08_ck <- function(out_dir, id) file.path(out_dir, sprintf("setting_%04d.rds", id))

# All per-setting result tables live in one named list, results/sr08/results_all.rds, with
# names such as "results_intercept_TRUE" or "results_sens_seed_2009". This adds or replaces
# one element and rewrites the file atomically.
sr08_save_result <- function(dir, name, r) {
  f <- file.path(dir, "results_all.rds")
  all <- if (file.exists(f)) readRDS(f) else list()
  all[[name]] <- r; all <- all[order(names(all))]
  tmp <- paste0(f, ".tmp"); saveRDS(all, tmp); file.rename(tmp, f)
  invisible(f)
}

# Runs on a worker. Uses the globals exported by sr08_run_par (rng, opts, out_dir,
# log_file, tag, ids); defined at top level so tasks don't carry the caller's frame.
sr08_worker <- function(id) {
  res <- tryCatch(do.call(sr08_setting, c(list(id, rng), opts)), error = function(e) e)
  if (inherits(res, "error")) {
    sr08_log(log_file, tag, " setting ", sprintf("%04d", id), " ERROR: ", conditionMessage(res))
    return(NULL)
  }
  f <- sr08_ck(out_dir, id); tmp <- paste0(f, ".tmp")
  saveRDS(res, tmp); file.rename(tmp, f)        # a crash mid-write leaves only a .tmp
  n_done <- sum(file.exists(vapply(ids, function(i) sr08_ck(out_dir, i), "")))
  sr08_log(log_file, tag, " setting ", sprintf("%04d", id), " done in ",
           sprintf("%.1f", res$sec), "s  [", n_done, "/", length(ids), "]")
  NULL
}

sr08_script_path <- function() {
  a <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(a)) return(normalizePath(sub("^--file=", "", a[1])))
  normalizePath(file.path("R", "sr08_appendixB.R"), mustWork = TRUE)
}

# Tables in the paper's layout: percentage reduction (remaining ISB).
# digits = NULL returns unrounded means (used for the sensitivity comparisons).
sr08_tables <- function(res, digits = 0) {
  rnd <- if (is.null(digits)) identity else function(x) round(x, digits)
  f <- function(v) rnd(tapply(res$pct_red, res[[v]], mean))
  list(B1 = lapply(c("d1", "Nt", "ratio", "B", "a", "s2t"), f) |> setNames(c("d1", "Nt", "ratio", "B", "a", "s2t")),
       B2 = rnd(tapply(res$pct_red, list(s2t = res$s2t, d1 = res$d1), mean)),
       B3 = rnd(tapply(res$pct_red, list(s2t = res$s2t, B = res$B), mean)),
       B4 = rnd(tapply(res$pct_red, list(s2t = res$s2t, a = res$a), mean)))
}

# Paper values for comparison: percentage reduction in ISB, SR08 Appendix B, Tables B1-B4
# (pp. 302-303). B1 is the one-way main effects; the paper's overall mean is 80.6% (p. 296).
sr08_paper_lv <- function(v) as.character(sort(unique(sr08_grid()[[v]])))
sr08_paper <- list(
  overall_mean = 80.6,
  B1 = list(d1 = c(98, 98, 92, 82, 67, 47), Nt = c(81, 81), ratio = c(74, 88),
            B = c(75, 81, 83, 83, 81), a = c(90, 56, 90, 73, 96), s2t = c(98, 91, 54)) |>
    (\(l) Map(function(v, nm) setNames(v, sr08_paper_lv(nm)), l, names(l)))(),
  B2 = matrix(c(99, 99, 99, 98, 96, 95,  99, 98, 95, 91, 84, 76,  95, 95, 83, 58, 20, -30), 3, byrow = TRUE,
              dimnames = list(s2t = c(.5, 1, 1.5), d1 = c(0, .25, .5, .75, 1, 1.25))),
  B3 = matrix(c(99, 98, 98, 98, 96,  94, 93, 91, 89, 86,  30, 52, 61, 62, 63), 3, byrow = TRUE,
              dimnames = list(s2t = c(.5, 1, 1.5), B = c(.5, .75, 1, 1.25, 1.5))),
  B4 = matrix(c(99, 98, 99, 95, 96,  99, 86, 94, 78, 95,  70, -17, 76, 44, 95), 3, byrow = TRUE,
              dimnames = list(s2t = c(.5, 1, 1.5), a = c(-1, -.5, 0, .5, 1))))

# ---- summary.md -----------------------------------------------------------------------
md_table <- function(df) {
  df[] <- lapply(df, function(v) if (is.numeric(v)) format(v, trim = TRUE) else as.character(v))
  c(paste0("| ", paste(names(df), collapse = " | "), " |"),
    paste0("|", paste(rep(" --- ", ncol(df)), collapse = "|"), "|"),
    apply(df, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |")))
}

# res: named list of result data frames, e.g. list(`intercept=TRUE` = ..., `intercept=FALSE` = ...)
sr08_summary_md <- function(res, file, n_expected = nrow(sr08_grid()), note = character()) {
  tabs <- lapply(res, sr08_tables)
  L <- c("# SR08 Appendix B replication: summary", "",
         paste0("Written ", format(Sys.time(), "%Y-%m-%d %H:%M"), " by R/sr08_appendixB.R. ",
                "Cells are the mean percentage reduction in ISB across settings (remaining ISB in ",
                "the paper's sense: 100 = all initial bias removed)."), "", note, "")
  L <- c(L, "## Overall", "",
         md_table(data.frame(config = names(res),
                             settings = sapply(res, nrow), expected = n_expected,
                             mean_pct_red = round(sapply(res, function(r) mean(r$pct_red)), 1),
                             pooled_pct_red = round(sapply(res, function(r) 100 * (1 - mean(r$mean_isb) / mean(r$mean_iisb))), 1),
                             mean_IISB = signif(sapply(res, function(r) mean(r$mean_iisb)), 3),
                             mean_ISB = signif(sapply(res, function(r) mean(r$mean_isb)), 3),
                             mean_share_C1 = round(sapply(res, function(r) mean(r$pct_c1)), 3),
                             row.names = NULL)), "",
         "`mean_share_C1` is the mean share of treated units matched to C1 (the rest get C2 matches).",
         "Percent reduction is unstable when IISB is near 0, so mean IISB and ISB are shown too.", "")
  # B1: one-way margins, ours next to the paper.
  L <- c(L, "## Table B1 (one-way margins)", "", paste0("Paper overall mean: ", sr08_paper$overall_mean, "%."), "")
  for (v in names(tabs[[1]]$B1)) {
    lv <- names(tabs[[1]]$B1[[v]])
    df <- data.frame(level = lv, check.names = FALSE)
    for (cfg in names(tabs)) df[[cfg]] <- as.numeric(tabs[[cfg]]$B1[[v]][lv])
    df$paper <- as.numeric(sr08_paper$B1[[v]][lv])
    df$share_C1 <- round(tapply(res[[1]]$pct_c1, res[[1]][[v]], mean)[lv], 3)
    names(df)[1] <- v; names(df)[ncol(df)] <- paste0("share_C1 (", names(res)[1], ")")
    L <- c(L, paste0("**", v, "**"), "", md_table(df), "")
  }
  # B2-B4: s2t by d1 / B / a, ours next to the paper.
  for (b in c("B2", "B3", "B4")) {
    P <- sr08_paper[[b]]; cn <- colnames(P)
    rows <- list()
    for (s in rownames(P)) {
      for (cfg in names(tabs)) {
        o <- tabs[[cfg]][[b]]
        rows[[length(rows) + 1]] <- c(s2t = s, source = paste("ours", cfg), o[s, cn])
      }
      rows[[length(rows) + 1]] <- c(s2t = s, source = "paper", P[s, cn])
    }
    df <- as.data.frame(do.call(rbind, rows), check.names = FALSE)
    names(df)[-(1:2)] <- paste0(names(dimnames(P))[2], "=", cn)
    L <- c(L, paste0("## Table ", b, " (s2t by ", names(dimnames(P))[2], ")"), "", md_table(df), "")
  }
  writeLines(L, file)
  invisible(file)
}

# ---- Sensitivity comparison -----------------------------------------------------------
# Flatten B1-B4 (unrounded) into one named vector of cells, e.g. "B2 s2t=1 d1=0.5".
sr08_cells <- function(tabs) {
  b1 <- unlist(Map(function(x, v) setNames(x, paste0("B1 ", v, "=", names(x))), tabs$B1, names(tabs$B1)))
  m2v <- function(M, b) {
    cn <- names(dimnames(M))
    setNames(as.vector(M), paste0(b, " ", cn[1], "=", rownames(M)[row(M)], " ", cn[2], "=", colnames(M)[col(M)]))
  }
  c(b1, m2v(tabs$B2, "B2"), m2v(tabs$B3, "B3"), m2v(tabs$B4, "B4"))
}

# res: named list, first element = baseline, and one element named "seed_2009" (MC noise).
sr08_sensitivity_md <- function(res, file, note = character()) {
  P <- sr08_cells(sr08_paper[c("B1", "B2", "B3", "B4")])
  C <- lapply(res, function(r) sr08_cells(sr08_tables(r, digits = NULL))[names(P)])
  s1 <- grepl("^B[234] s2t=1 ", names(P))                      # the s2t = 1 rows of B2-B4
  b4 <- names(P) == "B4 s2t=1.5 a=0.5"
  noise <- abs(C[["seed_2009"]] - C[[1]])
  summ <- data.frame(
    variant = names(res),
    mean_pct_red = round(sapply(res, function(r) mean(r$pct_red)), 1),
    share_C1 = round(sapply(res, function(r) mean(r$pct_c1)), 3),
    mean_ISB = signif(sapply(res, function(r) mean(r$mean_isb)), 3),
    `MAD vs paper, all 71 cells` = round(sapply(C, function(x) mean(abs(x - P))), 1),
    `s2t=1 cells (16): mean gap` = round(sapply(C, function(x) mean(x[s1] - P[s1])), 1),
    `s2t=1 cells: MAD` = round(sapply(C, function(x) mean(abs(x[s1] - P[s1]))), 1),
    `B4 s2t=1.5 a=0.5 (paper 44)` = round(sapply(C, function(x) x[b4]), 1),
    check.names = FALSE, row.names = NULL)
  shift <- function(sel) round(sapply(C, function(x) mean(abs(x[sel] - C[[1]][sel]))), 1)
  summ$`s2t=1: mean abs change vs baseline` <- shift(s1)
  L <- c("# SR08 Appendix B: sensitivity variants", "",
         paste0("Written ", format(Sys.time(), "%Y-%m-%d %H:%M"), " by `Rscript R/sr08_appendixB.R sensitivity`. ",
                "All variants: intercept = TRUE, reps = 500, J = 50, full 1,800-setting grid. ",
                "Cells are mean percentage reduction in ISB; gaps are ours minus paper (positive = we remove more bias)."), "",
         "- **baseline**: caliper 0.2 x sample SD of treated X, treated units matched in random (draw) order, a0 = \"stuart\", seed 2008.",
         "- **caliper_true**: caliper 0.2 x true sigma_t = 0.2 x sqrt(s2t).",
         "- **order_high_low**: treated units sorted by X, largest first, before greedy matching.",
         "- **a0_linear**: V(X) = X when a = 0 (Rubin 1979 limit). Only the 360 a = 0 settings can change; they were rerun and the rest copied from the baseline (checked identical on settings 1 and 1500).",
         "- **caliper_after_loop**: greedy nearest unused control for every treated unit first, then pairs outside the caliper dropped (their controls stay used), as in the original 2009 program (not included). Caliper still 0.2 x sample SD, so this isolates when the caliper is applied.",
         "- **seed_2009**: baseline with seed 2009 (new X draws and imputation streams). Its distance from the baseline measures Monte Carlo noise.",
         "", note, "", "## Summary", "", md_table(summ), "",
         sprintf("Monte Carlo noise (|seed_2009 - baseline|): mean %.1f, max %.1f points over all 71 cells; mean %.1f over the s2t = 1 cells; %.1f at B4 s2t=1.5 a=0.5.",
                 mean(noise), max(noise), mean(noise[s1]), noise[b4]),
         "A variant's change matters only if it is clearly larger than this noise.", "")
  # Verdict: a variant closes a gap only if it beats the baseline by more than 2x the noise.
  vs <- setdiff(names(C), c(names(C)[1], "seed_2009"))
  mad1 <- sapply(C[c(names(C)[1], vs)], function(x) mean(abs(x[s1] - P[s1])))
  gap4 <- sapply(C[c(names(C)[1], vs)], function(x) unname(abs(x[b4] - P[b4])))
  verdict <- function(score, noise_lvl, what) {
    best <- names(which.min(score[vs])); gain <- score[[1]] - score[[best]]
    if (gain > 2 * noise_lvl)
      sprintf("- **%s:** `%s` closes it best: %.1f -> %.1f points from the paper (baseline %.1f; noise %.1f).",
              what, best, score[[1]], score[[best]], score[[1]], noise_lvl)
    else sprintf("- **%s:** no variant beats the baseline by more than 2x the noise. Best is `%s` (%.1f vs baseline %.1f; noise %.1f), so none of these explains the gap.",
                 what, best, score[[best]], score[[1]], noise_lvl)
  }
  L <- c(L, "## Which variant closes the gaps best", "",
         verdict(mad1, mean(noise[s1]), "s2t = 1 rows of B2-B4 (mean absolute gap, 16 cells)"),
         verdict(gap4, noise[b4], "B4 at s2t = 1.5, a = 0.5 (absolute gap; paper 44)"), "")
  # Tables B2-B4 at s2t = 1 and 1.5: one row per variant, paper last.
  for (b in c("B2", "B3", "B4")) {
    L <- c(L, paste0("## Table ", b), "")
    for (s in c("1", "1.5")) {
      sel <- startsWith(names(P), paste0(b, " s2t=", s, " "))
      col <- sub("^B[234] s2t=[^ ]+ ", "", names(P)[sel])
      rows <- lapply(c(names(C), "paper"), function(v) {
        x <- if (v == "paper") P[sel] else C[[v]][sel]
        c(source = v, setNames(as.character(round(x)), col))
      })
      L <- c(L, paste0("**s2t = ", s, "**"), "",
             md_table(as.data.frame(do.call(rbind, rows), check.names = FALSE)), "")
    }
  }
  writeLines(L, file); invisible(file)
}

# ---- Entry point ----------------------------------------------------------------------
#   Rscript R/sr08_appendixB.R pilot   -> 20 random settings, reps = 500, J = 50 (timing)
#   Rscript R/sr08_appendixB.R full    -> all 1,800 settings, intercept = TRUE then FALSE,
#                                         then results/sr08/summary.md
#   Rscript R/sr08_appendixB.R sensitivity -> variants of the intercept = TRUE baseline
#                                         (caliper_true, order_high_low, a0_linear,
#                                         caliper_after_loop, seed_2009), then
#                                         results/sr08/sensitivity.md
#   Rscript R/sr08_appendixB.R variants_2009 -> d0_1 and caliper_after_recycle
# Rerunning any command resumes from the checkpoints on disk.
if (sys.nframe() == 0) {
  mode <- commandArgs(TRUE); mode <- if (length(mode)) mode[1] else "full"
  root <- dirname(dirname(sr08_script_path()))
  workers <- max(1, parallel::detectCores() - 1)

  if (mode == "pilot") {
    dir <- file.path(root, "results", "sr08_pilot"); dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    log <- file.path(dir, "progress.log")
    set.seed(20261106); ids <- sort(sample(nrow(sr08_grid()), 20))
    t0 <- proc.time()[["elapsed"]]
    r <- sr08_run_par(ids, out_dir = file.path(dir, "intercept_TRUE"), log_file = log,
                      reps = 500, J = 50, intercept = TRUE, workers = workers)
    wall <- proc.time()[["elapsed"]] - t0
    g <- sr08_grid(); g$Nc <- g$Nt * g$ratio
    fit <- lm(sec ~ I(Nt * ratio), data = transform(r, Nc = Nt * ratio))   # cost grows with Nc
    proj_cpu <- sum(predict(fit, newdata = g)) * 2                       # two configurations
    cat("pilot settings:", paste(ids, collapse = " "), "\n")
    cat(sprintf("wall: %.1f s on %d workers | per-setting sec: mean %.1f, median %.1f, min %.1f, max %.1f\n",
                wall, workers, mean(r$sec), median(r$sec), min(r$sec), max(r$sec)))
    print(aggregate(sec ~ Nt + ratio, data = r, FUN = function(x) round(mean(x), 1)))
    cat(sprintf("projected: %.0f worker-hours; %.1f wall-hours on %d workers (1800 x 2 configs)\n",
                proj_cpu / 3600, proj_cpu / 3600 / workers, workers))
    print(r[, c("id", "d1", "Nt", "ratio", "B", "s2t", "a", "pct_red", "pct_c1", "sec")], row.names = FALSE)
  } else if (mode == "full") {
    dir <- file.path(root, "results", "sr08"); dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    log <- file.path(dir, "progress.log")
    sr08_log(log, "full run: pid ", Sys.getpid(), ", ", R.version.string, ", ", workers, " workers")
    res <- list()
    for (int in c(TRUE, FALSE)) {
      cfg <- paste0("intercept=", int)
      res[[cfg]] <- tryCatch(
        sr08_run_par(out_dir = file.path(dir, paste0("intercept_", int)), log_file = log,
                     reps = 500, J = 50, intercept = int, workers = workers),
        error = function(e) { sr08_log(log, cfg, " FAILED: ", conditionMessage(e)); NULL })
      if (!is.null(res[[cfg]])) sr08_save_result(dir, paste0("results_intercept_", int), res[[cfg]])
    }
    res <- Filter(Negate(is.null), res)
    n <- sapply(res, nrow)
    note <- if (length(res) < 2 || any(n < nrow(sr08_grid())))
      paste0("**INCOMPLETE:** settings on disk per config: ", paste(names(n), n, sep = " ", collapse = ", "),
             ". Rerun `Rscript R/sr08_appendixB.R full` to finish the missing ones.") else character()
    if (length(res)) {
      sr08_summary_md(res, file.path(dir, "summary.md"), note = note)
      sr08_log(log, "wrote ", file.path(dir, "summary.md"), if (length(note)) " (INCOMPLETE)" else "")
    }
    sr08_log(log, "ALL DONE")
  } else if (mode == "sensitivity") {
    dir <- file.path(root, "results", "sr08"); dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    log <- file.path(dir, "progress.log")
    sr08_log(log, "sensitivity run: pid ", Sys.getpid(), ", ", workers, " workers")
    g <- sr08_grid()
    base <- sr08_run_par(out_dir = file.path(dir, "intercept_TRUE"), log_file = log, workers = workers)  # resumes; all on disk
    a0_ids <- which(g$a == 0); check_ids <- c(1, 1500)            # a = -1 and a = 1: must equal baseline
    variants <- list(caliper_true = list(caliper = "true"), order_high_low = list(order = "high_low"),
                     a0_linear = list(a0 = "linear", ids = c(a0_ids, check_ids)),
                     caliper_after_loop = list(caliper_when = "after"), seed_2009 = list(seed = 2009))
    res <- list(baseline = base); note <- character()
    for (v in names(variants)) {
      a <- variants[[v]]; ids <- if (is.null(a$ids)) seq_len(nrow(g)) else a$ids; a$ids <- NULL
      r <- tryCatch(do.call(sr08_run_par, c(list(ids = ids, out_dir = file.path(dir, paste0("sens_", v)),
                                                 log_file = log, workers = workers), a)),
                    error = function(e) { sr08_log(log, v, " FAILED: ", conditionMessage(e)); NULL })
      if (is.null(r)) { note <- c(note, paste0("**", v, " FAILED**; see progress.log.")); next }
      if (v == "a0_linear") {
        cols <- setdiff(names(r), "sec")
        same <- isTRUE(all.equal(base[match(check_ids, base$id), cols], r[match(check_ids, r$id), cols],
                                 check.attributes = FALSE))
        sr08_log(log, "a0_linear: a != 0 check settings identical to baseline: ", same)
        if (!same) note <- c(note, "**WARNING:** a0_linear check settings differ from baseline; splice is not valid.")
        full <- base; full[match(r$id, full$id), ] <- r; r <- full
      }
      if (nrow(r) < nrow(g)) note <- c(note, paste0("**INCOMPLETE:** ", v, " has ", nrow(r), "/", nrow(g), " settings."))
      sr08_save_result(dir, paste0("results_sens_", v), r)
      res[[v]] <- r
    }
    if ("seed_2009" %in% names(res)) {
      sr08_sensitivity_md(res, file.path(dir, "sensitivity.md"), note = note)
      sr08_log(log, "wrote ", file.path(dir, "sensitivity.md"))
    }
    sr08_log(log, "SENSITIVITY DONE")
  } else if (mode == "variants_2009") {
    # Two variants that isolate the remaining differences from the original 2009 program:
    #   d0_1: d0 = 1 (the original program's value) instead of 0; the intercept in the d
    #         model should absorb it.
    #   caliper_after_recycle: caliper_after_loop plus the flag-recycling behaviour.
    dir <- file.path(root, "results", "sr08"); log <- file.path(dir, "progress.log")
    sr08_log(log, "variants_2009 run: pid ", Sys.getpid(), ", ", workers, " workers")
    variants <- list(d0_1 = list(d0 = 1),
                     caliper_after_recycle = list(caliper_when = "after", recycle_flags = TRUE))
    for (v in names(variants)) {
      r <- tryCatch(do.call(sr08_run_par, c(list(out_dir = file.path(dir, paste0("sens_", v)),
                                                 log_file = log, workers = workers), variants[[v]])),
                    error = function(e) { sr08_log(log, v, " FAILED: ", conditionMessage(e)); NULL })
      if (!is.null(r)) sr08_save_result(dir, paste0("results_sens_", v), r)
    }
    sr08_log(log, "VARIANTS_2009 DONE")
  } else stop("usage: Rscript R/sr08_appendixB.R [pilot|full|sensitivity|variants_2009]")
}
