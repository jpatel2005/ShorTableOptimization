#!/usr/bin/env python3
"""Export validated benchmark settings as GitHub Actions outputs."""

from __future__ import annotations

import json
from pathlib import Path

from scripts.leaderboard import validate_config


def main() -> int:
    config = json.loads(Path("leaderboard/config.json").read_text(encoding="utf-8"))
    targets = validate_config(config)

    print(f"targets={json.dumps(targets, separators=(',', ':'))}")
    print(f"weights={json.dumps(config['weights'], separators=(',', ':'))}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
