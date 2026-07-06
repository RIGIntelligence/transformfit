#!/usr/bin/env python3
"""Fail-closed gate for TransformFit's composition-trust surface."""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Iterable


REQUIRED_SOURCE_IDS = {
    "src_cdc_bmi_individual_context_2025",
    "src_cdc_physical_activity_strength_2025",
    "src_fda_bia_home_device_estimate_k130311",
    "src_nap_weight_context_complexity",
    "src_transformfit_composition_trust_protocol",
}

REQUIRED_LOGIC_TOKENS = {
    "bodyCompositionTrustSourceIds",
    "class BodyCompositionTrustSignal",
    "class BodyCompositionTrustSummary",
    "buildBodyCompositionTrustSummary",
    "buildBodyCompositionTrustSummary(",
    "DateTime? now",
    "final anchorDay = _dateOnly(now ?? DateTime.now());",
    "_inRange(session.startedAt, currentWeekStart, anchorDay)",
    "bodyCompositionCopyIsTrustSafe",
    "Signals, not verdicts",
    "Imperfect signal",
    "Private by default",
    "Strength context",
    "Recovery context",
    "Adherence context",
    "Nutrition context",
    "Review after repeated readings",
}

REQUIRED_SCREEN_TOKENS = {
    "class BodyCompositionScreen",
    "Composition trust",
    "Signals, not verdicts",
    "Imperfect signal",
    "Private by default",
    "Source trace",
    "does not diagnose",
    "appearance score",
    "buildBodyCompositionTrustSummary",
}

REQUIRED_ROUTE_TOKENS = {
    "BodyCompositionScreen",
    "path: '/composition'",
    "name: 'composition'",
}

REQUIRED_DISCOVERY_TOKENS = {
    "context.go('/composition')",
    "Open composition trust",
    "Composition",
}

REQUIRED_TEST_TOKENS = {
    "empty composition trust waits for training context",
    "composition trust connects strength recovery adherence and nutrition",
    "composition adherence uses wall-clock today, not stale latest session",
    "now: DateTime(2026, 7, 20)",
    "expect(adherence.status, 'Baseline');",
    "1000 generated composition scenarios remain deterministic and safe",
    "composition screen renders trust-first empty state",
    "composition screen renders training nutrition and privacy context",
    "Authenticated users can access the composition route",
    "find.bySemanticsLabel('Open composition trust')",
}

REQUIRED_SHIP_TOKENS = {
    "BODY_COMPOSITION_TRUST_GATE",
    "body_composition_trust_gate",
    "Tier-1 11/27: body_composition_trust_gate",
    "BODY_COMPOSITION_SOURCES",
}

