#!/usr/bin/env python3
"""Fail-closed gate for TransformFit's RIG systems engineering layer."""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Iterable


REQUIRED_MODEL_TOKENS = {
    "rigSystemsEngineeringSourceIds",
    "enum RigBuildMode",
    "enum RigDiamond",
    "enum RigProcessStep",
    "class RigBuildModeArchetype",
    "class RigDiamondCell",
    "class RigSystemsEngineeringSnapshot",
    "rigBuildModeArchetypes",
    "A1 deterministic",
    "A2 hybrid typed",
    "A3 agent bounded",
    "A4 LLM agent free",
    "BMS 0.75-1.00",
    "BMS 0.45-0.74",
    "BMS 0.25-0.44",
    "BMS 0.00-0.24",
    "buildRigSystemsEngineeringSnapshot",
    "buildTripleDoubleDiamondCells",
    "rigArchetypeForBms",
    "rigSystemsCopyIsGateSafe",
    "A1 unknown escalates",
    "A4 stays draft-only",
}

REQUIRED_PROVIDER_TOKENS = {
    "rigSystemsEngineeringProvider",
    "buildRigSystemsEngineeringSnapshot",
}

REQUIRED_SCREEN_TOKENS = {
    "RigSystemsEngineeringSnapshot",
    "_RigSystemsPanel",
    "_DiamondSummary",
    "_BuildModeCard",
    "RIG systems",
    "Triple Double Diamond",
    "BMS ",
    "IQRSQPI cells",
}

REQUIRED_ARCHETYPE_LABEL_TOKENS = {
    "A1 deterministic",
    "A2 hybrid typed",
    "A3 agent bounded",
    "A4 LLM agent free",
}

REQUIRED_TEST_TOKENS = {
    "full A1 A2 A3 A4 archetypes and BMS bands are defined",
    "empty state routes to A4 draft-only exploration",
    "rich local state routes to A1 deterministic execution",
    "pain state uses A1 safety override",
    "triple double diamond maps D1 D2 D3 across IQRSQPI",
    "RIG systems",
    "Triple Double Diamond",
}

REQUIRED_SHIP_TOKENS = {
    "RIG_SYSTEMS_ENGINEERING_GATE",
    "rig_systems_engineering_gate",
    "Tier-1 17/27: rig_systems_engineering_gate",
}

APP_BANNED_TERMS = {
    "burn fat",
    "diagnose",
    "no excuses",
    "punish",
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
        "model": repo_root / "lib/features/rig_systems/rig_systems_engineering.dart",
        "providers": repo_root / "lib/app_providers.dart",
        "screen": repo_root / "lib/features/coaching/coach_command_screen.dart",
        "model_tests": repo_root / "test/features/rig_systems/rig_systems_engineering_test.dart",
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
        failures.append(f"rig_systems_engineering.dart missing token: {token}")
    for token in _missing(text["providers"], REQUIRED_PROVIDER_TOKENS):
        failures.append(f"app_providers.dart missing token: {token}")
    for token in _missing(text["screen"], REQUIRED_SCREEN_TOKENS):
        failures.append(f"coach_command_screen.dart missing RIG systems token: {token}")
    archetype_text = "\n".join([text["model"], text["screen"], text["model_tests"], text["screen_tests"]])
    for token in _missing(archetype_text, REQUIRED_ARCHETYPE_LABEL_TOKENS):
        failures.append(f"RIG systems archetype label missing from model/screen/test surface: {token}")

    tests_text = "\n".join([text["model_tests"], text["screen_tests"]])
    for token in _missing(tests_text, REQUIRED_TEST_TOKENS):
        failures.append(f"RIG systems tests missing token: {token}")

    for token in _missing(text["ship_gate"], REQUIRED_SHIP_TOKENS):
        failures.append(f"ship_gate.sh missing RIG systems gate token: {token}")
    if "rig_systems_engineering_gate" not in text["bridge"]:
        failures.append("bridge.json missing rig_systems_engineering_gate routing")
    if '"rig_systems_engineering"' not in text["bridge"]:
        failures.append("bridge.json missing rig_systems_engineering artifact type")
    if "rig_systems_engineering_gate" not in text["war_room"]:
        failures.append("two_day_war_room.json missing rig_systems_engineering_gate")
    if "kpi-rig-systems-engineering" not in text["war_room"]:
        failures.append("two_day_war_room.json missing RIG systems KPI")
    if "rig_systems_engineering" not in text["war_room"]:
        failures.append("two_day_war_room.json missing RIG systems lane")
    if '"rig_systems_engineering_gate"' not in text["war_room_gate"]:
        failures.append("two_day_war_room_gate.py missing rig_systems_engineering_gate")
    if '"kpi-rig-systems-engineering"' not in text["war_room_gate"]:
        failures.append("two_day_war_room_gate.py missing RIG systems KPI")
    if '"rig_systems_engineering"' not in text["war_room_gate"]:
        failures.append("two_day_war_room_gate.py missing RIG systems lane")

    visible_app_text = text["screen"].lower()
    for banned in sorted(APP_BANNED_TERMS):
        if banned in visible_app_text:
            failures.append(f"visible RIG systems surface contains banned term: {banned}")

    return {
        "schema": "transformfit.rig_systems_engineering_gate.v1",
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
