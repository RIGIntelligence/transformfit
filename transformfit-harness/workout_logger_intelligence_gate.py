#!/usr/bin/env python3
"""Fail-closed gate for TransformFit's active workout set intelligence."""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Iterable


REQUIRED_SOURCE_IDS = {
    "src_macrofactor_workouts_product",
    "src_macrofactor_workouts_google_play",
    "src_hevy_app_store_preview",
    "src_hevy_rest_timer",
    "src_strong_app_store_preview",
    "src_fitbod_ai_why_2026",
}

REQUIRED_LOGIC_TOKENS = {
    "workoutLoggerIntelligenceSourceIds",
    "class PreviousSetReference",
    "class SetIntelligence",
    "previousSetReferenceForExercise",
    "buildSetIntelligence",
    "progressionIntent",
    "progressionReason",
    "restPace",
    "postSetCountdown",
    "Readiness is low",
    "Add one rep next",
    "Load progression",
    "Hold target",
    "selectedRestSeconds",
    "prescribedRestSeconds",
    "painSafetyActive",
    "Pain safety",
    "block load progression",
}

REQUIRED_MODEL_TOKENS = {
    "final DateTime? loggedAt",
    "final int? prescribedRestSeconds",
    "final int? actualRestSeconds",
    "'loggedAt': loggedAt?.toIso8601String()",
    "'prescribedRestSeconds': prescribedRestSeconds",
    "'actualRestSeconds': actualRestSeconds",
    "double get totalEffortUnits",
    "s.durationSeconds! / 30.0",
    "'totalEffortUnits': totalEffortUnits",
}

REQUIRED_CONTROLLER_TOKENS = {
    "DateTime? loggedAt",
    "int? prescribedRestSeconds",
    "int? actualRestSeconds",
    "loggedAt: loggedAt ?? DateTime.now()",
    "if (_state.activeSession == null) return;",
    "activeSessionPlan: exercises.isEmpty",
}

REQUIRED_SCREEN_TOKENS = {
    "import 'dart:async';",
    "Timer.periodic",
    "_startRestCountdown",
    "_restCountdownRemainingSeconds",
    "_restCountdownActive",
    "Rest started:",
    "Rest complete. Next set is ready.",
    "_actualRestSecondsBeforeSet",
    "_restPaceLabel",
    "_restPaceStatus",
    "actualRestSeconds",
    "Rest before:",
    "_painSafetyActive",
    "_activatePainSafety",
    "_applyPainSafetyCaps",
    "Pain safety active. Load progression blocked",
    "_readinessAdjustedSessionPlan",
    "_readinessWeightCeiling",
    "_readinessCapActive",
    "_readinessCappedTargetSets",
    "Readiness cap active",
    "Return to normal after recovery",
    "_applyTechniqueSwap",
    "_TechniqueSwap",
    "_techniqueSwapExerciseId",
    "Technique swap loaded",
    "Technique swap",
    "Set intelligence",
    "Progression intent",
    "Rest pace",
    "Previous reference",
    "Readiness context",
    "Post-set countdown",
    "buildSetIntelligence",
    "previousSetReferenceForExercise",
    "previousSetReferenceLabel",
    "_SetIntelligencePanel",
    "_SetIntentBadge",
    "_satisfaction",
    "Debrief satisfaction",
    "satisfaction: result.satisfaction",
}

