#!/usr/bin/env python3
"""Update leaderboard JSON from a successful verifier artifact."""

from __future__ import annotations

import argparse
import datetime as dt
import json
from pathlib import Path
from typing import Any


VALID_TARGET_MODES = {"PhaseProduct", "PhaseTripleProduct"}
REQUIRED_METRICS = {
    "arithmetic_operation_count",
    "parallel_phase_product_layer_count",
    "phase_product_count",
    "total_operation_count",
    "point_count",
}


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z")


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def read_existing(path: Path) -> dict[str, Any] | None:
    if not path.is_file() or path.stat().st_size == 0:
        return None
    return read_json(path)


def validate_target(raw: Any, source: str) -> dict[str, Any]:
    if not isinstance(raw, dict):
        raise ValueError(f"{source} must be an object")
    mode = raw.get("mode")
    k = raw.get("k")
    if mode not in VALID_TARGET_MODES:
        raise ValueError(f"{source}.mode must be PhaseProduct or PhaseTripleProduct")
    if not isinstance(k, int) or k < 2:
        raise ValueError(f"{source}.k must be an integer at least 2")
    return {"mode": mode, "k": k}


def validate_targets(raw: Any, source: str) -> list[dict[str, Any]]:
    if not isinstance(raw, list) or not raw:
        raise ValueError(f"{source} must be a nonempty array")
    targets: list[dict[str, Any]] = []
    seen: set[tuple[str, int]] = set()
    for index, item in enumerate(raw):
        target = validate_target(item, f"{source}[{index}]")
        key = (target["mode"], target["k"])
        if key in seen:
            raise ValueError(f"duplicate target {target['mode']} k={target['k']}")
        seen.add(key)
        targets.append(target)
    return targets


def validate_config(config: dict[str, Any]) -> list[dict[str, Any]]:
    targets = validate_targets(config.get("targets"), "config.targets")
    weights = config.get("weights")
    if not isinstance(weights, dict):
        raise ValueError("config weights must be an object")
    for key in ("arithmetic_operation_count", "parallel_phase_product_layer_count"):
        if not isinstance(weights.get(key), int) or weights[key] < 0:
            raise ValueError(f"config weights.{key} must be a nonnegative integer")
    return targets


def int_metric(metrics: dict[str, Any], key: str) -> int:
    value = metrics.get(key)
    if not isinstance(value, int):
        raise ValueError(f"metric {key} must be an integer")
    return value


def validate_metric_target(metrics: dict[str, Any], expected: dict[str, Any]) -> None:
    if metrics.get("mode") != expected["mode"] or metrics.get("k") != expected["k"]:
        raise ValueError(
            f"metric target {metrics.get('mode')} k={metrics.get('k')} "
            f"does not match expected {expected['mode']} k={expected['k']}"
        )
    missing = sorted(REQUIRED_METRICS - set(metrics))
    if missing:
        raise ValueError("submission result is missing metrics: " + ", ".join(missing))
    for key in REQUIRED_METRICS:
        int_metric(metrics, key)


