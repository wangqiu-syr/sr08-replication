# SR08 Appendix B replication: summary

Written 2026-11-06 04:29 by R/sr08_appendixB.R. Cells are the mean percentage reduction in ISB across settings (remaining ISB in the paper's sense: 100 = all initial bias removed).


## Overall

| config | settings | expected | mean_pct_red | pooled_pct_red | mean_IISB | mean_ISB | mean_share_C1 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| intercept=TRUE | 1800 | 1800 | 84.3 | 96.0 | 2.14 | 0.0857 | 0.819 |
| intercept=FALSE | 1800 | 1800 | 94.1 | 98.5 | 2.14 | 0.0314 | 0.819 |

`mean_share_C1` is the mean share of treated units matched to C1 (the rest get C2 matches).
Percent reduction is unstable when IISB is near 0, so mean IISB and ISB are shown too.

## Table B1 (one-way margins)

Paper values for B1 are not in `sr08_paper`; ours only.

**d1**

| d1 | intercept=TRUE | intercept=FALSE | share_C1 (intercept=TRUE) |
| --- | --- | --- | --- |
| 0 | 100 | 87 | 0.819 |
| 0.25 | 98 | 95 | 0.819 |
| 0.5 | 93 | 98 | 0.819 |
| 0.75 | 85 | 99 | 0.819 |
| 1 | 73 | 96 | 0.819 |
| 1.25 | 57 | 90 | 0.819 |

**Nt**

| Nt | intercept=TRUE | intercept=FALSE | share_C1 (intercept=TRUE) |
| --- | --- | --- | --- |
| 100 | 85 | 94 | 0.814 |
| 200 | 84 | 94 | 0.824 |

**ratio**

| ratio | intercept=TRUE | intercept=FALSE | share_C1 (intercept=TRUE) |
| --- | --- | --- | --- |
| 2 | 80 | 92 | 0.754 |
| 5 | 89 | 96 | 0.883 |

**B**

| B | intercept=TRUE | intercept=FALSE | share_C1 (intercept=TRUE) |
| --- | --- | --- | --- |
| 0.5 | 78 | 90 | 0.925 |
| 0.75 | 84 | 94 | 0.888 |
| 1 | 86 | 95 | 0.833 |
| 1.25 | 87 | 95 | 0.764 |
| 1.5 | 86 | 95 | 0.684 |

**a**

| a | intercept=TRUE | intercept=FALSE | share_C1 (intercept=TRUE) |
| --- | --- | --- | --- |
| -1 | 88 | 94 | 0.819 |
| -0.5 | 57 | 85 | 0.819 |
| 0 | 93 | 97 | 0.819 |
| 0.5 | 85 | 94 | 0.819 |
| 1 | 99 | 99 | 0.819 |

**s2t**

| s2t | intercept=TRUE | intercept=FALSE | share_C1 (intercept=TRUE) |
| --- | --- | --- | --- |
| 0.5 | 99 | 99 | 0.903 |
| 1 | 95 | 98 | 0.855 |
| 1.5 | 58 | 85 | 0.698 |

## Table B2 (s2t by d1)

| s2t | source | d1=0 | d1=0.25 | d1=0.5 | d1=0.75 | d1=1 | d1=1.25 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0.5 | ours intercept=TRUE | 100 | 100 | 100 | 99 | 99 | 98 |
| 0.5 | ours intercept=FALSE | 97 | 98 | 99 | 99 | 100 | 100 |
| 0.5 | paper | 99 | 99 | 99 | 98 | 96 | 95 |
| 1 | ours intercept=TRUE | 100 | 99 | 98 | 95 | 92 | 87 |
| 1 | ours intercept=FALSE | 96 | 98 | 100 | 100 | 99 | 96 |
| 1 | paper | 99 | 98 | 95 | 91 | 84 | 76 |
| 1.5 | ours intercept=TRUE | 100 | 96 | 82 | 59 | 27 | -14 |
| 1.5 | ours intercept=FALSE | 69 | 87 | 97 | 97 | 90 | 73 |
| 1.5 | paper | 95 | 95 | 83 | 58 | 20 | -30 |

## Table B3 (s2t by B)

| s2t | source | B=0.5 | B=0.75 | B=1 | B=1.25 | B=1.5 |
| --- | --- | --- | --- | --- | --- | --- |
| 0.5 | ours intercept=TRUE | 100 | 100 | 99 | 99 | 99 |
| 0.5 | ours intercept=FALSE | 99 | 99 | 99 | 99 | 99 |
| 0.5 | paper | 99 | 98 | 98 | 98 | 96 |
| 1 | ours intercept=TRUE | 98 | 97 | 95 | 94 | 92 |
| 1 | ours intercept=FALSE | 99 | 99 | 98 | 98 | 97 |
| 1 | paper | 94 | 93 | 91 | 89 | 86 |
| 1.5 | ours intercept=TRUE | 37 | 56 | 64 | 67 | 68 |
| 1.5 | ours intercept=FALSE | 74 | 85 | 88 | 90 | 90 |
| 1.5 | paper | 30 | 52 | 61 | 62 | 63 |

## Table B4 (s2t by a)

| s2t | source | a=-1 | a=-0.5 | a=0 | a=0.5 | a=1 |
| --- | --- | --- | --- | --- | --- | --- |
| 0.5 | ours intercept=TRUE | 100 | 99 | 100 | 98 | 100 |
| 0.5 | ours intercept=FALSE | 100 | 99 | 100 | 97 | 99 |
| 0.5 | paper | 99 | 98 | 99 | 95 | 96 |
| 1 | ours intercept=TRUE | 99 | 91 | 97 | 91 | 99 |
| 1 | ours intercept=FALSE | 100 | 96 | 99 | 96 | 100 |
| 1 | paper | 99 | 86 | 94 | 78 | 95 |
| 1.5 | ours intercept=TRUE | 65 | -19 | 81 | 67 | 98 |
| 1.5 | ours intercept=FALSE | 84 | 61 | 94 | 89 | 99 |
| 1.5 | paper | 70 | -17 | 76 | 44 | 95 |

