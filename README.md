# Matching with local and non-local control groups: An R rebuild of Stuart and Rubin’s (2008) simulation

Qiu Wang, Syracuse University · Version 1.1.0 · November 2026 · **[Read the report](report/report.md)** ([PDF](report/report.pdf))

Preprint: Wang, Q. (2026). *Matching with local and non-local control groups: An R rebuild of Stuart and Rubin’s (2008) simulation*. EdArXiv. https://doi.org/10.35542/osf.io/ehmcu

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.24186060.svg)](https://doi.org/10.5281/zenodo.24186060)

This repository is the replication package for the report. The study itself, with the question, the SR08 design, the materials, the results and the discussion, is in [report/report.md](report/report.md). This README says how to reproduce every number in it.

## Key findings

Stuart and Rubin (2008) proposed matching treated units first to a local control group and then, for units with no close local match, to a non-local group, with an adjustment for the difference between the two control groups.

- **Published vs rebuilt.** Their Appendix B simulation reports that the method removes 80.6% of the integrated squared bias (ISB) on average. An independent rebuild of that simulation, written from the paper's text alone, removes **84.3%**.
- **Cause of the gap.** Two bookkeeping details of the original program: where the caliper is applied in the matching loop, and how one line updates the matched-control flags.
- **Gap explained.** With both details added, the rebuild reproduces the original program to within 0.11 percentage points per table cell on average (at most 0.54), and the published tables to within 0.49 points on average, with no cell more than 5 points off.
- **The method stands.** The procedure in the paper's Appendix A is unaffected. Corrected, it removes more bias than published on average, by up to 23 points in one cell, though not in every cell.

## Results

Comparisons cover the 71 cells of Tables B1–B4; the report (Section 4) explains each row.

| Source | Mean % ISB reduction | Share matched in C1 | Mean abs diff from paper | Cells > 5 points off |
| --- | --- | --- | --- | --- |
| Published (p. 296) | 80.6 | — | — | — |
| Original 2009 program, run in 2026 | 80.9 | 0.738 | 0.5 | 0 |
| Rebuild, corrected (caliper inside loop) | 84.3 | 0.819 | 4.0 | 16 |
| Rebuild, caliper after loop only | 71.7 | 0.740 | 10.2 | 26 |
| Rebuild, caliper after loop + flag update | matches the original program (mean 0.11, max 0.54) | — | 0.49 | 0 |

## Repository layout

```
README.md          this file: the replication guide
report/            the study
  report.md          question, the SR08 design, materials, results, discussion, references
  report.pdf         the same report as a PDF, built from report.md by pdf/build.sh
  figures/           Figures 1–3 (PNG, 300 dpi), drawn by R/report_figures.R
  pdf/               build.sh, filter.lua, print.js, style.css (the PDF build), and README.md (how report.pdf was built)
R/
  sr08_appendixB.R   the rebuild, with switches for each variant and the full, sensitivity and variants_2009 run modes
  run_smoke.R        quick check on a 16-setting grid
  report_figures.R   Figures 1–3 of the report, from results_all.rds and docs/three_way.md
results/sr08/      summary.md, sensitivity.md, three_way.md, and results_all.rds
docs/              replication_verdict.md (verdict), three_way.md (paper vs original program vs rebuild),
                   sensitivity.md (sensitivity variants)
CITATION.cff       citation metadata
LICENSE            MIT, for the code
LICENSE-report     CC BY 4.0, for the report text and figures
```

`results_all.rds` holds the per-setting result tables for each variant, as one named list.

## Computational requirements

- **R.** Requires R 4.1 or later (the code uses the native pipe `|>`); the results here were produced with R 4.5.1. Only base R and the bundled `parallel` package are used.
- **Runtime.** On 13 worker processes each full-grid variant took 10 to 70 minutes. The smoke test takes about a minute.
- **Randomness.** Seeds are fixed and recorded in each run's `meta.rds`.
- **Report PDF (optional).** pandoc 3 or later, and Node with Playwright (Chromium).

## Reproduce

From the repository root:

```sh
# 1. Corrected method (reference implementation), with and without an intercept in the d model
Rscript R/sr08_appendixB.R full            # -> results/sr08/intercept_TRUE, intercept_FALSE, summary.md
# 2. Caliper after the loop only, and 4. the sensitivity runs
#    (caliper_true, order_high_low, a0_linear, caliper_after_loop, seed_2009)
Rscript R/sr08_appendixB.R sensitivity     # -> results/sr08/sens_*, sensitivity.md
# 3. Caliper after the loop + flag update (reproduces the published tables), and d0 = 1
Rscript R/sr08_appendixB.R variants_2009   # -> results/sr08/sens_caliper_after_recycle, sens_d0_1
#    and the same variant with seed 2009 (its own seed-to-seed noise)
Rscript R/sr08_appendixB.R noise_2009      # -> results/sr08/sens_caliper_after_recycle_seed_2009
# 5. Figures 1–3 of the report, from the results above (seconds; no simulation)
Rscript R/report_figures.R                 # -> report/figures/*.png
# Quick check on 16 settings, 2 replications (about a minute)
Rscript R/run_smoke.R
```

The same variants from an R session, for any subset of `sr08_grid()`:

```r
source("R/sr08_appendixB.R")
g <- sr08_grid()                                            # 1,800 settings
sr08_run(g, reps = 500, J = 50, seed = 2008, intercept = TRUE)              # 1. corrected method
sr08_run(g, caliper_when = "after")                                         # 2. caliper after the loop
sr08_run(g, caliper_when = "after", recycle_flags = TRUE)                   # 3. + flag update
sr08_run(g, seed = 2009)                                    # 4. seed
sr08_run(g, caliper = "true")                               #    caliper on the true sigma_t
sr08_run(g, d0 = 1)                                         #    delta0 = 1
sr08_run(g, intercept = FALSE)                              #    no intercept in the d model
sr08_run(g, a0 = "linear")                                  #    a = 0 convention: V(X) = X
sr08_run(g, order = "high_low")                             #    treated matched largest X first
```

`sr08_run()` is serial; the `Rscript` modes run settings in parallel with `sr08_run_par()` on all cores but one and resume from per-setting checkpoints. Per-setting checkpoints (`results/sr08/<variant>/setting_XXXX.rds`) are not tracked; the per-setting result tables (`results/sr08/results_all.rds`, one named data frame per variant, one row per setting) and the Markdown summaries are. To load the results:

```r
res <- readRDS("results/sr08/results_all.rds")   # names(res): results_intercept_TRUE, results_sens_seed_2009, ...
mean(res$results_intercept_TRUE$pct_red)          # corrected method, mean % ISB reduction: 84.3
```

The column for the original 2009 program in `docs/three_way.md` comes from a 2026 run of that program, which is not included here, so it cannot be regenerated from this repository.

### Build the report PDF

```sh
bash report/pdf/build.sh
```

pandoc writes a standalone HTML page from `report/report.md`, and Chromium (Playwright) prints it to `report/report.pdf`. Relative links in the PDF point to the files on GitHub at the release tag for the version in `CITATION.cff` (set `REF` to use another ref).

## Acknowledgment

The original 2009 simulation program was provided by Elizabeth A. Stuart. It was shared privately, and its results appear in this repository’s comparisons: the `original_2009` column in `docs/three_way.md` and the “Original 2009 program, run in 2026” row of the Results table come from running it in 2026 with its simulation code unchanged (only the number of replications, the random seed and file paths were set, and the settings were split across processor cores). My 2009 revisions of that program were also run for comparison. Neither her program nor my revisions of it are redistributed here, since they were shared on a do-not-distribute basis. All code in this repository was written independently from the published description in Stuart and Rubin (2008).

## AI assistance

Code, documentation and analyses were developed with Claude (Anthropic) as a coding assistant, under the author's direction. The author designed the study, checked the results and is responsible for the content.

## How to cite

To cite the report, cite the EdArXiv preprint (the `preferred-citation` in [CITATION.cff](CITATION.cff), which GitHub's "Cite this repository" button shows):

> Wang, Q. (2026). *Matching with local and non-local control groups: An R rebuild of Stuart and Rubin’s (2008) simulation*. EdArXiv. https://doi.org/10.35542/osf.io/ehmcu

To cite the code, cite the software release on Zenodo (the top-level metadata in CITATION.cff). The DOI is Zenodo's concept DOI, which always resolves to the latest version.

> Wang, Q. (2026). *Matching with local and non-local control groups: An R rebuild of Stuart and Rubin’s (2008) simulation* (Version 1.1.0) [Computer software and report]. Zenodo. https://doi.org/10.5281/zenodo.24186060

Please also cite Stuart and Rubin (2008):

> Stuart, E. A., & Rubin, D. B. (2008). Matching with multiple control groups with adjustment for group differences. *Journal of Educational and Behavioral Statistics, 33*(3), 279–306. https://doi.org/10.3102/1076998607306078

## License

Code: MIT ([LICENSE](LICENSE)). Report text and figures: CC BY 4.0 ([LICENSE-report](LICENSE-report)).