def validate_result(
    result: dict[str, Any],
    config_targets: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    if result.get("schema_version") != 1:
        raise ValueError("submission result schema_version must be 1")
    if result.get("challenge") != "table-generation":
        raise ValueError("submission result challenge must be table-generation")
    if result.get("status") != "success":
        raise ValueError("submission result status must be success")

    target = result.get("target")
    if not isinstance(target, dict) or not target.get("configured"):
        raise ValueError("submission result must include configured targets")
    result_targets = validate_targets(target.get("targets"), "result.target.targets")
    if result_targets != config_targets:
        raise ValueError("submission result targets do not match leaderboard config")

    metrics = result.get("metrics")
    if not isinstance(metrics, dict):
        raise ValueError("submission result metrics must be an object")
    metric_targets = metrics.get("targets")
    if not isinstance(metric_targets, list) or len(metric_targets) != len(config_targets):
        raise ValueError("submission result metrics.targets must match configured targets")
    for metric, expected in zip(metric_targets, config_targets, strict=True):
        if not isinstance(metric, dict):
            raise ValueError("each target metric must be an object")
        validate_metric_target(metric, expected)
    return metric_targets


def weighted_cost(metrics: dict[str, Any], weights: dict[str, int]) -> int:
    return (
        weights["arithmetic_operation_count"] * metrics["arithmetic_operation_count"]
        + weights["parallel_phase_product_layer_count"]
        * metrics["parallel_phase_product_layer_count"]
    )


def metric_totals(
    metric_targets: list[dict[str, Any]],
    weights: dict[str, int],
) -> dict[str, int]:
    totals = {
        "weighted_cost": 0,
        "arithmetic_operation_count": 0,
        "parallel_phase_product_layer_count": 0,
        "phase_product_count": 0,
        "total_operation_count": 0,
        "point_count": 0,
    }
    for metrics in metric_targets:
        totals["weighted_cost"] += weighted_cost(metrics, weights)
        for key in totals:
            if key != "weighted_cost":
                totals[key] += metrics[key]
    return totals


def build_entry(
    result: dict[str, Any],
    config: dict[str, Any],
    metric_targets: list[dict[str, Any]],
) -> dict[str, Any]:
    metadata = result.get("metadata") or {}
    weights = config["weights"]
    pr_number = str(metadata.get("pr_number") or "").strip()
    run_id = str(metadata.get("run_id") or "").strip()
    submission_id = f"pr-{pr_number}" if pr_number else f"run-{run_id}"
    if submission_id == "run-":
        raise ValueError("submission result metadata must include pr_number or run_id")

    target_entries = []
    for metrics in metric_targets:
        target_entries.append(
            {
                "mode": metrics["mode"],
                "k": metrics["k"],
                "weighted_cost": weighted_cost(metrics, weights),
                "arithmetic_operation_count": metrics["arithmetic_operation_count"],
                "parallel_phase_product_layer_count": metrics[
                    "parallel_phase_product_layer_count"
                ],
                "phase_product_count": metrics["phase_product_count"],
                "total_operation_count": metrics["total_operation_count"],
                "point_count": metrics["point_count"],
                "points": metrics.get("points", ""),
                "program": metrics.get("program", ""),
            }
        )

    return {
        "submission_id": submission_id,
        "repository": metadata.get("repository", ""),
        "pr_number": pr_number,
        "head_ref": metadata.get("head_ref", ""),
        "head_sha": metadata.get("head_sha", ""),
        "run_id": run_id,
        "run_attempt": metadata.get("run_attempt", ""),
        "created_at": metadata.get("created_at", ""),
        "totals": metric_totals(metric_targets, weights),
        "targets": target_entries,
    }


def sort_entries(entries: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return sorted(
        entries,
        key=lambda entry: (
            entry["totals"]["weighted_cost"],
            entry["totals"]["arithmetic_operation_count"],
            entry["totals"]["parallel_phase_product_layer_count"],
            entry.get("created_at") or "",
            entry["submission_id"],
        ),
    )


def update_leaderboard(
    existing: dict[str, Any] | None,
    result: dict[str, Any],
    config: dict[str, Any],
    config_targets: list[dict[str, Any]],
    metric_targets: list[dict[str, Any]],
) -> dict[str, Any]:
    entry = build_entry(result, config, metric_targets)
    entries_by_id: dict[str, dict[str, Any]] = {}
    if existing:
        if existing.get("schema_version") != 1:
            raise ValueError("existing leaderboard schema_version must be 1")
        if existing.get("challenge") != "table-generation":
            raise ValueError("existing leaderboard challenge must be table-generation")
        if existing.get("targets") != config_targets:
            raise ValueError("existing leaderboard targets do not match config")
        for old_entry in existing.get("results", []):
            if isinstance(old_entry, dict) and isinstance(old_entry.get("submission_id"), str):
                entries_by_id[old_entry["submission_id"]] = old_entry

    entries_by_id[entry["submission_id"]] = entry
    return {
        "schema_version": 1,
        "challenge": "table-generation",
        "generated_at": utc_now(),
        "targets": config_targets,
        "scoring": {
            "weights": config["weights"],
            "formula": (
                "weighted_cost = "
                f"{config['weights']['arithmetic_operation_count']} * arithmetic_operation_count + "
                f"{config['weights']['parallel_phase_product_layer_count']} * "
                "parallel_phase_product_layer_count"
            ),
        },
        "results": sort_entries(list(entries_by_id.values())),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--artifact", required=True, help="Verifier JSON artifact.")
    parser.add_argument("--config", default="leaderboard/config.json", help="Leaderboard config.")
    parser.add_argument("--existing", default="", help="Existing leaderboard JSON, if present.")
    parser.add_argument("--out", required=True, help="Output leaderboard JSON.")
    args = parser.parse_args()

    config = read_json(Path(args.config))
    config_targets = validate_config(config)
    result = read_json(Path(args.artifact))
    metric_targets = validate_result(result, config_targets)

    existing = read_existing(Path(args.existing)) if args.existing else None
    leaderboard = update_leaderboard(
        existing,
        result,
        config,
        config_targets,
        metric_targets,
    )
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(leaderboard, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
