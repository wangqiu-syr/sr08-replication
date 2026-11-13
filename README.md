# Matching with local and non-local control groups: An R rebuild of Stuart and Rubin’s (2008) simulation

Qiu Wang, Syracuse University · v1.0 · November 2026

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.24186061.svg)](https://doi.org/10.5281/zenodo.24186061)

## Key findings

Stuart and Rubin (2008) proposed matching treated units first to a local control group and then, for units with no close local match, to a non-local group, with an adjustment for the difference between the two control groups.

- **Published vs rebuilt.** Their Appendix B simulation reports that the method removes 80.6% of the initial squared bias (ISB) on average. An independent rebuild of that simulation, written from the paper's text alone, removes **84.3%**.
- **Cause of the gap.** Two bookkeeping details of the original program: where the caliper is applied in the matching loop, and how one line updates the matched-control flags.
- **Gap explained.** With both details added, the rebuild reproduces the original program to within 0.11 percentage points per table cell on average (at most 0.54), and the published tables to within 0.49 points on average, with no cell more than 5 points off.
- **The method stands.** The procedure in the paper's Appendix A is unaffected. Corrected, it removes more bias than published on average, by up to 23 points in one cell, though not in every cell.

## Why this replication

In school-based program evaluations, a treated student's own school often has few good comparison students, while nearby schools offer a much larger pool. That is the local/non-local setting of Stuart and Rubin (2008). Before applying and extending their method to such data, I reproduced its simulation as a foundation.

## Background

The original 2009 simulation program was provided by Elizabeth A. Stuart. It is not part of this repository. Everything here was written independently from the published description:

> Stuart, E. A., & Rubin, D. B. (2008). Matching with multiple control groups with adjustment for group differences. *Journal of Educational and Behavioral Statistics, 33*(3), 279–306.

In 2009 I ran a replication of Appendix B for my dissertation work and could not reproduce the published results. I returned to the question in 2026.

## Design (as in Appendix B)

- **Groups.** Treated units T, a local control group C1, and an effectively infinite non-local control pool C2. Here C1 and C2 are control groups.
- **Outcome model.** E(Y | X, D) = γ + exp(aX) + (δ0 + δ1·X)·D, where D marks the non-local group.
- **Matching.** Greedy 1:1 matching of T to C1 with a caliper of 0.2 SD. Treated units without a C1 match within the caliper are matched to C2.
- **Adjustment.** The group difference d is estimated from `lm(y ~ x + D)`, with an intercept, on the C1 and C2 controls. Y(0) for C2-matched units is imputed by multiple imputation (J = 50) and combined with Rubin's rules.
- **Criterion.** Percent reduction in ISB, averaged over settings.
- **Scale.** 1,800 settings × 500 replications × 50 imputations.

## What differed

Two details of the original program affect which controls end up in the analysis:

1. **When the caliper is applied.** The original program applied it after the matching loop had finished. The rebuild applies it inside the loop, as each treated unit is matched.
2. **How the matched-control flags are updated.** After the loop, the original program used a condition computed over the treated units to update flags stored on the control units. The two lists have different lengths, and R silently reuses ("recycles") the shorter condition along the longer list. So the flags can be set on the wrong controls.

Together, these details have three effects:

- controls of rejected pairs mostly stay in the sample;
- some controls of good pairs are dropped;
- some treated units get both a C1 and a C2 match.

Neither detail alone reproduces the published tables; both together do.

## Results

Comparisons cover the 71 cells of Tables B2–B4.

| Source | Mean % ISB reduction | Share matched in C1 | Mean abs diff from paper | Cells > 5 points off |
| --- | --- | --- | --- | --- |
| Published (p. 296) | 80.6 | — | — | — |
| Original 2009 program, run in 2026 | 80.9 | 0.738 | 0.5 | 0 |
| Rebuild, corrected (caliper inside loop) | 84.3 | 0.819 | 4.0 | 16 |
| Rebuild, caliper after loop only | 71.7 | 0.740 | 10.2 | 26 |
| Rebuild, caliper after loop + flag recycling | matches the original program (mean 0.11, max 0.54) | — | 0.49 | 0 |

- **Size of the change.** The corrected method gains up to 23 points in one cell (Table B4, σ²_t = 1.5, a = 0.5: 67 vs 44). It is not better everywhere: at σ²_t = 1.5, a = −1 it gives 65 vs 70.
- **No effect.** δ0 = 1 vs 0, a caliper on the true σ_t instead of the sample SD, the a = 0 convention, and a new seed all leave results within noise. Seed-to-seed noise is at most 1.5 points per cell.
- **Intercept.** Keep it. Appendix A's n − (p + 2) degrees of freedom imply one, and dropping it breaks the Table B2 pattern.

## Reproduce

Requires R 4.1 or later (the code uses the native pipe `|>`); the results here were produced with R 4.5.1. Only base R and the bundled `parallel` package are used. From the repository root:

```sh
# 1. Corrected method (reference implementation), with and without an intercept in the d model
Rscript R/sr08_appendixB.R full            # -> results/sr08/intercept_TRUE, intercept_FALSE, summary.md
# 2. Caliper after the loop only, and 4. the sensitivity runs
#    (caliper_true, order_high_low, a0_linear, caliper_after_loop, seed_2009)
Rscript R/sr08_appendixB.R sensitivity     # -> results/sr08/sens_*, sensitivity.md
# 3. Caliper after the loop + flag recycling (reproduces the published tables), and d0 = 1
Rscript R/sr08_appendixB.R variants_2009   # -> results/sr08/sens_caliper_after_recycle, sens_d0_1
# Quick check on 16 settings, 2 replications (about a minute)
Rscript R/run_smoke.R
```

The same variants from an R session, for any subset of `sr08_grid()`:

```r
source("R/sr08_appendixB.R")
g <- sr08_grid()                                            # 1,800 settings
sr08_run(g, reps = 500, J = 50, seed = 2008, intercept = TRUE)              # 1. corrected method
sr08_run(g, caliper_when = "after")                                         # 2. caliper after the loop
sr08_run(g, caliper_when = "after", recycle_flags = TRUE)                   # 3. + flag recycling
sr08_run(g, seed = 2009)                                    # 4. seed
sr08_run(g, caliper = "true")                               #    caliper on the true sigma_t
sr08_run(g, d0 = 1)                                         #    delta0 = 1
sr08_run(g, intercept = FALSE)                              #    no intercept in the d model
sr08_run(g, a0 = "linear")                                  #    a = 0 convention: V(X) = X
sr08_run(g, order = "high_low")                             #    treated matched largest X first
```

`sr08_run()` is serial; the `Rscript` modes run settings in parallel with `sr08_run_par()` on all cores but one and resume from per-setting checkpoints. On 13 worker processes each full-grid variant took 10 to 70 minutes. Seeds are fixed and recorded in each run's `meta.rds`. Per-setting checkpoints (`results/sr08/<variant>/setting_XXXX.rds`) are not tracked; the per-setting result tables (`results/sr08/results_all.rds`, one named data frame per variant, one row per setting) and the Markdown summaries are. To load the results:

```r
res <- readRDS("results/sr08/results_all.rds")   # names(res): results_intercept_TRUE, results_sens_seed_2009, ...
mean(res$results_intercept_TRUE$pct_red)          # corrected method, mean % ISB reduction: 84.3
```

## Files

| Path | Contents |
| --- | --- |
| `R/sr08_appendixB.R` | The rebuild, with switches for each variant and the `full`, `sensitivity` and `variants_2009` run modes |
| `R/run_smoke.R` | Quick check on a 16-setting grid |
| `results/sr08/` | `summary.md`, `sensitivity.md`, `three_way.md`, and `results_all.rds` (per-setting result tables for each variant, as one named list) |
| `docs/` | `replication_verdict.md` (verdict), `three_way.md` (paper vs original program vs rebuild), `sensitivity.md` (sensitivity variants) |

## Lesson

A shorter logical vector used to index a longer one is silently recycled in R. A one-line check such as `stopifnot(length(flag) == length(x))` would have caught this. An independent rebuild with a switch for each suspected difference isolated the cause quickly.

## Conclusions

The local/non-local matching method of Stuart and Rubin (2008) stands. Implemented as Appendix A describes, it removes more bias than the published simulation shows (84.3% vs 80.6% on average), so the published tables understate its advantage. The gap came from two small bookkeeping details in the 2009 program, not from the method. More generally, an independent rebuild from a paper’s text, with a switch for each suspected difference, is an effective way to check a published simulation, and a one-line length check would have caught this issue.

## Acknowledgment

The original 2009 simulation program was provided by Elizabeth A. Stuart. It was shared privately, and its results appear in this repository’s comparisons: the `original_2009` column in `docs/three_way.md` and the “Original 2009 program, run in 2026” row of the Results table come from running it in 2026 with its simulation code unchanged (only the number of replications, the random seed and file paths were set, and the settings were split across processor cores). My 2009 revisions of that program were also run for comparison. Neither her program nor my revisions of it are redistributed here, since they were shared on a do-not-distribute basis. All code in this repository was written independently from the published description in Stuart and Rubin (2008).

## AI assistance

Code, documentation and analyses were developed with Claude (Anthropic) as a coding assistant, under the author's direction. The author designed the study, checked the results and is responsible for the content.

## How to cite

Wang, Q. (2026). *Matching with local and non-local control groups: An R rebuild of Stuart and Rubin’s (2008) simulation* (Version 1.0) [Computer software]. Zenodo. https://doi.org/10.5281/zenodo.24186061

## License

MIT (see `LICENSE`).
