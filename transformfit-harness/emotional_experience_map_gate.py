#!/usr/bin/env python3
"""Fail-closed gate for TransformFit's emotional experience map."""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Iterable


REQUIRED_MODEL_TOKENS = {
    "emotionalExperienceSourceIds",
    "enum EmotionalExperienceStage",
    "class EmotionalExperienceVector",
    "class EmotionalExperienceMap",
    "buildEmotionalExperienceMap",
    "emotionalExperienceCopyIsGateSafe",
    "Orientation",
    "Agency",
    "Safety",
    "Comeback",
    "Momentum",
    "Proof identity",
    "The first win is clarity, not intensity",
    "A gap becomes a restart path, not a verdict",
}

REQUIRED_PROVIDER_TOKENS = {
    "emotionalExperienceMapProvider",
    "buildEmotionalExperienceMap",
}

REQUIRED_PROGRESS_TOKENS = {
    "EmotionalExperienceMap",
    "_EmotionalExperiencePanel",
    "_EmotionVectorCard",
    "Emotional map",
    "Promise",
    "Next experience",
    "Avoid",
}

REQUIRED_COACH_TOKENS = {
    "EmotionalExperienceMap",
    "_EmotionalMapPanel",
    "_EmotionVectorCard",
    "Emotional map",
    "Promise",
    "Avoid",
}

REQUIRED_TEST_TOKENS = {
    "empty state routes to orientation",
    "active session routes to agency",
    "pain debrief routes to safety",
    "missed day routes to comeback",
    "three completed sessions route to proof identity",
    "Feel safe to begin",
    "Feel the loop working",
    "Orientation",
}

REQUIRED_SHIP_TOKENS = {
    "EMOTIONAL_EXPERIENCE_MAP_GATE",
    "emotional_experience_map_gate",
    "Tier-1 16/27: emotional_experience_map_gate",
}

APP_BANNED_TERMS = {
    "beast mode",
    "burn fat",
    "diagnose",
    "guilt",
    "lazy",
    "no excuses",
    "punish",
    "shame",
    "skinny",
    "weight loss",
}


def _read(path: pathlib.Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return ""


def _missing(text: str, tokens: Iterable[str]) -> list[str]:
    return [token for token in tokens if token not in text]


def run(repo_root: pathlib.Path) -> dict[str, object]:
    failures: list[str] = []
    paths = {
        "model": repo_root / "lib/features/emotion/emotional_experience_map.dart",
        "providers": repo_root / "lib/app_providers.dart",
        "progress_screen": repo_root / "lib/features/progress/progress_screen.dart",
        "coach_screen": repo_root / "lib/features/coaching/coach_command_screen.dart",
        "model_tests": repo_root / "test/features/emotion/emotional_experience_map_test.dart",
        "progress_tests": repo_root / "test/features/progress/progress_screen_test.dart",
        "coach_tests": repo_root / "test/features/coaching/coach_command_screen_test.dart",
        "ship_gate": repo_root / "transformfit-harness/ship_gate.sh",
        "bridge": repo_root / "transformfit-harness/bridge.json",
        "war_room": repo_root / "transformfit-harness/two_day_war_room.json",
        "war_room_gate": repo_root / "transformfit-harness/two_day_war_room_gate.py",
    }
    text = {name: _read(path) for name, path in paths.items()}

    for name, body in text.items():
        if not body:
            failures.append(f"missing required file: {paths[name]}")

    for token in _missing(text["model"], REQUIRED_MODEL_TOKENS):
        failures.append(f"emotional_experience_map.dart missing token: {token}")
    for token in _missing(text["providers"], REQUIRED_PROVIDER_TOKENS):
        failures.append(f"app_providers.dart missing token: {token}")
    for token in _missing(text["progress_screen"], REQUIRED_PROGRESS_TOKENS):
        failures.append(f"progress_screen.dart missing emotional map token: {token}")
    for token in _missing(text["coach_screen"], REQUIRED_COACH_TOKENS):
        failures.append(f"coach_command_screen.dart missing emotional map token: {token}")

    tests_text = "\n".join(
        [text["model_tests"], text["progress_tests"], text["coach_tests"]]
    )
    for token in _missing(tests_text, REQUIRED_TEST_TOKENS):
        failures.append(f"emotional map tests missing token: {token}")

    for token in _missing(text["ship_gate"], REQUIRED_SHIP_TOKENS):
        failures.append(f"ship_gate.sh missing emotional experience gate token: {token}")
    if "emotional_experience_map_gate" not in text["bridge"]:
        failures.append("bridge.json missing emotional_experience_map_gate routing")
    if '"emotional_experience_map"' not in text["bridge"]:
        failures.append("bridge.json missing emotional_experience_map artifact type")
    if "emotional_experience_map_gate" not in text["war_room"]:
        failures.append("two_day_war_room.json missing emotional_experience_map_gate")
    if "kpi-emotional-experience-map" not in text["war_room"]:
        failures.append("two_day_war_room.json missing emotional experience KPI")
    if '"emotional_experience_map"' not in text["war_room"]:
        failures.append("two_day_war_room.json missing emotional experience lane")
    if '"emotional_experience_map_gate"' not in text["war_room_gate"]:
        failures.append("two_day_war_room_gate.py missing emotional_experience_map_gate")
    if '"kpi-emotional-experience-map"' not in text["war_room_gate"]:
        failures.append("two_day_war_room_gate.py missing emotional experience KPI")

    visible_app_text = "\n".join(
        [text["progress_screen"], text["coach_screen"]]
    ).lower()
    for banned in sorted(APP_BANNED_TERMS):
        if banned in visible_app_text:
            failures.append(f"visible emotional map surface contains banned term: {banned}")

    return {
        "schema": "transformfit.emotional_experience_map_gate.v1",
        "repo_root": str(repo_root),
        "verdict": "GREEN" if not failures else "RED",
        "failures": failures,
    }


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=pathlib.Path,
        default=pathlib.Path("."),
        help="TransformFit Flutter repo root",
    )
    args = parser.parse_args(argv)

    result = run(args.repo_root.resolve())
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if result["verdict"] == "GREEN" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
