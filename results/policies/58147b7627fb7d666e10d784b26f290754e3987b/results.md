<!-- table-generation-submission-result -->
### Table generation benchmark

Status: **SUCCESS**

Submission: PR #15 · commit `58147b7627fb`

Scoring: `weighted_cost = 1 * arithmetic_operation_count + 5 * parallel_phase_product_layer_count`.

Coverage: **2 of 30** targets.

| Target | Weighted cost | Arithmetic ops | Parallel layers | Phase products | Total ops | Generated points |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `PhaseProduct` `k=6` | **89** | 64 | 5 | 11 | 75 | 11 |
| `PhaseTripleProduct` `k=6` | **128** | 93 | 7 | 16 | 109 | 16 |

All correctness and safety checks passed.
