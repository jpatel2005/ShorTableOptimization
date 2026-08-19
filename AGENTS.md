# Agent Guidelines

This repository contains a minimal Lean verifier for table-generation
submissions.

## Code Boundaries

- Protected verifier code lives in `TableGeneration/Basic.lean`,
  `TableGeneration/Language.lean`, `TableGeneration/Spec.lean`,
  `TableGeneration/Metrics.lean`, and `TableGeneration/Baseline.lean`.
- Submission-facing code lives in `TableGeneration/Submission/`.
- Submitters are expected to edit `TableGeneration/Submission/Defs.lean` and
  `TableGeneration/Submission/Correctness.lean`.
- Optional submission helper files may live under
  `TableGeneration/Submission/`; helper files outside that directory are
  rejected and should be imported as `TableGeneration.Submission.<Name>` or a
  nested module path.

## Verifier Contract

- Preserve the theorem statements checked by `scripts/verifier.py`.
- Submissions define their generator in
  `TableGeneration/Submission/Defs.lean` and prove the required theorem
  statements in `TableGeneration/Submission/Correctness.lean`.
- `submissionHandles mode k = true` identifies the implemented cases; submitted
  definitions may be general across modes and `k`, or specialized to selected
  targets with fallback elsewhere.
- `generatePointsInOrder` and `generate` are verifier entry points and must
  remain identical to the template.
- The verifier should reject `sorry`, `admit`, new `axiom` or `constant`
  declarations, `unsafe`, and compile-time execution commands in submission
  files.
- The verifier should use the base branch's `scripts/verifier.py` in CI.
- CI should run verifier preflight before installing Lean or building submitted
  Lean code.
- Leaderboard scoring should use `leaderboard/config.json`.
- Keep the concise benchmark contract in `BENCHMARK.md` synchronized with the
  configured targets, weights, and published result formats.
- A submission must handle at least one configured target; unhandled targets are
  skipped and do not receive scores.
- Successful results and submission source snapshots should be retained on the
  `submission-results` branch.
- Unhandled submission cases should fall back to the protected baseline
  generator.

## Checks

- Run `lake build TableGeneration` after Lean changes.
- CI runs `scripts/verifier.py` automatically for submission PRs.
- For local verification while changing the verifier or template, run
  `python3 scripts/verifier.py --out-dir artifacts`.
- For local preflight only, run
  `python3 scripts/verifier.py --out-dir artifacts --preflight-only`.
