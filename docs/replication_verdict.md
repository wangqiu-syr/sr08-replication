# SR08 Appendix B replication: verdict

November 7, 2026. Sources: `docs/three_way.md` (all 71 cells of Tables B1-B4) and
`docs/sensitivity.md`. Every cell is the mean percentage reduction in ISB over the
1,800-setting grid, 500 replications, 50 imputations. "The original 2009 program" is the
simulation program behind the paper's Appendix B. It is not included in this repository.

## Verdict

1. **The tables in Stuart & Rubin (2008) reflect two bookkeeping details of the original
   2009 program, not the method as the paper describes it.** The details are where the
   caliper is applied in the matching loop and how one line updates the matched-control
   flags. Together they have three effects:
   - the C1 controls of rejected pairs mostly stay in the sample, both as matched controls
     and in the C1:C2 model for the C2 adjustment;
   - some C1 controls of good pairs are dropped;
   - the treated units in rejected pairs also get C2 matches, so the control group is no
     longer 1:1 with the treated group.
2. **The rebuild reproduces that behaviour.** `R/sr08_appendixB.R` with
   `caliper_when = "after", recycle_flags = TRUE` matches the original 2009 program (run
   with 500 replications and 50 imputations) as closely as two independent simulations can.
   The option is written from a description of the behaviour.
3. **The rebuild's baseline is the corrected method:**
   - the caliper is applied inside the greedy loop;
   - the matched flags are correct, so a treated unit uses either its C1 match or a C2
     match, never both;
   - the d model includes an intercept.

   Under the corrected method the procedure removes more bias than the paper reports:
   84.3% on average against 80.6%. The paper understates it by up to 23 points
   (Table B4, s2t = 1.5, a = 0.5).

## Evidence

The test was fixed before seeing the result: (b) matches the original 2009 program if the
mean absolute difference over the 71 cells is under 1 point and no cell differs by more
than 5. The two use different random draws (seed 2009 with Mersenne-Twister vs. seed 2008
with L'Ecuyer-CMRG), so each cell was expected to differ by 1-2 points.

| comparison (71 cells) | mean abs diff | max abs diff | cells > 5 |
| --- | --- | --- | --- |
| **(b) caliper_after_recycle vs the original 2009 program** | **0.11** | **0.54** | **0** |
| (b) caliper_after_recycle vs paper | 0.49 | 4.1 | 0 |
| the original 2009 program vs paper | 0.49 | 4.5 | 0 |
| caliper_after_loop (no flag recycling) vs the original 2009 program | 10.5 | — | 28 |
| rebuild baseline vs the original 2009 program | 3.9 | — | 13 |
| Monte Carlo noise: rebuild baseline, seed 2009 vs seed 2008 | 0.2 | 1.55 | 0 |

**Result: match.** The difference from the original 2009 program is smaller than the
rebuild's own seed-to-seed noise. Overall means: paper 80.6, the original 2009 program
80.9, (b) 81.0. The share of treated units matched in C1 is 0.738 for the original 2009
program and 0.740 for (b).

Which differences from the rebuild baseline matter:

| difference from the rebuild baseline | effect on the tables | source |
| --- | --- | --- |
| d0 = 1 instead of 0 | none (max 1.4e-14 points); the d model's intercept absorbs it | variant d0_1 |
| caliper 0.2 x true sigma_t instead of 0.2 x sample SD | none (within noise) | sensitivity.md, caliper_true |
| caliper applied after the greedy loop | fits s2t = 1 but overshoots badly at s2t = 1.5 | caliper_after_loop |
| flag recycling, on top of the after-loop caliper | closes the rest of the gap | caliper_after_recycle |

Neither the after-loop caliper nor the flag recycling reproduces the paper alone. Only the
two together do.

Cells where the two details move the published value most:

| cell | paper | original 2009 program | (b) caliper_after_recycle | rebuild baseline (corrected) |
| --- | --- | --- | --- | --- |
| B4 s2t=1.5 a=0.5 | 44 | 44 | 44 | 67 |
| B2 s2t=1 d1=1.25 | 76 | 76 | 77 | 87 |
| B4 s2t=1 a=0.5 | 78 | 78 | 79 | 91 |
| B1 a=0.5 | 73 | 72 | 73 | 85 |
| B1 d1=1.25 | 47 | 48 | 48 | 57 |
| B2 s2t=1.5 d1=1.25 | -30 | -27 | -27 | -14 |
| B4 s2t=1.5 a=-1 | 70 | 75 | 74 | 65 |

The two details do not always lower the reduction. At s2t = 1.5, a = -1 the corrected
method removes less bias (65 vs. 70-75).

## Implications

- The rebuild baseline is the reference implementation.
- When comparing against SR08's published tables, expect the corrected method to differ
  from them by about 4 points on average (16 of 71 cells by more than 5). This is a
  property of the original simulation program, not an error in the rebuild.
- The method in the paper's Appendix A is unaffected. Only the simulation results in its
  Appendix B are.

## Reproduce

```
Rscript R/sr08_appendixB.R full           # rebuild baseline (intercept_TRUE) and intercept_FALSE
Rscript R/sr08_appendixB.R sensitivity    # caliper_true, order_high_low, a0_linear, caliper_after_loop, seed_2009
Rscript R/sr08_appendixB.R variants_2009  # d0_1, caliper_after_recycle
```

The column for the original 2009 program comes from a 2026 run of that program, which is
not included here, so it cannot be regenerated from this repository.