REQUIRED_TEST_TOKENS = {
    "previous set reference prefers stable exercise IDs and date context",
    "set intelligence explains progression intent and rest pace",
    "set intelligence reduces target on low readiness before overload",
    "set intelligence detects load progression and long rest",
    "1000 generated set intelligence scenarios stay deterministic and safe",
    "Set intelligence",
    "Progression intent",
    "Rest pace",
    "Previous reference",
    "Readiness context",
    "Post-set countdown",
    "active workout auto-starts rest countdown after logging a set",
    "Rest started: 1:30",
    "Rest timer, 1 minute 29 seconds",
    "logSet records loggedAt and rest timing fields",
    "active workout records actual rest pace between logged sets",
    "actualRestSeconds, 45",
    "Rest before: 0:45 early vs 1:30",
    "set intelligence blocks progression when pain safety is active",
    "active workout pain safety blocks load progression",
    "Pain safety active. Load progression blocked",
    "active workout turns low readiness into capped active targets",
    "Readiness cap active",
    "2 planned sets",
    "85 kg",
    "active workout technique swap loads a safer variation and counts the plan set",
    "Technique swap loaded",
    "barbell_squat.technique_swap",
    "active workout debrief persists only entered fields and ratings",
    "Increase satisfaction",
    "Left knee stayed quiet.",
    "expect(debrief?.satisfaction, 5);",
    "expect(debrief?.whatWorked, isNull);",
    "expect(debrief?.whatToChange, isNull);",
    "attachActiveSessionPlan accepts an empty list as an explicit clear",
    "controller.attachActiveSessionPlan(const []);",
    "expect(controller.state.activeSessionPlan, isEmpty);",
    "WorkoutSession effort units include bodyweight and timed work",
    "Bodyweight Split Squat",
    "Side Plank",
    "expect(session.totalEffortUnits, 19);",
    "expect(json['totalEffortUnits'], 19);",
}

REQUIRED_SHIP_TOKENS = {
    "WORKOUT_LOGGER_INTELLIGENCE_GATE",
    "workout_logger_intelligence_gate",
    "Tier-1 12/27: workout_logger_intelligence_gate",
    "WORKOUT_LOGGER_SOURCES",
}

APP_BANNED_TERMS = {
    "burn fat",
    "cheat meal",
    "clean eating",
    "detox",
    "no excuses",
    "punish",
    "shame",
    "shred",
    "summer body",
    "weight loss",
}

FORBIDDEN_SCREEN_TOKENS = {
    "Logged the work and kept the appointment.",
    "Use the next focus before adding complexity.",
}

