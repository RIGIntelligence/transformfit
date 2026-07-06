#!/usr/bin/env python3
"""Fail-closed gate for TransformFit's activation nutrition target slice."""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Iterable


REQUIRED_SOURCE_IDS = {
    "src_odphp_dietary_guidelines_2025_2030",
    "src_odphp_physical_activity_guidelines",
    "src_nutrition_target_safety_protocol",
}

REQUIRED_MODEL_TOKENS = {
    "class NutritionTarget",
    "defaultSafetyNote",
    "defaultSourceIds",
    "src_odphp_dietary_guidelines_2025_2030",
    "src_odphp_physical_activity_guidelines",
    "src_nutrition_target_safety_protocol",
    "_validNutritionTargetSnapshot",
    "not medical nutrition advice",
    "'g/day'",
    "'ml/day'",
    "'meals/day'",
    "'times/day'",
}

REQUIRED_STATE_TOKENS = {
    "final NutritionTarget? nutritionTarget",
    "'nutritionTarget': nutritionTarget?.toJson()",
    "rawNutritionTarget",
    "NutritionTarget.fromJson",
    "setNutritionTarget",
    "clearNutritionTarget",
    "nutritionTarget: _state.nutritionTarget",
}

REQUIRED_UI_TOKENS = {
    "class _NutritionTargetPanel",
    "Create nutrition target",
    "Protein target",
    "Daily protein",
    "This is not medical nutrition advice",
    "Nutrition target source trace",
    "label: 'Nutrition target'",
    "state.nutritionTarget?.targetDisplay",
}

REQUIRED_TEST_TOKENS = {
    "setNutritionTarget creates a safe source-traced target",
    "setNutritionTarget rejects unsafe or out-of-range targets",
    "nutrition target survives JSON restore and resetDay",
    "Today screen creates a safe nutrition target for activation",
    "Create nutrition target",
    "120 g/day",
    "not medical nutrition advice",
}

REQUIRED_SHIP_TOKENS = {
    "NUTRITION_TARGET_GATE",
    "nutrition_target_gate",
    "Tier-1 10/27: nutrition_target_gate",
}

APP_BANNED_TERMS = {
    "burn fat",
    "cheat meal",
    "clean eating",
    "detox",
    "shred",
    "summer body",
    "weight loss",
}


def _read(path: pathlib.Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return ""


def _missing(text: str, tokens: Iterable[str]) -> list[str]:
    return [token for token in tokens if token not in text]


def _load_json(path: pathlib.Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return {}


def run(repo_root: pathlib.Path) -> dict[str, object]:
    failures: list[str] = []
    paths = {
        "models": repo_root / "lib/features/session/models.dart",
        "controller": repo_root / "lib/features/session/session_controller.dart",
        "today": repo_root / "lib/screens/today_screen.dart",
        "session_tests": repo_root / "test/features/session/session_controller_test.dart",
        "today_tests": repo_root / "test/today_screen_test.dart",
        "sources": repo_root / "transformfit-harness/nutrition_target_sources.json",
        "ship_gate": repo_root / "transformfit-harness/ship_gate.sh",
        "bridge": repo_root / "transformfit-harness/bridge.json",
        "war_room": repo_root / "transformfit-harness/two_day_war_room.json",
        "war_room_gate": repo_root / "transformfit-harness/two_day_war_room_gate.py",
    }
    text = {name: _read(path) for name, path in paths.items()}

    for name, body in text.items():
        if not body:
            failures.append(f"missing required file: {paths[name]}")

    for token in _missing(text["models"], REQUIRED_MODEL_TOKENS):
        failures.append(f"models.dart missing nutrition token: {token}")
    for token in _missing(text["controller"], REQUIRED_STATE_TOKENS):
        failures.append(f"session_controller.dart missing nutrition token: {token}")
    for token in _missing(text["today"], REQUIRED_UI_TOKENS):
        failures.append(f"today_screen.dart missing nutrition UI token: {token}")

    combined_tests = text["session_tests"] + "\n" + text["today_tests"]
    for token in _missing(combined_tests, REQUIRED_TEST_TOKENS):
        failures.append(f"nutrition tests missing token: {token}")

    for token in _missing(text["ship_gate"], REQUIRED_SHIP_TOKENS):
        failures.append(f"ship_gate.sh missing nutrition gate token: {token}")
    if "nutrition_target_gate" not in text["bridge"]:
        failures.append("bridge.json missing nutrition_target_gate routing")
    if "one nutrition target within 24 hours" not in text["war_room"]:
        failures.append("two_day_war_room.json missing activation nutrition KPI")
    if '"nutrition_target_gate"' not in text["war_room_gate"]:
        failures.append("two_day_war_room_gate.py missing nutrition target gate")

    source_data = _load_json(paths["sources"])
    if source_data.get("schema") != "transformfit.nutrition_target_sources.v1":
        failures.append("nutrition_target_sources.json has wrong schema")
    source_ids = {
        item.get("id")
        for item in source_data.get("sources", [])
        if isinstance(item, dict)
    }
    missing_source_ids = REQUIRED_SOURCE_IDS - source_ids
    if missing_source_ids:
        failures.append(f"nutrition source sidecar missing IDs: {sorted(missing_source_ids)}")
    for item in source_data.get("sources", []):
        if not isinstance(item, dict):
            failures.append("nutrition source entry must be an object")
            continue
        source_id = item.get("id", "<unknown>")
        url = str(item.get("source_url", ""))
        if source_id != "src_nutrition_target_safety_protocol" and "odphp.health.gov" not in url:
            failures.append(f"nutrition source {source_id} must cite odphp.health.gov")
        if not item.get("retrieved_at"):
            failures.append(f"nutrition source {source_id} missing retrieved_at")
        if not item.get("product_use"):
            failures.append(f"nutrition source {source_id} missing product_use")
    safety_rules = json.dumps(source_data.get("safety_rules", [])).lower()
    if "not medical nutrition advice" not in safety_rules:
        failures.append("nutrition safety rules must require non-medical framing")

    app_text = text["today"].lower()
    for banned in sorted(APP_BANNED_TERMS):
        if banned in app_text:
            failures.append(f"app nutrition surface contains banned term: {banned}")

    return {
        "schema": "transformfit.nutrition_target_gate.v1",
        "repo_root": str(repo_root),
        "verdict": "GREEN" if not failures else "RED",
        "failures": failures,
        "required_source_ids": sorted(REQUIRED_SOURCE_IDS),
    }


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=pathlib.Path,
        default=pathlib.Path("."),
        help="TransformFit Flutter repo root",
    )
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)

    result = run(args.repo_root.resolve())
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(f"{result['verdict']} nutrition_target_gate: {result['repo_root']}")
        for failure in result["failures"]:
            print(f"  - {failure}")
    return 0 if result["verdict"] == "GREEN" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
