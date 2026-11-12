# SR08 Appendix B: sensitivity variants

Written 2026-11-06 12:47 by `Rscript R/sr08_appendixB.R sensitivity`. All variants: intercept = TRUE, reps = 500, J = 50, full 1,800-setting grid. Cells are mean percentage reduction in ISB; gaps are ours minus paper (positive = we remove more bias).

- **baseline**: caliper 0.2 x sample SD of treated X, treated units matched in random (draw) order, a0 = "stuart", seed 2008.
- **caliper_true**: caliper 0.2 x true sigma_t = 0.2 x sqrt(s2t).
- **order_high_low**: treated units sorted by X, largest first, before greedy matching.
- **a0_linear**: V(X) = X when a = 0 (Rubin 1979 limit). Only the 360 a = 0 settings can change; they were rerun and the rest copied from the baseline (checked identical on settings 1 and 1500).
- **caliper_after_loop**: greedy nearest unused control for every treated unit first, then pairs outside the caliper dropped (their controls stay used), as in the original 2009 program (not included). Caliper still 0.2 x sample SD, so this isolates when the caliper is applied.
- **seed_2009**: baseline with seed 2009 (new X draws and imputation streams). Its distance from the baseline measures Monte Carlo noise.


## Summary

| variant | mean_pct_red | share_C1 | mean_ISB | MAD vs paper, all 71 cells | s2t=1 cells (16): mean gap | s2t=1 cells: MAD | B4 s2t=1.5 a=0.5 (paper 44) | s2t=1: mean abs change vs baseline |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| baseline | 84.3 | 0.819 | 0.0857 | 4.0 | 4.8 | 4.8 | 66.9 | 0.0 |
| caliper_true | 84.3 | 0.819 | 0.0858 | 4.0 | 4.8 | 4.8 | 66.9 | 0.0 |
| order_high_low | 87.6 | 0.846 | 0.0677 | 7.0 | 6.2 | 6.2 | 75.8 | 1.4 |
| a0_linear | 84.4 | 0.819 | 0.0852 | 4.0 | 4.8 | 4.8 | 66.9 | 0.0 |
| caliper_after_loop | 71.7 | 0.740 | 0.1540 | 10.2 | 0.1 | 1.4 | 41.0 | 4.7 |
| seed_2009 | 84.1 | 0.817 | 0.0872 | 3.8 | 4.7 | 4.7 | 66.7 | 0.1 |

Monte Carlo noise (|seed_2009 - baseline|): mean 0.2, max 1.5 points over all 71 cells; mean 0.1 over the s2t = 1 cells; 0.2 at B4 s2t=1.5 a=0.5.
A variant's change matters only if it is clearly larger than this noise.

## Which variant closes the gaps best

- **s2t = 1 rows of B2-B4 (mean absolute gap, 16 cells):** `caliper_after_loop` closes it best: 4.8 -> 1.4 points from the paper (baseline 4.8; noise 0.1).
- **B4 at s2t = 1.5, a = 0.5 (absolute gap; paper 44):** `caliper_after_loop` closes it best: 22.9 -> 3.0 points from the paper (baseline 22.9; noise 0.2).

## Table B2

**s2t = 1**

| source | d1=0 | d1=0.25 | d1=0.5 | d1=0.75 | d1=1 | d1=1.25 |
| --- | --- | --- | --- | --- | --- | --- |
| baseline | 100 | 99 | 98 | 95 | 92 | 87 |
| caliper_true | 100 | 99 | 98 | 95 | 92 | 87 |
| order_high_low | 100 | 100 | 99 | 97 | 94 | 91 |
| a0_linear | 100 | 100 | 98 | 95 | 92 | 87 |
| caliper_after_loop | 100 | 99 | 96 | 91 | 84 | 74 |
| seed_2009 | 100 | 99 | 98 | 95 | 92 | 87 |
| paper | 99 | 98 | 95 | 91 | 84 | 76 |

**s2t = 1.5**

| source | d1=0 | d1=0.25 | d1=0.5 | d1=0.75 | d1=1 | d1=1.25 |
| --- | --- | --- | --- | --- | --- | --- |
| baseline | 100 | 96 | 82 | 59 | 27 | -14 |
| caliper_true | 100 | 96 | 82 | 59 | 27 | -14 |
| order_high_low | 100 | 96 | 85 | 67 | 42 | 10 |
| a0_linear | 100 | 96 | 82 | 59 | 27 | -14 |
| caliper_after_loop | 100 | 92 | 68 | 27 | -30 | -103 |
| seed_2009 | 100 | 95 | 82 | 59 | 26 | -15 |
| paper | 95 | 95 | 83 | 58 | 20 | -30 |

## Table B3

**s2t = 1**

| source | B=0.5 | B=0.75 | B=1 | B=1.25 | B=1.5 |
| --- | --- | --- | --- | --- | --- |
| baseline | 98 | 97 | 95 | 94 | 92 |
| caliper_true | 98 | 97 | 95 | 94 | 92 |
| order_high_low | 99 | 98 | 97 | 96 | 94 |
| a0_linear | 98 | 97 | 95 | 94 | 92 |
| caliper_after_loop | 96 | 94 | 91 | 88 | 85 |
| seed_2009 | 98 | 97 | 95 | 94 | 92 |
| paper | 94 | 93 | 91 | 89 | 86 |

**s2t = 1.5**

| source | B=0.5 | B=0.75 | B=1 | B=1.25 | B=1.5 |
| --- | --- | --- | --- | --- | --- |
| baseline | 37 | 56 | 64 | 67 | 68 |
| caliper_true | 37 | 56 | 64 | 67 | 68 |
| order_high_low | 53 | 65 | 70 | 72 | 72 |
| a0_linear | 37 | 56 | 64 | 67 | 69 |
| caliper_after_loop | -16 | 20 | 36 | 42 | 45 |
| seed_2009 | 36 | 55 | 64 | 67 | 68 |
| paper | 30 | 52 | 61 | 62 | 63 |

## Table B4

**s2t = 1**

| source | a=-1 | a=-0.5 | a=0 | a=0.5 | a=1 |
| --- | --- | --- | --- | --- | --- |
| baseline | 99 | 91 | 97 | 91 | 99 |
| caliper_true | 99 | 90 | 97 | 91 | 99 |
| order_high_low | 99 | 92 | 98 | 95 | 100 |
| a0_linear | 99 | 91 | 97 | 91 | 99 |
| caliper_after_loop | 98 | 81 | 94 | 82 | 98 |
| seed_2009 | 99 | 90 | 97 | 91 | 99 |
| paper | 99 | 86 | 94 | 78 | 95 |

**s2t = 1.5**

| source | a=-1 | a=-0.5 | a=0 | a=0.5 | a=1 |
| --- | --- | --- | --- | --- | --- |
| baseline | 65 | -19 | 81 | 67 | 98 |
| caliper_true | 65 | -20 | 81 | 67 | 98 |
| order_high_low | 70 | 3 | 85 | 76 | 99 |
| a0_linear | 65 | -19 | 82 | 67 | 98 |
| caliper_after_loop | 36 | -113 | 67 | 41 | 96 |
| seed_2009 | 64 | -21 | 81 | 67 | 98 |
| paper | 70 | -17 | 76 | 44 | 95 |

