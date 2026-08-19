# Table Generation Benchmark

The benchmark is provisional. Its targets and weights can be changed in
`leaderboard/config.json` as the challenge evolves.

## Current Configuration

The current benchmark evaluates both `PhaseProduct` and `PhaseTripleProduct` for
every `k` from 2 through 16, giving 30 independent targets. A submission may
handle any nonempty subset of those targets.

Each handled target receives its own weighted cost:

```text
weighted_cost = arithmetic_operation_count + 5 * parallel_phase_product_layer_count
```

There is no combined score: coverage and the vector of per-target costs describe
a policy. The benchmark records the champion or tied champions for each
`(mode, k)` target, so different policies may be optimal in different cells.

The report also includes the unweighted measurements used to understand a
submission:

| Metric | Meaning |
| --- | --- |
| Arithmetic operations | Program operations other than phase products. |
| Parallel phase-product layers | Consecutive phase-product runs separated by arithmetic operations. |
| Phase products | Phase-product operations in the program. |
| Total operations | All operations in the program. |
| Generated points | Points produced for the target. |

## Published Results

For each successful submission, CI publishes:

- `results.json`: a compact record of the submission identity, benchmark weights,
  coverage, raw measurements, and per-target weighted costs.
- `results.md`: a short report containing the formula and a readable results
  table.
- `source.zip`: the submitted Lean source, retained so the policy can be
  inspected or reprocessed later.
- `leaderboard/results.json`: the website-oriented policy registry and current
  per-target champions.

The files are stored on the `submission-results` branch and linked from the PR
comment. Every successful policy is retained for now, not only per-target
champions. Full verifier output and diagnostic logs remain available as workflow
artifacts for 90 days.

Champion policies are composed with the general fallback and promoted through a
verified PR to `main`. Promotion repeats correctness checks and requires the
published metrics to match.
