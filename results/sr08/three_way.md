# SR08 Appendix B: paper vs the original 2009 program vs the rebuild

Written 2026-11-07 07:56. Cells are mean percentage reduction in ISB over the 1,800 settings, 500 replications, 50 imputations. The script that assembled this comparison is not included, because it also runs the original 2009 program.

- **paper**: SR08 Tables B1-B4 (pp. 302-303).
- **original_2009**: the original 2009 simulation program (not included), run in 2026 with its simulation code unchanged: 500 replications and 50 imputations, seed 2009. It uses d0 = 1, a caliper of 0.2 x true sigma_t applied after the greedy loop, and the MI difference in means.
- **sr08_baseline**: R/sr08_appendixB.R, intercept = TRUE, caliper 0.2 x sample SD applied inside the greedy loop, d0 = 0, seed 2008.
- **sr08_caliper_after_loop**: as the baseline, but greedy nearest-unused matching for every treated unit first, then pairs outside the caliper dropped (their controls stay used).
- **sr08_d0_1**: the baseline with d0 = 1 (the original program's value) instead of 0. The intercept in the d model absorbs it, so it should equal the baseline.
- **sr08_caliper_after_recycle**: caliper_after_loop plus the original program's way of updating the matched-control flags (`recycle_flags = TRUE`). Controls of rejected pairs mostly stay in the sample (as controls and in the C1:C2 model) and some controls of good pairs are dropped; treated units of rejected pairs also get C2 matches.

## Overall

| source | mean_pct_red | mean_share_C1 |
| --- | --- | --- |
| paper | 80.6 | NA |
| original_2009 | 80.9 | 0.738 |
| sr08_baseline | 84.3 | 0.819 |
| sr08_caliper_after_loop | 71.7 | 0.740 |
| sr08_d0_1 | 84.3 | 0.819 |
| sr08_caliper_after_recycle | 81.0 | 0.740 |

## Pairwise agreement (71 cells; 6 sources)

| pair | mean_abs_diff | cells_over_5 |
| --- | --- | --- |
| paper vs original_2009 | 0.5 | 0 |
| paper vs sr08_baseline | 4.0 | 16 |
| paper vs sr08_caliper_after_loop | 10.2 | 26 |
| paper vs sr08_d0_1 | 4.0 | 16 |
| paper vs sr08_caliper_after_recycle | 0.5 | 0 |
| original_2009 vs sr08_baseline | 3.9 | 13 |
| original_2009 vs sr08_caliper_after_loop | 10.5 | 28 |
| original_2009 vs sr08_d0_1 | 3.9 | 13 |
| original_2009 vs sr08_caliper_after_recycle | 0.1 | 0 |
| sr08_baseline vs sr08_caliper_after_loop | 12.6 | 37 |
| sr08_baseline vs sr08_d0_1 | 0.0 | 0 |
| sr08_baseline vs sr08_caliper_after_recycle | 3.8 | 14 |
| sr08_caliper_after_loop vs sr08_d0_1 | 12.6 | 37 |
| sr08_caliper_after_loop vs sr08_caliper_after_recycle | 10.5 | 28 |
| sr08_d0_1 vs sr08_caliper_after_recycle | 3.8 | 14 |

## Cells where any two sources differ by more than 5 points (37 of 71)

| cell | paper | original_2009 | sr08_baseline | sr08_caliper_after_loop | sr08_d0_1 | sr08_caliper_after_recycle | range |
| --- | --- | --- | --- | --- | --- | --- | --- |
| d1.B1 d1=0.5 | 92 | 92 | 93 | 88 | 93 | 92 | 5.5 |
| d1.B1 d1=0.75 | 82 | 82 | 85 | 72 | 85 | 82 | 12.4 |
| d1.B1 d1=1 | 67 | 68 | 73 | 51 | 73 | 68 | 22.0 |
| d1.B1 d1=1.25 | 47 | 48 | 57 | 23 | 57 | 48 | 34.4 |
| Nt.B1 Nt=100 | 81 | 81 | 85 | 72 | 85 | 81 | 12.2 |
| Nt.B1 Nt=200 | 81 | 81 | 84 | 71 | 84 | 81 | 13.1 |
| ratio.B1 ratio=2 | 74 | 74 | 80 | 62 | 80 | 74 | 17.3 |
| ratio.B1 ratio=5 | 88 | 88 | 89 | 81 | 89 | 88 | 8.0 |
| B.B1 B=0.5 | 75 | 75 | 78 | 60 | 78 | 75 | 18.2 |
| B.B1 B=0.75 | 81 | 81 | 84 | 71 | 84 | 81 | 13.1 |
| B.B1 B=1 | 83 | 83 | 86 | 75 | 86 | 83 | 11.2 |
| B.B1 B=1.25 | 83 | 83 | 87 | 76 | 87 | 83 | 10.5 |
| B.B1 B=1.5 | 81 | 82 | 86 | 76 | 86 | 82 | 10.2 |
| a.B1 a=-1 | 90 | 91 | 88 | 78 | 88 | 91 | 12.9 |
| a.B1 a=-0.5 | 56 | 56 | 57 | 22 | 57 | 56 | 34.5 |
| a.B1 a=0 | 90 | 90 | 93 | 87 | 93 | 90 | 5.9 |
| a.B1 a=0.5 | 73 | 72 | 85 | 73 | 85 | 73 | 12.9 |
| s2t.B1 s2t=1.5 | 54 | 55 | 58 | 26 | 58 | 54 | 32.8 |
| B2 s2t=1.5 d1=0.5 | 83 | 83 | 82 | 68 | 82 | 83 | 15.4 |
| B2 s2t=1.5 d1=0.75 | 58 | 59 | 59 | 27 | 59 | 58 | 32.2 |
| B2 s2t=1 d1=1 | 84 | 84 | 92 | 84 | 92 | 85 | 8.2 |
| B2 s2t=1.5 d1=1 | 20 | 22 | 27 | -30 | 27 | 22 | 57.3 |
| B2 s2t=1 d1=1.25 | 76 | 76 | 87 | 74 | 87 | 77 | 12.8 |
| B2 s2t=1.5 d1=1.25 | -30 | -27 | -14 | -103 | -14 | -27 | 89.5 |
| B3 s2t=1.5 B=0.5 | 30 | 32 | 37 | -16 | 37 | 31 | 52.4 |
| B3 s2t=1.5 B=0.75 | 52 | 53 | 56 | 20 | 56 | 53 | 35.6 |
| B3 s2t=1.5 B=1 | 61 | 61 | 64 | 36 | 64 | 61 | 28.2 |
| B3 s2t=1 B=1.25 | 89 | 89 | 94 | 88 | 94 | 89 | 6.1 |
| B3 s2t=1.5 B=1.25 | 62 | 63 | 67 | 42 | 67 | 63 | 24.8 |
| B3 s2t=1 B=1.5 | 86 | 86 | 92 | 85 | 92 | 86 | 7.0 |
| B3 s2t=1.5 B=1.5 | 63 | 63 | 68 | 45 | 68 | 63 | 23.0 |
| B4 s2t=1.5 a=-1 | 70 | 75 | 65 | 36 | 65 | 74 | 38.1 |
| B4 s2t=1 a=-0.5 | 86 | 87 | 91 | 81 | 91 | 87 | 9.3 |
| B4 s2t=1.5 a=-0.5 | -17 | -17 | -19 | -113 | -19 | -17 | 96.5 |
| B4 s2t=1.5 a=0 | 76 | 76 | 81 | 67 | 81 | 76 | 14.3 |
| B4 s2t=1 a=0.5 | 78 | 78 | 91 | 82 | 91 | 79 | 12.9 |
| B4 s2t=1.5 a=0.5 | 44 | 44 | 67 | 41 | 67 | 44 | 25.9 |

## All cells

| cell | paper | original_2009 | sr08_baseline | sr08_caliper_after_loop | sr08_d0_1 | sr08_caliper_after_recycle | range |
| --- | --- | --- | --- | --- | --- | --- | --- |
| d1.B1 d1=0 | 98 | 98 | 100 | 100 | 100 | 98 | 2.1 |
| d1.B1 d1=0.25 | 98 | 97 | 98 | 97 | 98 | 98 | 1.4 |
| d1.B1 d1=0.5 | 92 | 92 | 93 | 88 | 93 | 92 | 5.5 |
| d1.B1 d1=0.75 | 82 | 82 | 85 | 72 | 85 | 82 | 12.4 |
| d1.B1 d1=1 | 67 | 68 | 73 | 51 | 73 | 68 | 22.0 |
| d1.B1 d1=1.25 | 47 | 48 | 57 | 23 | 57 | 48 | 34.4 |
| Nt.B1 Nt=100 | 81 | 81 | 85 | 72 | 85 | 81 | 12.2 |
| Nt.B1 Nt=200 | 81 | 81 | 84 | 71 | 84 | 81 | 13.1 |
| ratio.B1 ratio=2 | 74 | 74 | 80 | 62 | 80 | 74 | 17.3 |
| ratio.B1 ratio=5 | 88 | 88 | 89 | 81 | 89 | 88 | 8.0 |
| B.B1 B=0.5 | 75 | 75 | 78 | 60 | 78 | 75 | 18.2 |
| B.B1 B=0.75 | 81 | 81 | 84 | 71 | 84 | 81 | 13.1 |
| B.B1 B=1 | 83 | 83 | 86 | 75 | 86 | 83 | 11.2 |
| B.B1 B=1.25 | 83 | 83 | 87 | 76 | 87 | 83 | 10.5 |
| B.B1 B=1.5 | 81 | 82 | 86 | 76 | 86 | 82 | 10.2 |
| a.B1 a=-1 | 90 | 91 | 88 | 78 | 88 | 91 | 12.9 |
| a.B1 a=-0.5 | 56 | 56 | 57 | 22 | 57 | 56 | 34.5 |
| a.B1 a=0 | 90 | 90 | 93 | 87 | 93 | 90 | 5.9 |
| a.B1 a=0.5 | 73 | 72 | 85 | 73 | 85 | 73 | 12.9 |
| a.B1 a=1 | 96 | 95 | 99 | 98 | 99 | 96 | 3.4 |
| s2t.B1 s2t=0.5 | 98 | 98 | 99 | 99 | 99 | 98 | 1.7 |
| s2t.B1 s2t=1 | 91 | 91 | 95 | 91 | 95 | 91 | 4.7 |
| s2t.B1 s2t=1.5 | 54 | 55 | 58 | 26 | 58 | 54 | 32.8 |
| B2 s2t=0.5 d1=0 | 99 | 99 | 100 | 100 | 100 | 99 | 1.0 |
| B2 s2t=1 d1=0 | 99 | 99 | 100 | 100 | 100 | 99 | 1.0 |
| B2 s2t=1.5 d1=0 | 95 | 95 | 100 | 100 | 100 | 95 | 5.0 |
| B2 s2t=0.5 d1=0.25 | 99 | 99 | 100 | 100 | 100 | 99 | 0.9 |
| B2 s2t=1 d1=0.25 | 98 | 98 | 99 | 99 | 99 | 98 | 1.5 |
| B2 s2t=1.5 d1=0.25 | 95 | 95 | 96 | 92 | 96 | 95 | 3.6 |
| B2 s2t=0.5 d1=0.5 | 99 | 99 | 100 | 100 | 100 | 98 | 1.2 |
| B2 s2t=1 d1=0.5 | 95 | 95 | 98 | 96 | 98 | 96 | 3.0 |
| B2 s2t=1.5 d1=0.5 | 83 | 83 | 82 | 68 | 82 | 83 | 15.4 |
| B2 s2t=0.5 d1=0.75 | 98 | 98 | 99 | 99 | 99 | 98 | 1.8 |
| B2 s2t=1 d1=0.75 | 91 | 91 | 95 | 91 | 95 | 91 | 4.6 |
| B2 s2t=1.5 d1=0.75 | 58 | 59 | 59 | 27 | 59 | 58 | 32.2 |
| B2 s2t=0.5 d1=1 | 96 | 96 | 99 | 98 | 99 | 96 | 2.8 |
| B2 s2t=1 d1=1 | 84 | 84 | 92 | 84 | 92 | 85 | 8.2 |
| B2 s2t=1.5 d1=1 | 20 | 22 | 27 | -30 | 27 | 22 | 57.3 |
| B2 s2t=0.5 d1=1.25 | 95 | 95 | 98 | 97 | 98 | 95 | 3.4 |
| B2 s2t=1 d1=1.25 | 76 | 76 | 87 | 74 | 87 | 77 | 12.8 |
| B2 s2t=1.5 d1=1.25 | -30 | -27 | -14 | -103 | -14 | -27 | 89.5 |
| B3 s2t=0.5 B=0.5 | 99 | 98 | 100 | 100 | 100 | 98 | 1.4 |
| B3 s2t=1 B=0.5 | 94 | 94 | 98 | 96 | 98 | 94 | 4.0 |
| B3 s2t=1.5 B=0.5 | 30 | 32 | 37 | -16 | 37 | 31 | 52.4 |
| B3 s2t=0.5 B=0.75 | 98 | 98 | 100 | 99 | 100 | 98 | 1.7 |
| B3 s2t=1 B=0.75 | 93 | 93 | 97 | 94 | 97 | 93 | 4.0 |
| B3 s2t=1.5 B=0.75 | 52 | 53 | 56 | 20 | 56 | 53 | 35.6 |
| B3 s2t=0.5 B=1 | 98 | 98 | 99 | 99 | 99 | 98 | 1.7 |
| B3 s2t=1 B=1 | 91 | 91 | 95 | 91 | 95 | 91 | 4.8 |
| B3 s2t=1.5 B=1 | 61 | 61 | 64 | 36 | 64 | 61 | 28.2 |
| B3 s2t=0.5 B=1.25 | 98 | 98 | 99 | 99 | 99 | 98 | 1.4 |
| B3 s2t=1 B=1.25 | 89 | 89 | 94 | 88 | 94 | 89 | 6.1 |
| B3 s2t=1.5 B=1.25 | 62 | 63 | 67 | 42 | 67 | 63 | 24.8 |
| B3 s2t=0.5 B=1.5 | 96 | 96 | 99 | 98 | 99 | 96 | 2.7 |
| B3 s2t=1 B=1.5 | 86 | 86 | 92 | 85 | 92 | 86 | 7.0 |
| B3 s2t=1.5 B=1.5 | 63 | 63 | 68 | 45 | 68 | 63 | 23.0 |
| B4 s2t=0.5 a=-1 | 99 | 100 | 100 | 100 | 100 | 100 | 0.9 |
| B4 s2t=1 a=-1 | 99 | 99 | 99 | 98 | 99 | 99 | 1.0 |
| B4 s2t=1.5 a=-1 | 70 | 75 | 65 | 36 | 65 | 74 | 38.1 |
| B4 s2t=0.5 a=-0.5 | 98 | 98 | 99 | 99 | 99 | 98 | 1.4 |
| B4 s2t=1 a=-0.5 | 86 | 87 | 91 | 81 | 91 | 87 | 9.3 |
| B4 s2t=1.5 a=-0.5 | -17 | -17 | -19 | -113 | -19 | -17 | 96.5 |
| B4 s2t=0.5 a=0 | 99 | 99 | 100 | 99 | 100 | 99 | 0.6 |
| B4 s2t=1 a=0 | 94 | 94 | 97 | 94 | 97 | 95 | 3.1 |
| B4 s2t=1.5 a=0 | 76 | 76 | 81 | 67 | 81 | 76 | 14.3 |
| B4 s2t=0.5 a=0.5 | 95 | 95 | 98 | 97 | 98 | 95 | 3.2 |
| B4 s2t=1 a=0.5 | 78 | 78 | 91 | 82 | 91 | 79 | 12.9 |
| B4 s2t=1.5 a=0.5 | 44 | 44 | 67 | 41 | 67 | 44 | 25.9 |
| B4 s2t=0.5 a=1 | 96 | 96 | 100 | 99 | 100 | 96 | 3.8 |
| B4 s2t=1 a=1 | 95 | 95 | 99 | 98 | 99 | 96 | 4.1 |
| B4 s2t=1.5 a=1 | 95 | 95 | 98 | 96 | 98 | 95 | 3.0 |

