#!/usr/bin/env python3
"""Publish a verified best-known generator update as a pull request."""

from __future__ import annotations

import json
from pathlib import Path
import subprocess


BRANCH = "automation/promote-table-generation"
ALLOWED_PREFIXES = (
    "TableGeneration/BestKnown.lean",
    "TableGeneration/Policies/Accepted/",
)


def run(args: list[str], *, capture: bool = False, check: bool = True) -> str:
    completed = subprocess.run(
        args,
        check=False,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.STDOUT if capture else None,
    )
    if check and completed.returncode != 0:
        raise RuntimeError(completed.stdout or f"command failed: {' '.join(args)}")
    # Preserve the leading columns in machine-readable `git status --short`
    # output; callers that parse JSON tolerate trailing whitespace.
    return (completed.stdout or "").rstrip("\n")


def changed_paths() -> list[str]:
    output = run(
        ["git", "status", "--short", "--untracked-files=all"],
        capture=True,
    )
    paths = []
    for line in output.splitlines():
        path = line[3:].strip()
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        paths.append(path)
    return paths


def allowed(path: str) -> bool:
    return path == ALLOWED_PREFIXES[0] or path.startswith(ALLOWED_PREFIXES[1])


def existing_pr() -> int | None:
    output = run(
        [
            "gh",
            "pr",
            "list",
            "--state",
            "open",
            "--head",
            BRANCH,
            "--json",
            "number",
        ],
        capture=True,
    )
    values = json.loads(output)
    return values[0]["number"] if values else None


def main() -> int:
    paths = changed_paths()
    if not paths:
        print("Best-known generator is already current.")
        return 0
    disallowed = sorted(path for path in paths if not allowed(path))
    if disallowed:
        raise RuntimeError("promotion modified unexpected paths: " + ", ".join(disallowed))

    run(["git", "config", "user.name", "github-actions[bot]"])
    run(
        [
            "git",
            "config",
            "user.email",
            "41898282+github-actions[bot]@users.noreply.github.com",
        ]
    )
    run(["git", "checkout", "-B", BRANCH])
    run(["git", "add", "--", *paths])
    run(["git", "commit", "-m", "feat: promote best-known table policies"])
    run(
        [
            "git",
            "fetch",
            "origin",
            f"refs/heads/{BRANCH}:refs/remotes/origin/{BRANCH}",
        ],
        check=False,
    )
    run(["git", "push", "--force-with-lease", "origin", f"HEAD:{BRANCH}"])

    body = "\n".join(
        [
            "Constructs the best-known generator from published per-target champions.",
            "",
            "The promotion workflow rebuilt Lean, checked axioms and restricted declarations,",
            "and reproduced every promised benchmark metric.",
        ]
    )
    number = existing_pr()
    if number is None:
        run(
            [
                "gh",
                "pr",
                "create",
                "--base",
                "main",
                "--head",
                BRANCH,
                "--title",
                "feat: promote best-known table policies",
                "--body",
                body,
            ]
        )
    else:
        run(["gh", "pr", "edit", str(number), "--body", body])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