APP_BANNED_TERMS = {
    "before and after",
    "bikini",
    "burn fat",
    "cheat meal",
    "clean eating",
    "detox",
    "dream body",
    "fat loss",
    "guilt",
    "no excuses",
    "punish",
    "shame",
    "shred",
    "skinny",
    "summer body",
    "transformation photo",
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
        "logic": repo_root / "lib/features/body_composition/body_composition_trust.dart",
        "screen": repo_root / "lib/features/body_composition/body_composition_screen.dart",
        "router": repo_root / "lib/navigation/app_router.dart",
        "today": repo_root / "lib/screens/today_screen.dart",
        "progress": repo_root / "lib/features/progress/progress_screen.dart",
        "profile": repo_root / "lib/screens/profile_screen.dart",
        "logic_tests": repo_root / "test/features/body_composition/body_composition_trust_test.dart",
        "screen_tests": repo_root / "test/features/body_composition/body_composition_screen_test.dart",
        "progress_tests": repo_root / "test/features/progress/progress_screen_test.dart",
        "today_tests": repo_root / "test/today_screen_test.dart",
        "router_tests": repo_root / "test/navigation/app_router_test.dart",
        "sources": repo_root / "transformfit-harness/body_composition_sources.json",
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
        failures.append(f"body_composition_trust.dart missing token: {token}")
    if "completedSessions.last.startedAt" in text["logic"]:
        failures.append(
            "body_composition_trust.dart must not anchor adherence to latest completed session"
        )
    screen_contract_text = text["screen"] + "\n" + text["logic"]
    for token in _missing(screen_contract_text, REQUIRED_SCREEN_TOKENS):
        failures.append(f"body composition screen contract missing token: {token}")
    for token in _missing(text["router"], REQUIRED_ROUTE_TOKENS):
        failures.append(f"app_router.dart missing composition route token: {token}")

    discovery_text = "\n".join([text["today"], text["progress"], text["profile"]])
    for token in _missing(discovery_text, REQUIRED_DISCOVERY_TOKENS):
        failures.append(f"app surfaces missing composition discovery token: {token}")

    tests_text = "\n".join(
        [
            text["logic_tests"],
            text["screen_tests"],
            text["progress_tests"],
            text["today_tests"],
            text["router_tests"],
        ]
    )
    for token in _missing(tests_text, REQUIRED_TEST_TOKENS):
        failures.append(f"composition tests missing token: {token}")

    for token in _missing(text["ship_gate"], REQUIRED_SHIP_TOKENS):
        failures.append(f"ship_gate.sh missing composition gate token: {token}")
    if "body_composition_trust_gate" not in text["bridge"]:
        failures.append("bridge.json missing body_composition_trust_gate routing")
    if "body_composition_trust_gate" not in text["war_room"]:
        failures.append("two_day_war_room.json missing body_composition_trust_gate")
    if '"body_composition_trust_gate"' not in text["war_room_gate"]:
        failures.append("two_day_war_room_gate.py missing composition trust gate")
    if "imperfect signals" not in text["war_room"].lower():
        failures.append("two_day_war_room.json missing imperfect signals KPI language")

    source_data = _load_json(paths["sources"])
    if source_data.get("schema") != "transformfit.body_composition_sources.v1":
        failures.append("body_composition_sources.json has wrong schema")
    source_ids = {
        item.get("id")
        for item in source_data.get("sources", [])
        if isinstance(item, dict)
    }
    missing_source_ids = REQUIRED_SOURCE_IDS - source_ids
    if missing_source_ids:
        failures.append(f"composition source sidecar missing IDs: {sorted(missing_source_ids)}")
    for item in source_data.get("sources", []):
        if not isinstance(item, dict):
            failures.append("composition source entry must be an object")
            continue
        source_id = item.get("id", "<unknown>")
        url = str(item.get("source_url", ""))
        if source_id.startswith("src_cdc_") and "cdc.gov" not in url:
            failures.append(f"composition source {source_id} must cite cdc.gov")
        if source_id.startswith("src_fda_") and "accessdata.fda.gov" not in url:
            failures.append(f"composition source {source_id} must cite accessdata.fda.gov")
        if source_id.startswith("src_nap_") and "ncbi.nlm.nih.gov" not in url:
            failures.append(f"composition source {source_id} must cite ncbi.nlm.nih.gov")
        if not item.get("retrieved_at"):
            failures.append(f"composition source {source_id} missing retrieved_at")
        if not item.get("product_use"):
            failures.append(f"composition source {source_id} missing product_use")
    safety_rules = json.dumps(source_data.get("safety_rules", [])).lower()
    for phrase in ["signals, not verdicts", "private by default", "appearance"]:
        if phrase not in safety_rules:
            failures.append(f"composition safety rules must include: {phrase}")

    visible_app_text = "\n".join(
        [text["screen"], text["today"], text["progress"], text["profile"]]
    ).lower()
    for banned in sorted(APP_BANNED_TERMS):
        if banned in visible_app_text:
            failures.append(f"visible composition app surface contains banned term: {banned}")

    return {
        "schema": "transformfit.body_composition_trust_gate.v1",
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
        print(f"{result['verdict']} body_composition_trust_gate: {result['repo_root']}")
        for failure in result["failures"]:
            print(f"  - {failure}")
    return 0 if result["verdict"] == "GREEN" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
