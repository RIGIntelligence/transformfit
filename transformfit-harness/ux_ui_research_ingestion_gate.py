#!/usr/bin/env python3
"""Validate TransformFit UX/UI research ingestion and traceability.

This gate keeps the "we embedded the research" claim honest. It cross-checks
research source IDs against the competitive ledger, screen mappings against real
repo paths, and coaching workflow mappings against the coaching harness.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Any

SCREEN_EVIDENCE_LEVELS = {
    "first_party_capture",
    "screen_state_capture",
    "screenshot_packet",
}

REQUIRED_SCREEN_IDS = {
    "welcome",
    "onboarding_intake",
    "plan_reveal",
    "today",
    "active_workout_log",
    "progress",
    "proof_card",
    "profile",
}

REQUIRED_ACTIVE_WORKOUT_INVARIANTS = {
    "fast_set_logging",
    "previous_set_reference",
    "rest_timer",
    "smart_progression",
    "undo_safety",
}

REQUIRED_ACTIVE_WORKOUT_SOURCES = {
    "src_macrofactor_workouts_product",
    "src_hevy_app_store_preview",
}

REQUIRED_PROOF_CARD_INVARIANTS = {
    "opt_in_share",
    "sourceable_claims",
    "body_neutral_share",
    "privacy_redacted_share_text",
}

REQUIRED_WORKFLOW_GUARDS = {"message_rule_lint", "doctrine_lint"}

PROOF_SHARE_REQUIRED_TOKENS = {
    "model": {
        "path": "lib/features/proof/proof_card.dart",
        "tokens": [
            "proofShareTextIsPrivacySafe",
            "sharePrivacySummary",
            "shareRedactions",
            "shareConsentLabel",
            "Shared by choice",
            "No measurements",
            "No injury details",
        ],
    },
    "screen": {
        "path": "lib/features/proof/proof_card_screen.dart",
        "tokens": [
            "Clipboard.setData",
            "CheckboxListTile",
            "Copy proof text",
            "Copy redacted proof text",
            "Private by default",
            "Proof text copied. You choose where it goes.",
        ],
    },
    "model_tests": {
        "path": "test/features/proof/proof_card_test.dart",
        "tokens": [
            "1000 generated proof scenarios stay body-neutral and deterministic",
            "proofShareTextIsPrivacySafe",
            "isNot(contains('kg'))",
            "isNot(contains('rpe'))",
            "No measurements",
            "No injury details",
        ],
    },
    "screen_tests": {
        "path": "test/features/proof/proof_card_screen_test.dart",
        "tokens": [
            "proof card copy is disabled until explicit opt-in",
            "setMockMethodCallHandler",
            "I reviewed this redacted proof text",
            "isNot(contains('90 kg'))",
            "isNot(contains('Front squat'))",
            "isNot(contains('hip'))",
        ],
    },
}

PLAN_REVEAL_SANITIZER_REQUIRED_TOKENS = {
    "controller": {
        "path": "lib/features/onboarding/plan_reveal_controller.dart",
        "tokens": [
            "Strip emoji + markup + question marks",
            "replaceAll(RegExp(r'\\?'), '')",
        ],
    },
    "server": {
        "path": "supabase/functions/_shared/llm.ts",
        "tokens": [
            "Strip emoji + markup + question marks",
            'replace(/\\?/g, "")',
        ],
    },
    "server_tests": {
        "path": "supabase/functions/_shared/llm_test.ts",
        "tokens": [
            'sanitizeUserPhrase("Can I get strong?")',
            '"Can I get strong"',
            'sanitizeUserPhrase("Why? How? When?")',
            '"Why How When"',
        ],
    },
    "real_wiring_tests": {
        "path": "test/features/onboarding/plan_reveal_real_wiring_test.dart",
        "tokens": [
            "question marks are stripped from echoed why-now phrase",
            "to match server sanitizer",
            "echoed.contains('?')",
            "client echo must match server sanitizer question stripping",
            "Can I really get strong Why now",
        ],
    },
}


def _load_json(path: pathlib.Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise ValueError(f"{path} root must be an object")
    return data


def _as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def _string_set(value: Any) -> set[str]:
    return {str(item) for item in _as_list(value) if isinstance(item, str) and item.strip()}


def _audit_sources(data: dict[str, Any], ledger: dict[str, Any]) -> tuple[list[str], set[str], set[str]]:
    failures: list[str] = []
    source_ids: set[str] = set()
    missing_source_ids: set[str] = set()

    sources = _as_list(data.get("research_sources"))
    if len(sources) < 10:
        failures.append(f"research_sources must include at least 10 entries; got {len(sources)}")

    ledger_apps = {
        str(app.get("name")): app
        for app in _as_list(ledger.get("apps_logged"))
        if isinstance(app, dict) and app.get("name")
    }
    ledger_bound_count = 0
    screen_evidence_count = 0
    macrofactor_seen = False

    for index, source in enumerate(sources):
        if not isinstance(source, dict):
            failures.append(f"research source {index} must be an object")
            continue
        source_id = str(source.get("id", "")).strip()
        if not source_id:
            failures.append(f"research source {index} missing id")
            continue
        if source_id in source_ids:
            failures.append(f"duplicate research source id: {source_id}")
        source_ids.add(source_id)

        kind = str(source.get("kind", "")).strip()
        if kind == "missing_external_repo":
            missing_source_ids.add(source_id)
            status = str(source.get("status", "")).lower()
            if "not_found" not in status and "not_accessible" not in status:
                failures.append(f"{source_id} missing-source status must be explicit; got {status!r}")
            continue

        if kind != "competitive_ledger_app":
            failures.append(f"{source_id} kind must be competitive_ledger_app or missing_external_repo")
            continue

        ledger_name = str(source.get("ledger_app_name", "")).strip()
        if not ledger_name:
            failures.append(f"{source_id} missing ledger_app_name")
            continue
        ledger_app = ledger_apps.get(ledger_name)
        if ledger_app is None:
            failures.append(f"{source_id} references missing ledger app {ledger_name!r}")
            continue
        ledger_bound_count += 1

        if "macrofactor" in ledger_name.lower():
            macrofactor_seen = True

        source_url = str(source.get("source_url", "")).strip()
        ledger_url = str(ledger_app.get("source_url", "")).strip()
        if not source_url.startswith("http"):
            failures.append(f"{source_id} missing http source_url")
        elif ledger_url and source_url != ledger_url:
            failures.append(f"{source_id} source_url does not match ledger url for {ledger_name}")

        evidence_level = str(source.get("evidence_level", "")).strip()
        ledger_evidence = str(ledger_app.get("evidence_level", "")).strip()
        if evidence_level != ledger_evidence:
            failures.append(
                f"{source_id} evidence_level {evidence_level!r} does not match ledger {ledger_evidence!r}"
            )
        if evidence_level in SCREEN_EVIDENCE_LEVELS:
            screen_evidence_count += 1

    if ledger_bound_count < 9:
        failures.append(f"at least 9 research sources must bind to the competitive ledger; got {ledger_bound_count}")
    if screen_evidence_count < 6:
        failures.append(f"at least 6 research sources must be screen-state evidence; got {screen_evidence_count}")
    if not macrofactor_seen:
        failures.append("at least one MacroFactor source is required")
    if "src_ux_ui_scraper_repo_requested" not in missing_source_ids:
        failures.append("missing requested ux-ui-scraper repo must be recorded as src_ux_ui_scraper_repo_requested")

    return failures, source_ids, missing_source_ids


def _audit_principles(
    data: dict[str, Any],
    source_ids: set[str],
    missing_source_ids: set[str],
) -> tuple[list[str], set[str]]:
    failures: list[str] = []
    principle_ids: set[str] = set()
    principles = _as_list(data.get("ux_principles"))
    if len(principles) < 8:
        failures.append(f"ux_principles must include at least 8 entries; got {len(principles)}")

    for index, principle in enumerate(principles):
        if not isinstance(principle, dict):
            failures.append(f"ux principle {index} must be an object")
            continue
        principle_id = str(principle.get("id", "")).strip()
        if not principle_id:
            failures.append(f"ux principle {index} missing id")
            continue
        if principle_id in principle_ids:
            failures.append(f"duplicate ux principle id: {principle_id}")
        principle_ids.add(principle_id)

        refs = _string_set(principle.get("source_ids"))
        if len(refs) < 2:
            failures.append(f"{principle_id} must cite at least two source_ids")
        unknown = refs - source_ids
        if unknown:
            failures.append(f"{principle_id} references unknown source_ids: {sorted(unknown)}")
        if refs and refs <= missing_source_ids:
            failures.append(f"{principle_id} cites only missing-source gaps")
        if principle.get("screen_observable") is not True:
            failures.append(f"{principle_id} must be screen_observable=true")
        if not _as_list(principle.get("target_screen_ids")):
            failures.append(f"{principle_id} missing target_screen_ids")
        if not str(principle.get("principle", "")).strip():
            failures.append(f"{principle_id} missing principle text")

    return failures, principle_ids


def _audit_screens(
    data: dict[str, Any],
    repo_root: pathlib.Path,
    source_ids: set[str],
    missing_source_ids: set[str],
    principle_ids: set[str],
) -> list[str]:
    failures: list[str] = []
    screens = _as_list(data.get("screen_traceability"))
    screen_by_id: dict[str, dict[str, Any]] = {}

    for index, screen in enumerate(screens):
        if not isinstance(screen, dict):
            failures.append(f"screen trace {index} must be an object")
            continue
        screen_id = str(screen.get("id", "")).strip()
        if not screen_id:
            failures.append(f"screen trace {index} missing id")
            continue
        if screen_id in screen_by_id:
            failures.append(f"duplicate screen id: {screen_id}")
        screen_by_id[screen_id] = screen

        screen_path = str(screen.get("screen_path", "")).strip()
        if not screen_path:
            failures.append(f"{screen_id} missing screen_path")
        elif not (repo_root / screen_path).is_file():
            failures.append(f"{screen_id} screen_path does not exist: {screen_path}")

        refs = _string_set(screen.get("source_ids"))
        if len(refs) < 3:
            failures.append(f"{screen_id} must cite at least 3 source_ids")
        unknown_sources = refs - source_ids
        if unknown_sources:
            failures.append(f"{screen_id} references unknown source_ids: {sorted(unknown_sources)}")
        if refs and refs <= missing_source_ids:
            failures.append(f"{screen_id} cites only missing-source gaps")

        refs_principles = _string_set(screen.get("ux_principle_ids"))
        if len(refs_principles) < 2:
            failures.append(f"{screen_id} must cite at least 2 ux_principle_ids")
        unknown_principles = refs_principles - principle_ids
        if unknown_principles:
            failures.append(f"{screen_id} references unknown ux_principle_ids: {sorted(unknown_principles)}")

        invariants = _as_list(screen.get("ux_invariants"))
        if len(invariants) < 3:
            failures.append(f"{screen_id} must include at least 3 ux_invariants")
        for invariant in invariants:
            if not isinstance(invariant, dict):
                failures.append(f"{screen_id} invariant must be an object")
                continue
            for key in ("id", "statement", "test_surface"):
                if not str(invariant.get(key, "")).strip():
                    failures.append(f"{screen_id} invariant missing {key}")

        if len(_as_list(screen.get("product_metrics"))) < 1:
            failures.append(f"{screen_id} must include at least 1 product metric")

        gates = _string_set(screen.get("gate_ids"))
        if "ux_ui_research_ingestion_gate" not in gates:
            failures.append(f"{screen_id} must include ux_ui_research_ingestion_gate in gate_ids")

    missing_screens = REQUIRED_SCREEN_IDS - set(screen_by_id)
    if missing_screens:
        failures.append(f"missing required screen ids: {sorted(missing_screens)}")

    active = screen_by_id.get("active_workout_log")
    if isinstance(active, dict):
        active_sources = _string_set(active.get("source_ids"))
        missing_active_sources = REQUIRED_ACTIVE_WORKOUT_SOURCES - active_sources
        if missing_active_sources:
            failures.append(f"active_workout_log missing required sources: {sorted(missing_active_sources)}")
        invariant_ids = {
            str(item.get("id"))
            for item in _as_list(active.get("ux_invariants"))
            if isinstance(item, dict) and item.get("id")
        }
        missing_invariants = REQUIRED_ACTIVE_WORKOUT_INVARIANTS - invariant_ids
        if missing_invariants:
            failures.append(f"active_workout_log missing required invariants: {sorted(missing_invariants)}")

    proof = screen_by_id.get("proof_card")
    if isinstance(proof, dict):
        proof_invariant_ids = {
            str(item.get("id"))
            for item in _as_list(proof.get("ux_invariants"))
            if isinstance(item, dict) and item.get("id")
        }
        missing_proof_invariants = REQUIRED_PROOF_CARD_INVARIANTS - proof_invariant_ids
        if missing_proof_invariants:
            failures.append(f"proof_card missing required invariants: {sorted(missing_proof_invariants)}")

    return failures


def _audit_proof_share_implementation(repo_root: pathlib.Path) -> list[str]:
    failures: list[str] = []
    for surface_id, spec in PROOF_SHARE_REQUIRED_TOKENS.items():
        path = repo_root / str(spec["path"])
        if not path.is_file():
            failures.append(f"proof share {surface_id} file missing: {spec['path']}")
            continue
        content = path.read_text(encoding="utf-8")
        for token in spec["tokens"]:
            if str(token) not in content:
                failures.append(f"proof share {surface_id} missing token: {token}")
    return failures


def _audit_plan_reveal_sanitizer_parity(repo_root: pathlib.Path) -> list[str]:
    failures: list[str] = []
    for surface_id, spec in PLAN_REVEAL_SANITIZER_REQUIRED_TOKENS.items():
        path = repo_root / str(spec["path"])
        if not path.is_file():
            failures.append(f"plan reveal sanitizer {surface_id} file missing: {spec['path']}")
            continue
        content = path.read_text(encoding="utf-8")
        for token in spec["tokens"]:
            if str(token) not in content:
                failures.append(
                    f"plan reveal sanitizer {surface_id} missing parity token: {token}"
                )
    return failures


def _audit_coaching_workflows(
    data: dict[str, Any],
    coaching: dict[str, Any],
    source_ids: set[str],
    missing_source_ids: set[str],
    principle_ids: set[str],
) -> list[str]:
    failures: list[str] = []
    workflow_states = {
        str(item.get("id")): item
        for item in _as_list(coaching.get("workflow_states"))
        if isinstance(item, dict) and item.get("id")
    }
    traces = {
        str(item.get("workflow_id")): item
        for item in _as_list(data.get("coaching_workflow_traceability"))
        if isinstance(item, dict) and item.get("workflow_id")
    }

    if set(traces) != set(workflow_states):
        failures.append(
            "coaching_workflow_traceability must exactly cover coaching_harness workflow ids; "
            f"missing={sorted(set(workflow_states) - set(traces))} extra={sorted(set(traces) - set(workflow_states))}"
        )

    for workflow_id, state in workflow_states.items():
        trace = traces.get(workflow_id)
        harness_refs = _string_set(state.get("research_trace_ids"))
        if not harness_refs:
            failures.append(f"coaching_harness workflow {workflow_id} missing research_trace_ids")
        if harness_refs - source_ids:
            failures.append(
                f"coaching_harness workflow {workflow_id} references unknown research_trace_ids: {sorted(harness_refs - source_ids)}"
            )
        if trace is None:
            continue

        refs = _string_set(trace.get("source_ids"))
        if len(refs) < 3:
            failures.append(f"{workflow_id} must cite at least 3 source_ids")
        if refs - source_ids:
            failures.append(f"{workflow_id} references unknown source_ids: {sorted(refs - source_ids)}")
        if refs and refs <= missing_source_ids:
            failures.append(f"{workflow_id} cites only missing-source gaps")
        if harness_refs and not harness_refs <= refs:
            failures.append(f"{workflow_id} ingestion trace must include all harness research_trace_ids")

        principle_refs = _string_set(trace.get("ux_principle_ids"))
        if not principle_refs:
            failures.append(f"{workflow_id} missing ux_principle_ids")
        if principle_refs - principle_ids:
            failures.append(f"{workflow_id} references unknown ux_principle_ids: {sorted(principle_refs - principle_ids)}")

        mechanisms = _as_list(trace.get("behavioral_mechanisms"))
        if len(mechanisms) < 2:
            failures.append(f"{workflow_id} must include at least 2 behavioral_mechanisms")
        guards = _string_set(trace.get("guardrail_ids"))
        if not REQUIRED_WORKFLOW_GUARDS <= guards:
            failures.append(f"{workflow_id} guardrail_ids must include {sorted(REQUIRED_WORKFLOW_GUARDS)}")

    return failures


def _find_failures(
    ingestion: dict[str, Any],
    ledger: dict[str, Any],
    coaching: dict[str, Any],
    repo_root: pathlib.Path,
) -> list[str]:
    failures: list[str] = []
    if ingestion.get("schema") != "transformfit.ux_ui_research_ingestion.v1":
        failures.append("schema must be transformfit.ux_ui_research_ingestion.v1")
    if ledger.get("schema") != "transformfit.competitive_reverse_engineering.v1":
        failures.append("competitive ledger schema mismatch")
    if coaching.get("schema") != "transformfit.coaching_harness.v1":
        failures.append("coaching harness schema mismatch")

    status = ingestion.get("source_status")
    if not isinstance(status, dict):
        failures.append("source_status must be an object")
    else:
        repo_status = str(status.get("requested_repo_status", "")).lower()
        if "not_found" not in repo_status and "not_accessible" not in repo_status:
            failures.append("requested_repo_status must explicitly record not_found or not_accessible")
        if "RIGIntelligence/transformfit" not in str(status.get("canonical_transformfit_remote", "")):
            failures.append("canonical_transformfit_remote must point to RIGIntelligence/transformfit")

    source_failures, source_ids, missing_source_ids = _audit_sources(ingestion, ledger)
    failures.extend(source_failures)

    principle_failures, principle_ids = _audit_principles(ingestion, source_ids, missing_source_ids)
    failures.extend(principle_failures)
    failures.extend(_audit_screens(ingestion, repo_root, source_ids, missing_source_ids, principle_ids))
    failures.extend(_audit_coaching_workflows(ingestion, coaching, source_ids, missing_source_ids, principle_ids))
    failures.extend(_audit_proof_share_implementation(repo_root))
    failures.extend(_audit_plan_reveal_sanitizer_parity(repo_root))

    obligations = _as_list(ingestion.get("proof_obligations"))
    if len(obligations) < 5:
        failures.append("proof_obligations must include at least 5 obligations")

    quality = ingestion.get("quality_standard")
    if not isinstance(quality, dict):
        failures.append("quality_standard must be an object")
    else:
        required = set(map(str, _as_list(quality.get("required_active_workout_invariants"))))
        if not REQUIRED_ACTIVE_WORKOUT_INVARIANTS <= required:
            failures.append("quality_standard missing required_active_workout_invariants")
        required_screens = set(map(str, _as_list(quality.get("required_screen_ids"))))
        if not REQUIRED_SCREEN_IDS <= required_screens:
            failures.append("quality_standard missing required_screen_ids")

    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate TransformFit UX/UI research ingestion")
    parser.add_argument("ingestion", type=pathlib.Path)
    parser.add_argument(
        "--competitive-ledger",
        type=pathlib.Path,
        default=pathlib.Path("transformfit-harness/competitive_reverse_engineering.json"),
    )
    parser.add_argument(
        "--coaching-harness",
        type=pathlib.Path,
        default=pathlib.Path("transformfit-harness/coaching_harness.json"),
    )
    parser.add_argument("--repo-root", type=pathlib.Path, default=pathlib.Path("."))
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    try:
        ingestion = _load_json(args.ingestion)
        ledger = _load_json(args.competitive_ledger)
        coaching = _load_json(args.coaching_harness)
        failures = _find_failures(ingestion, ledger, coaching, args.repo_root)
    except Exception as exc:  # noqa: BLE001 - fail closed with useful message.
        failures = [str(exc)]

    result = {
        "schema": "transformfit.ux_ui_research_ingestion_gate.v1",
        "ingestion": str(args.ingestion),
        "competitive_ledger": str(args.competitive_ledger),
        "coaching_harness": str(args.coaching_harness),
        "repo_root": str(args.repo_root),
        "verdict": "GREEN" if not failures else "RED",
        "failures": failures,
    }
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(f"{result['verdict']} ux_ui_research_ingestion_gate: {args.ingestion}")
        for failure in failures:
            print(f"  - {failure}")
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main())
