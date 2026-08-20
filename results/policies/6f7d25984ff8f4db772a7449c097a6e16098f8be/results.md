<!-- table-generation-submission-result -->
### Table generation benchmark

Status: **SUCCESS**

Submission: PR #5 · commit `6f7d25984ff8`

Scoring: `weighted_cost = 1 * arithmetic_operation_count + 5 * parallel_phase_product_layer_count`.

Coverage: **30 of 30** targets.

| Target | Weighted cost | Arithmetic ops | Parallel layers | Phase products | Total ops | Generated points |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `PhaseProduct` `k=2` | **12** | 2 | 2 | 3 | 5 | 3 |
| `PhaseTripleProduct` `k=2` | **18** | 8 | 2 | 4 | 12 | 4 |
| `PhaseProduct` `k=3` | **22** | 12 | 2 | 5 | 17 | 5 |
| `PhaseTripleProduct` `k=3` | **31** | 16 | 3 | 7 | 23 | 7 |
| `PhaseProduct` `k=4` | **43** | 28 | 3 | 7 | 35 | 7 |
| `PhaseTripleProduct` `k=4` | **66** | 46 | 4 | 10 | 56 | 10 |
| `PhaseProduct` `k=5` | **68** | 48 | 4 | 9 | 57 | 9 |
| `PhaseTripleProduct` `k=5` | **106** | 76 | 6 | 13 | 89 | 13 |
| `PhaseProduct` `k=6` | **97** | 72 | 5 | 11 | 83 | 11 |
| `PhaseTripleProduct` `k=6` | **145** | 110 | 7 | 16 | 126 | 16 |
| `PhaseProduct` `k=7` | **130** | 100 | 6 | 13 | 113 | 13 |
| `PhaseTripleProduct` `k=7` | **199** | 154 | 9 | 19 | 173 | 19 |
| `PhaseProduct` `k=8` | **167** | 132 | 7 | 15 | 147 | 15 |
| `PhaseTripleProduct` `k=8` | **248** | 198 | 10 | 22 | 220 | 22 |
| `PhaseProduct` `k=9` | **208** | 168 | 8 | 17 | 185 | 17 |
| `PhaseTripleProduct` `k=9` | **316** | 256 | 12 | 25 | 281 | 25 |
| `PhaseProduct` `k=10` | **253** | 208 | 9 | 19 | 227 | 19 |
| `PhaseTripleProduct` `k=10` | **375** | 310 | 13 | 28 | 338 | 28 |
| `PhaseProduct` `k=11` | **302** | 252 | 10 | 21 | 273 | 21 |
| `PhaseTripleProduct` `k=11` | **457** | 382 | 15 | 31 | 413 | 31 |
| `PhaseProduct` `k=12` | **355** | 300 | 11 | 23 | 323 | 23 |
| `PhaseTripleProduct` `k=12` | **526** | 446 | 16 | 34 | 480 | 34 |
| `PhaseProduct` `k=13` | **412** | 352 | 12 | 25 | 377 | 25 |
| `PhaseTripleProduct` `k=13` | **622** | 532 | 18 | 37 | 569 | 37 |
| `PhaseProduct` `k=14` | **473** | 408 | 13 | 27 | 435 | 27 |
| `PhaseTripleProduct` `k=14` | **701** | 606 | 19 | 40 | 646 | 40 |
| `PhaseProduct` `k=15` | **538** | 468 | 14 | 29 | 497 | 29 |
| `PhaseTripleProduct` `k=15` | **811** | 706 | 21 | 43 | 749 | 43 |
| `PhaseProduct` `k=16` | **607** | 532 | 15 | 31 | 563 | 31 |
| `PhaseTripleProduct` `k=16` | **900** | 790 | 22 | 46 | 836 | 46 |

All correctness and safety checks passed.