FORBIDDEN_CONTROLLER_TOKENS = {
    "if (_state.activeSession == null || exercises.isEmpty) return;",
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
        "logic": repo_root / "lib/features/workout/set_intelligence.dart",
        "models": repo_root / "lib/features/session/models.dart",
        "controller": repo_root / "lib/features/session/session_controller.dart",
        "screen": repo_root / "lib/features/workout/active_workout_screen.dart",
        "logic_tests": repo_root / "test/features/workout/set_intelligence_test.dart",
        "screen_tests": repo_root / "test/features/workout/active_workout_screen_test.dart",
        "controller_tests": repo_root / "test/features/session/session_controller_test.dart",
        "sources": repo_root / "transformfit-harness/workout_logger_sources.json",
        "ship_gate": repo_root / "transformfit-harness/ship_gate.sh",
        "bridge": repo_root / "transformfit-harness/bridge.json",
        "war_room": repo_root / "transformfit-harness/two_day_war_room.json",
        "war_room_gate": repo_root / "transformfit-harness/two_day_war_room_gate.py",
    }
    text = {name: _read(path) for name, path in paths.items()}

    for name, body in text.items():
        if not body:
            failures.append(f"missing required file: {paths[name]}")

    for token in _missing(text["logic"], REQUIRED_LOGIC_TOKENS):
        failures.append(f"set_intelligence.dart missing token: {token}")
    for token in _missing(text["models"], REQUIRED_MODEL_TOKENS):
        failures.append(f"models.dart missing rest timing token: {token}")
    for token in _missing(text["controller"], REQUIRED_CONTROLLER_TOKENS):
        failures.append(f"session_controller.dart missing rest timing token: {token}")
    for token in sorted(FORBIDDEN_CONTROLLER_TOKENS):
        if token in text["controller"]:
            failures.append(
                "session_controller.dart contains forbidden stale plan-clear guard: "
                f"{token}"
            )
    for token in _missing(text["screen"], REQUIRED_SCREEN_TOKENS):
        failures.append(f"active_workout_screen.dart missing set-intelligence token: {token}")
    for token in sorted(FORBIDDEN_SCREEN_TOKENS):
        if token in text["screen"]:
            failures.append(
                "active_workout_screen.dart contains forbidden fabricated debrief token: "
                f"{token}"
            )

    tests_text = text["logic_tests"] + "\n" + text["screen_tests"] + "\n" + text["controller_tests"]
    for token in _missing(tests_text, REQUIRED_TEST_TOKENS):
        failures.append(f"workout logger tests missing token: {token}")

    for token in _missing(text["ship_gate"], REQUIRED_SHIP_TOKENS):
        failures.append(f"ship_gate.sh missing workout logger gate token: {token}")
    if "workout_logger_intelligence_gate" not in text["bridge"]:
        failures.append("bridge.json missing workout_logger_intelligence_gate routing")
    if "workout_logger_intelligence_gate" not in text["war_room"]:
        failures.append("two_day_war_room.json missing workout logger intelligence gate")
    if '"workout_logger_intelligence_gate"' not in text["war_room_gate"]:
        failures.append("two_day_war_room_gate.py missing workout logger intelligence gate")
    if "kpi-set-intelligence" not in text["war_room"]:
        failures.append("two_day_war_room.json missing set-intelligence KPI")

    source_data = _load_json(paths["sources"])
    if source_data.get("schema") != "transformfit.workout_logger_sources.v1":
        failures.append("workout_logger_sources.json has wrong schema")
    source_ids = {
        item.get("id")
        for item in source_data.get("sources", [])
        if isinstance(item, dict)
    }
    missing_source_ids = REQUIRED_SOURCE_IDS - source_ids
    if missing_source_ids:
        failures.append(f"workout logger source sidecar missing IDs: {sorted(missing_source_ids)}")
    for item in source_data.get("sources", []):
        if not isinstance(item, dict):
            failures.append("workout logger source entry must be an object")
            continue
        source_id = item.get("id", "<unknown>")
        url = str(item.get("source_url", ""))
        if source_id.startswith("src_macrofactor") and "macrofactor.com" not in url and "play.google.com" not in url:
            failures.append(f"workout logger source {source_id} must cite MacroFactor or app-store evidence")
        if source_id.startswith("src_hevy") and "hevy" not in url and "apps.apple.com" not in url:
            failures.append(f"workout logger source {source_id} must cite Hevy evidence")
        if source_id.startswith("src_strong") and "apps.apple.com" not in url:
            failures.append(f"workout logger source {source_id} must cite App Store evidence")
        if source_id.startswith("src_fitbod") and "techradar.com" not in url:
            failures.append(f"workout logger source {source_id} must cite the 2026 AI-fitness why source")
        if not item.get("retrieved_at"):
            failures.append(f"workout logger source {source_id} missing retrieved_at")
        if not item.get("product_use"):
            failures.append(f"workout logger source {source_id} missing product_use")

    quality = json.dumps(source_data.get("workout_logger_quality_bar", [])).lower()
    for phrase in [
        "progressive overload",
        "previous performance",
        "selected rest versus prescribed rest",
        "low readiness",
        "load/rpe",
        "planned sets",
        "pain safety",
        "technique substitutions",
    ]:
        if phrase not in quality:
            failures.append(f"workout logger quality bar must include: {phrase}")

    panel = source_data.get("team_panel_proxy", {})
    if panel.get("simulated_users") != 20:
        failures.append("team_panel_proxy must record 20 simulated users")
    for group in [
        "designers",
        "fitness_coaches",
        "top_fitness_influencer_patterns",
        "artists_photographers",
        "ai_engineers",
        "nutritionists",
        "behavioral_science_specialists",
    ]:
        if not isinstance(panel.get(group), int) or panel.get(group, 0) <= 0:
            failures.append(f"team_panel_proxy missing positive count for {group}")
    boundary = str(panel.get("boundary", "")).lower()
    for phrase in ["no outreach", "endorsement", "public claim"]:
        if phrase not in boundary:
            failures.append(f"team_panel_proxy boundary must include: {phrase}")

    visible_app_text = text["screen"].lower()
    for banned in sorted(APP_BANNED_TERMS):
        if banned in visible_app_text:
            failures.append(f"visible active workout surface contains banned term: {banned}")

    return {
        "schema": "transformfit.workout_logger_intelligence_gate.v1",
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
        print(f"{result['verdict']} workout_logger_intelligence_gate: {result['repo_root']}")
        for failure in result["failures"]:
            print(f"  - {failure}")
    return 0 if result["verdict"] == "GREEN" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
