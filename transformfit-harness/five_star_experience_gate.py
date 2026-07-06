#!/usr/bin/env python3
"""Fail-closed gate for TransformFit's five-star experience review readiness."""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Iterable


REQUIRED_MODEL_TOKENS = {
    "fiveStarExperienceSourceIds",
    "fiveStarExperienceCriteria",
    "enum FiveStarExperienceStatus",
    "class FiveStarExperienceCriterion",
    "class FiveStarExperienceMoment",
    "buildFiveStarExperienceMoment",
    "fiveStarExperienceCopyIsGateSafe",
    "holdDuringTask",
    "holdForSafety",
    "completeActivation",
    "repairExperience",
    "readyNaturalBreak",
    "src_apple_hig_ratings_reviews",
    "src_apple_storekit_review_limits",
    "src_google_play_in_app_review_api",
    "src_transformfit_five_star_experience_bar",
    "Use the native review flow after the session recap",
    "Never interrupt a set, timer, debrief, or recovery decision with a store-rating request.",
}

REQUIRED_PROVIDER_TOKENS = {
    "fiveStarExperienceMomentProvider",
    "buildFiveStarExperienceMoment",
}

REQUIRED_COMMAND_MODEL_TOKENS = {
    "src_transformfit_five_star_experience_bar",
    "buildFiveStarExperienceMoment",
    "lane-review-readiness",
    "Review readiness",
}

REQUIRED_COMMAND_SCREEN_TOKENS = {
    "FiveStarExperienceMoment",
    "_FiveStarExperiencePanel",
    "Trust milestone",
    "Session ${moment.lastSatisfaction}/5",
    "fiveStarExperienceMomentProvider",
}

REQUIRED_TEST_TOKENS = {
    "active workout suppresses review prompt during task",
    "pain debrief blocks review readiness",
    "insufficient training proof keeps building value",
    "activation context must be complete before review eligibility",
    "low satisfaction routes to repair before review",
    "positive activated natural break is review eligible",
    "1000 generated review-readiness scenarios stay safe",
    "activated positive natural break becomes review eligible",
    "Trust milestone",
    "Build value",
}

REQUIRED_SHIP_TOKENS = {
    "FIVE_STAR_EXPERIENCE_GATE",
    "five_star_experience_gate",
    "Tier-1 22/27: five_star_experience_gate",
}

APP_BANNED_TERMS = {
    "beast mode",
    "burn fat",
    "diagnose",
    "do you love",
    "give us",
    "no excuses",
    "punish",
    "rate us",
    "shame",
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
        "model": repo_root / "lib/features/reviews/five_star_experience.dart",
        "providers": repo_root / "lib/app_providers.dart",
        "command_model": repo_root / "lib/features/coaching/coach_command_center.dart",
        "command_screen": repo_root / "lib/features/coaching/coach_command_screen.dart",
        "model_tests": repo_root / "test/features/reviews/five_star_experience_test.dart",
        "command_tests": repo_root / "test/features/coaching/coach_command_center_test.dart",
        "screen_tests": repo_root / "test/features/coaching/coach_command_screen_test.dart",
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
        failures.append(f"five_star_experience.dart missing token: {token}")
    for token in _missing(text["providers"], REQUIRED_PROVIDER_TOKENS):
        failures.append(f"app_providers.dart missing token: {token}")
    for token in _missing(text["command_model"], REQUIRED_COMMAND_MODEL_TOKENS):
        failures.append(f"coach_command_center.dart missing five-star token: {token}")
    for token in _missing(text["command_screen"], REQUIRED_COMMAND_SCREEN_TOKENS):
        failures.append(f"coach_command_screen.dart missing five-star token: {token}")

    tests_text = "\n".join(
        [text["model_tests"], text["command_tests"], text["screen_tests"]]
    )
    for token in _missing(tests_text, REQUIRED_TEST_TOKENS):
        failures.append(f"five-star tests missing token: {token}")

    for token in _missing(text["ship_gate"], REQUIRED_SHIP_TOKENS):
        failures.append(f"ship_gate.sh missing five-star gate token: {token}")
    if "five_star_experience_gate" not in text["bridge"]:
        failures.append("bridge.json missing five_star_experience_gate routing")
    if '"five_star_experience"' not in text["bridge"]:
        failures.append("bridge.json missing five_star_experience artifact type")
    if "five_star_experience_gate" not in text["war_room"]:
        failures.append("two_day_war_room.json missing five_star_experience_gate")
    if "kpi-five-star-experience" not in text["war_room"]:
        failures.append("two_day_war_room.json missing five-star experience KPI")
    if '"five_star_experience"' not in text["war_room"]:
        failures.append("two_day_war_room.json missing five-star experience lane")
    if '"five_star_experience_gate"' not in text["war_room_gate"]:
        failures.append("two_day_war_room_gate.py missing five_star_experience_gate")
    if '"kpi-five-star-experience"' not in text["war_room_gate"]:
        failures.append("two_day_war_room_gate.py missing five-star experience KPI")
    if '"five_star_experience"' not in text["war_room_gate"]:
        failures.append("two_day_war_room_gate.py missing five-star experience lane")

    visible_app_text = text["command_screen"].lower()
    for banned in sorted(APP_BANNED_TERMS):
        if banned in visible_app_text:
            failures.append(f"visible five-star surface contains banned term: {banned}")

    return {
        "schema": "transformfit.five_star_experience_gate.v1",
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
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)

    result = run(args.repo_root.resolve())
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if result["verdict"] == "GREEN" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
