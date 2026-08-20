# Shor Table Optimization

This repository contains the minimal Lean setup for table-generation
submissions.

## Repository Layout

- `TableGeneration/Basic.lean` defines symbolic registers, states, points, and
  primitive operations.
- `TableGeneration/Language.lean` defines programs, execution, row matching,
  ordered point consumption, and pretty printers.
- `TableGeneration/Spec.lean` defines protected product modes, default point
  lists, and validity checks for generated points.
- `TableGeneration/Metrics.lean` defines operation and layer counts.
- `TableGeneration/Baseline.lean` defines the protected general fallback.
- `TableGeneration/Policy.lean` defines the portable policy interface.
- `TableGeneration/BestKnown.lean` selects promoted policies before the general
  fallback.
- `TableGeneration/Submission/Policy.lean` contains the submitted policy.
- `leaderboard/config.json` defines the active targets and score weights.
- `leaderboard/site/index.html` is the static leaderboard website.
- `scripts/verifier.py` is the CI verifier.
- `scripts/leaderboard.py` updates the website benchmark JSON from successful
  verifier artifacts.

## Submission Template

Submissions should replace the `implementation` in:

- `TableGeneration/Submission/Policy.lean`

Related helper files should be placed under:

- `TableGeneration/Submission/Policy/`

Import helpers from `Policy.lean`, for example:

```lean
import TableGeneration.Submission.Policy.Helpers
```

Do not change the protected specification, language, metrics, or workflow files.
The verifier rejects changed protected files, `sorry`, `admit`, new `axiom` or
`constant` declarations, `unsafe`, external implementation hooks, and submitted
Lean compile-time execution commands such as `#eval`.

`Defs.lean` and `Correctness.lean` are fixed adapters and must remain unchanged.

## How Submissions Work

`implementation : GeneratorPolicy` bundles:

- generated points and handled `(mode, k)` cases;
- the point-consumption order and generated program;
- proofs of point validity, safe consumption, and return to the starting state.

A policy may be general or target-specific. CI scores only configured targets
where its `handles` field is true and requires at least one. Unhandled generation
uses the protected best-known policy, whose final fallback is the general
generator.

`generatedPoints` may be any mathematically distinct list with the required
length for the selected product mode and `k`. Each point must be one of:

```text
0, inf, +/- 2^n, or +/- 1/2^n
```

The program may consume the points in another order, but that order must be a
permutation of the generated points.

The program must consume the generated point order, use only safe arithmetic
operations, and return to the starting state.

## Pull Request Setup

The maintained submission base branch is:

```text
submission/template
```

Submission PRs should use:

```text
base:    submission/template
compare: submission/<name>
```

GitHub Actions first runs a Python preflight over the submitted files. If that
passes, it installs Lean using the base template's `lean-toolchain`, runs the
full verifier, posts a compact benchmark summary, and uploads verifier artifacts.
The comment links to the workflow run, readable and JSON results, the website
benchmark data, and an archived source snapshot stored on the
`submission-results` branch. Full workflow artifacts and diagnostic logs are
retained for 90 days. Successful submission PRs are closed automatically only
after the results and source are archived.

When a result becomes a per-target champion, trusted automation constructs the
complete best-known generator, rebuilds Lean, audits the target proofs, reproduces
the metrics, and updates `automation/best-known`. Its workflow summary links to the
[comparison for creating a PR](https://github.com/jpatel2005/ShorTableOptimization/compare/main...automation/best-known?expand=1)
for manual review and merging into `main`; automation never pushes directly to
`main`.

The current promoted metrics are listed in
[`leaderboard/best-known.md`](leaderboard/best-known.md).

## Scoring

Submissions are scored independently on the active targets they handle. There is
no combined score across targets. See [BENCHMARK.md](BENCHMARK.md) for the
current targets, weights, metric definitions, and published result formats. The
current results are available on the
[leaderboard website](https://jpatel2005.github.io/ShorTableOptimization/).

## Local Checks

Build the Lean template:

```bash
lake build TableGeneration
```

Run the submission verifier locally:

```bash
python3 scripts/verifier.py --out-dir artifacts
```

Run only the structural preflight checks:

```bash
python3 scripts/verifier.py --out-dir artifacts --preflight-only
```

The template passes preflight but the full verifier rejects it because it handles
no benchmark targets.
