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
- `TableGeneration/Baseline.lean` defines the protected fallback generator.
- `TableGeneration/Submission/Defs.lean` is where submissions define points and
  programs.
- `TableGeneration/Submission/Correctness.lean` is where submissions prove the
  required theorems.
- `leaderboard/config.json` defines the active targets and score weights.
- `scripts/verifier.py` is the CI verifier.
- `scripts/leaderboard.py` updates the website benchmark JSON from successful
  verifier artifacts.

## Submission Template

Submissions should edit:

- `TableGeneration/Submission/Defs.lean`
- `TableGeneration/Submission/Correctness.lean`

Additional helper Lean files may also be placed under:

- `TableGeneration/Submission/`

Helper files outside `TableGeneration/Submission/` are rejected. Import helper
files from the two editable files using the corresponding Lean module path, for
example:

```lean
import TableGeneration.Submission.Helpers
```

Do not change the protected specification, language, metrics, or workflow files.
The verifier rejects changed protected files, `sorry`, `admit`, new `axiom` or
`constant` declarations, `unsafe`, and submitted Lean compile-time execution
commands such as `#eval`.

The two required theorem statements in `Correctness.lean` must remain unchanged:

- `generatedPoints_valid`
- `generate_ProgConsumesPtsSafe`

## How Submissions Work

In `TableGeneration/Submission/Defs.lean`, fill in the definitions that describe
the submitted generator. The intended edit surface is:

- `generatedPoints` returns the table points for a product mode and `k`.
- `submissionHandles` returns `true` for the `(mode, k)` cases implemented by
  the submission.
- `submissionGeneratePointsInOrder` returns the order in which the program will
  consume the generated points.
- `submissionGenerate` returns the generated program.

Do not edit the wrapper definitions `generatePointsInOrder` and `generate`.
They are verifier entry points and must match the template.

In `TableGeneration/Submission/Correctness.lean`, prove the required theorem
statements without changing their types. The theorem hypotheses include
`submissionHandles mode k = true`, so a submission can either implement a
general policy for many `k` values and product modes, or specialize to selected
cases by branching on `mode` and `k` in `submissionHandles`.

For example, a specialized submission can mark only one case as handled and let
all other cases use the protected fallback generator. CI only scores configured
targets that the submission handles. A submission must handle at least one
configured target; unhandled targets are skipped.

`generatedPoints` may be any mathematically distinct list with the required
length for the selected product mode and `k`. Each point must be one of:

```text
0, inf, +/- 2^n, or +/- 1/2^n
```

The template defaults to `canonicalPoints`, but that list is only a starting
point and fallback; submissions may replace it with another valid generated
point list.

The submitted program may consume the generated points in another order, but
`generatePointsInOrder` must be a permutation of `generatedPoints`.

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

## Scoring

Submissions are scored independently on the active targets they handle. There is
no combined score across targets. See [BENCHMARK.md](BENCHMARK.md) for the
current targets, weights, metric definitions, and published result formats.

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

The template intentionally contains `sorry`, so the verifier should fail until a
submission fills in the proofs.
