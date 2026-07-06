#!/usr/bin/env python3
"""Deterministic validator for the TransformFit coaching harness."""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Any

EXPECTED_PERSONAS = {"Motivator", "Analyst", "Challenger", "Zen"}
EXPECTED_RULES = {
    "echo_user_words",
    "max_60_words",
    "no_emoji",
    "no_generic_encouragement",
    "specific_data_token",
    "honest_uncertainty",
    "weave_memory",
    "max_one_question",
}
EXPECTED_ARC = [
    ("0-7", 80, 20),
    ("8-14", 60, 40),
    ("15-21", 40, 60),
    ("22-30", 20, 80),
]
BANNED_TERMS = [
    "before and after",
    "body fat",
    "crush excuses",
    "no excuses",
    "punish",
    "shame on you",
    "streak broken",
    "weight loss",
]


def _load_json(path: pathlib.Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise ValueError("manifest root must be an object")
    return data


def _find_failures(data: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    if data.get("schema") != "transformfit.coaching_harness.v1":
        failures.append("schema must be transformfit.coaching_harness.v1")
    if data.get("deterministic_first") is not True:
        failures.append("deterministic_first must be true")
    if "Week-2 activated retention" not in str(data.get("north_star", "")):
        failures.append("north_star must trace to Week-2 activated retention")

    personas = data.get("personas")
    if not isinstance(personas, list):
        failures.append("personas must be a list")
    else:
        persona_names = {str(item.get("name", "")) for item in personas if isinstance(item, dict)}
        if persona_names != EXPECTED_PERSONAS:
            failures.append(
                f"personas must be exactly {sorted(EXPECTED_PERSONAS)}; got {sorted(persona_names)}"
            )
        for item in personas:
            if not isinstance(item, dict):
                failures.append("each persona must be an object")
                continue
            if not item.get("role") or not item.get("behavior"):
                failures.append(f"persona {item.get('name')} needs role and behavior")

    arc = data.get("tone_arc")
    if not isinstance(arc, list) or len(arc) != len(EXPECTED_ARC):
        failures.append("tone_arc must define the four doctrine day ranges")
    else:
        got_arc = [
            (str(item.get("day_range")), int(item.get("directive", -1)), int(item.get("supportive", -1)))
            for item in arc
            if isinstance(item, dict)
        ]
        if got_arc != EXPECTED_ARC:
            failures.append(f"tone_arc mismatch: got {got_arc}")
        for day_range, directive, supportive in got_arc:
            if directive + supportive != 100:
                failures.append(f"tone arc {day_range} must sum to 100")

    rules = set(data.get("message_rules", []))
    if rules != EXPECTED_RULES:
        failures.append(f"message_rules must be exactly {sorted(EXPECTED_RULES)}")

    workflows = data.get("workflow_states")
    if not isinstance(workflows, list) or len(workflows) < 4:
        failures.append("workflow_states must include at least four states")
    else:
        for item in workflows:
            if not isinstance(item, dict):
                failures.append("each workflow state must be an object")
                continue
            missing = [
                key
                for key in ("id", "trigger", "persona", "decision", "north_star_trace", "gates")
                if not item.get(key)
            ]
            if missing:
                failures.append(f"workflow {item.get('id', '<missing>')} missing {missing}")
            trace_ids = item.get("research_trace_ids")
            if not isinstance(trace_ids, list) or len(trace_ids) < 3:
                failures.append(
                    f"workflow {item.get('id', '<missing>')} must include at least three research_trace_ids"
                )
            elif any(not isinstance(trace_id, str) or not trace_id.strip() for trace_id in trace_ids):
                failures.append(f"workflow {item.get('id', '<missing>')} has invalid research_trace_ids")
            if item.get("persona") not in {p.lower() for p in EXPECTED_PERSONAS}:
                failures.append(f"workflow {item.get('id')} has unknown persona {item.get('persona')}")
            if "activation" not in str(item.get("north_star_trace", "")).lower() and "retention" not in str(
                item.get("north_star_trace", "")
            ).lower():
                failures.append(f"workflow {item.get('id')} lacks north-star trace")

    proof = data.get("proof_obligations")
    if not isinstance(proof, list) or len(proof) < 5:
        failures.append("proof_obligations must include at least five obligations")

    joined = json.dumps(data, sort_keys=True).lower()
    for term in BANNED_TERMS:
        if term in joined:
            failures.append(f"banned coaching term present: {term}")
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate TransformFit coaching harness")
    parser.add_argument("manifest", type=pathlib.Path)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    try:
        data = _load_json(args.manifest)
        failures = _find_failures(data)
    except Exception as exc:  # noqa: BLE001 - fail closed with useful message.
        failures = [str(exc)]

    result = {
        "schema": "transformfit.coaching_harness_gate.v1",
        "manifest": str(args.manifest),
        "verdict": "GREEN" if not failures else "RED",
        "failures": failures,
    }
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(f"{result['verdict']} coaching_harness_gate: {args.manifest}")
        for failure in failures:
            print(f"  - {failure}")
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main())
