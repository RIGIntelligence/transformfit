#!/usr/bin/env python3
"""Fail-closed gate for TransformFit's wearable + DAI interface slice."""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Iterable


REQUIRED_SOURCE_IDS = {
    "src_apple_healthkit_data_types",
    "src_android_health_connect_overview",
    "src_android_health_connect_sleep",
    "src_flutter_health_package",
}

REQUIRED_WEARABLE_MODEL_TOKENS = {
    "wearableIntegrationSourceIds",
    "class WearableSignal",
    "class WearableReadinessInsight",
    "buildWearableReadinessInsight",
    "WearableSignal.localSample",
    "HealthKit / Health Connect ready",
    "Recovery-biased wearable signal",
    "Ready-biased wearable signal",
    "wearableSignalCopyIsGateSafe",
    "hasUsableSync",
    "permission_needed",
    "sync_unavailable",
    "Wearable permission needed",
    "Wearable sync unavailable",
    "will not infer recovery from missing wearable data",
}

REQUIRED_ADAPTER_TOKENS = {
    "abstract interface class WearableSyncAdapter",
    "class HealthWearableAdapter",
    "implements WearableSyncAdapter",
    "HealthDataType.STEPS",
    "HealthDataType.SLEEP_ASLEEP",
    "HealthDataType.RESTING_HEART_RATE",
    "HealthDataType.HEART_RATE_VARIABILITY_SDNN",
    "HealthDataType.HEART_RATE_VARIABILITY_RMSSD",
    "HealthDataType.ACTIVE_ENERGY_BURNED",
    "HealthDataType.WORKOUT",
    "requestAuthorization",
    "getHealthDataFromTypes",
    "getTotalStepsInInterval",
    "wearableSignalFromHealthData",
    "wearableRecoveryRecordingMethodsToFilter",
    "recordingMethodsToFilter: wearableRecoveryRecordingMethodsToFilter",
    "only user-entered manual points are filtered",
    "hasUsableMetric",
    "syncState: 'unavailable'",
}

REQUIRED_DAI_TOKENS = {
    "class DaiInterface",
    "buildDaiInterface",
    "dai_wearable_connect",
    "dai_wearable_recovery_bias",
    "dai_pain_override",
    "Daily Adaptive Intelligence",
    "daiInterfaceCopyIsGateSafe",
    "Grant wearable permission",
    "No wearable metric changes training",
}

REQUIRED_STATE_TOKENS = {
    "final WearableSignal? wearableSignal",
    "'wearableSignal': wearableSignal?.toJson()",
    "rawWearableSignal",
    "WearableSignal.fromJson",
    "setWearableSignal",
    "clearWearableSignal",
    "wearableSignal: _state.wearableSignal",
}

REQUIRED_PROVIDER_TOKENS = {
    "daiInterfaceProvider",
    "buildDaiInterface",
    "wearableSyncAdapterProvider",
    "HealthWearableAdapter",
}

REQUIRED_TODAY_TOKENS = {
    "_DaiInterfacePanel",
    "DAI interface",
    "DAI command",
    "Wearable status",
    "Readiness modifier",
    "Sync wearable data",
    "Connect wearable",
    "Refresh wearable",
    "Clear wearable",
    "heartRateVariabilityMs",
    "readDailySignal",
}

REQUIRED_TEST_TOKENS = {
    "1000 generated wearable scenarios stay deterministic and safe",
    "defaults to wearable connection workflow without making sync claims",
    "wearable recovery bias changes the DAI command",
    "pending wearable permission stays manual and zero modifier",
    "pending permission does not bias readiness from supplied metrics",
    "unavailable sync does not infer recovery from missing wearable data",
    "pain guardrail overrides wearable ready bias",
    "Today screen syncs HealthWearableAdapter output into DAI",
    "Today screen keeps unavailable adapter output fail-closed",
    "Today screen treats pending wearable permission as manual DAI",
    "adapter filter excludes manual entries without filtering automatic recovery data",
    "isNot(contains(RecordingMethod.automatic))",
    "automatic HealthKit points convert into a synced wearable signal",
    "empty Health data fails closed as unavailable, not synced",
    "wearable signal persists and can feed readiness HRV",
}

REQUIRED_NATIVE_TOKENS = {
    "pubspec": {"health:"},
    "android_manifest": {
        "android.permission.ACTIVITY_RECOGNITION",
        "android.permission.health.READ_ACTIVE_CALORIES_BURNED",
        "android.permission.health.READ_EXERCISE",
        "android.permission.health.READ_HEART_RATE",
        "android.permission.health.READ_HEART_RATE_VARIABILITY",
        "android.permission.health.READ_RESTING_HEART_RATE",
        "android.permission.health.READ_SLEEP",
        "android.permission.health.READ_STEPS",
        "androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE",
        "com.google.android.apps.healthdata",
        "android.intent.action.VIEW_PERMISSION_USAGE",
    },
    "main_activity": {"FlutterFragmentActivity"},
    "gradle_properties": {"android.useAndroidX=true", "android.enableJetifier=true"},
    "ios_info": {"NSHealthShareUsageDescription", "NSHealthUpdateUsageDescription"},
    "ios_entitlements": {"com.apple.developer.healthkit"},
    "xcode_project": {"CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;"},
}

REQUIRED_SHIP_TOKENS = {
    "WEARABLE_DAI_INTERFACE_GATE",
    "wearable_dai_interface_gate",
    "Tier-1 13/27: wearable_dai_interface_gate",
    "WEARABLE_DAI_SOURCES",
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


def _load_json(path: pathlib.Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return {}


def run(repo_root: pathlib.Path) -> dict[str, object]:
    failures: list[str] = []
    paths = {
        "wearable_model": repo_root / "lib/features/wearables/wearable_signal.dart",
        "health_adapter": repo_root / "lib/features/wearables/health_wearable_adapter.dart",
        "dai_interface": repo_root / "lib/features/coaching/dai_interface.dart",
        "controller": repo_root / "lib/features/session/session_controller.dart",
        "providers": repo_root / "lib/app_providers.dart",
        "today": repo_root / "lib/screens/today_screen.dart",
        "wearable_tests": repo_root / "test/features/wearables/wearable_signal_test.dart",
        "health_adapter_tests": repo_root / "test/features/wearables/health_wearable_adapter_test.dart",
        "dai_tests": repo_root / "test/features/coaching/dai_interface_test.dart",
        "session_tests": repo_root / "test/features/session/session_controller_test.dart",
        "today_tests": repo_root / "test/today_screen_test.dart",
        "sources": repo_root / "transformfit-harness/wearable_dai_sources.json",
        "ship_gate": repo_root / "transformfit-harness/ship_gate.sh",
        "bridge": repo_root / "transformfit-harness/bridge.json",
        "war_room": repo_root / "transformfit-harness/two_day_war_room.json",
        "war_room_gate": repo_root / "transformfit-harness/two_day_war_room_gate.py",
        "pubspec": repo_root / "pubspec.yaml",
        "android_manifest": repo_root / "android/app/src/main/AndroidManifest.xml",
        "main_activity": repo_root / "android/app/src/main/kotlin/com/rigintelligence/transformfitai/MainActivity.kt",
        "gradle_properties": repo_root / "android/gradle.properties",
        "ios_info": repo_root / "ios/Runner/Info.plist",
        "ios_entitlements": repo_root / "ios/Runner/Runner.entitlements",
        "xcode_project": repo_root / "ios/Runner.xcodeproj/project.pbxproj",
    }
    text = {name: _read(path) for name, path in paths.items()}

    for name, body in text.items():
        if not body:
            failures.append(f"missing required file: {paths[name]}")

    for token in _missing(text["wearable_model"], REQUIRED_WEARABLE_MODEL_TOKENS):
        failures.append(f"wearable_signal.dart missing token: {token}")
    for token in _missing(text["health_adapter"], REQUIRED_ADAPTER_TOKENS):
        failures.append(f"health_wearable_adapter.dart missing token: {token}")
    if "RecordingMethod.automatic" in text["health_adapter"]:
        failures.append(
            "health_wearable_adapter.dart must not filter automatic wearable data"
        )
    for token in _missing(text["dai_interface"], REQUIRED_DAI_TOKENS):
        failures.append(f"dai_interface.dart missing token: {token}")
    for token in _missing(text["controller"], REQUIRED_STATE_TOKENS):
        failures.append(f"session_controller.dart missing wearable state token: {token}")
    for token in _missing(text["providers"], REQUIRED_PROVIDER_TOKENS):
        failures.append(f"app_providers.dart missing token: {token}")
    for token in _missing(text["today"], REQUIRED_TODAY_TOKENS):
        failures.append(f"today_screen.dart missing DAI UI token: {token}")

    combined_tests = "\n".join(
        [
            text["wearable_tests"],
            text["health_adapter_tests"],
            text["dai_tests"],
            text["session_tests"],
            text["today_tests"],
        ]
    )
    for token in _missing(combined_tests, REQUIRED_TEST_TOKENS):
        failures.append(f"wearable/DAI tests missing token: {token}")

    for name, tokens in REQUIRED_NATIVE_TOKENS.items():
        for token in _missing(text[name], tokens):
            failures.append(f"{name} missing native wearable token: {token}")

    for token in _missing(text["ship_gate"], REQUIRED_SHIP_TOKENS):
        failures.append(f"ship_gate.sh missing wearable/DAI gate token: {token}")
    if "wearable_dai_interface_gate" not in text["bridge"]:
        failures.append("bridge.json missing wearable_dai_interface_gate routing")
    if "wearable_dai_interface_gate" not in text["war_room"]:
        failures.append("two_day_war_room.json missing wearable_dai_interface_gate")
    if '"wearable_dai_interface_gate"' not in text["war_room_gate"]:
        failures.append("two_day_war_room_gate.py missing wearable_dai_interface_gate")
    if "kpi-wearable-dai-interface" not in text["war_room"]:
        failures.append("two_day_war_room.json missing wearable DAI KPI")
    if "wearable_dai_interface" not in text["war_room"]:
        failures.append("two_day_war_room.json missing wearable DAI lane")

    source_data = _load_json(paths["sources"])
    if source_data.get("schema") != "transformfit.wearable_dai_sources.v1":
        failures.append("wearable_dai_sources.json has wrong schema")
    source_ids = {
        item.get("id")
        for item in source_data.get("sources", [])
        if isinstance(item, dict)
    }
    missing_source_ids = REQUIRED_SOURCE_IDS - source_ids
    if missing_source_ids:
        failures.append(f"wearable DAI source sidecar missing IDs: {sorted(missing_source_ids)}")
    for item in source_data.get("sources", []):
        if not isinstance(item, dict):
            failures.append("wearable DAI source entry must be an object")
            continue
        source_id = item.get("id", "<unknown>")
        url = str(item.get("source_url", ""))
        if source_id.startswith("src_apple") and "developer.apple.com" not in url:
            failures.append(f"wearable DAI source {source_id} must cite Apple developer docs")
        if source_id.startswith("src_android") and "developer.android.com" not in url:
            failures.append(f"wearable DAI source {source_id} must cite Android developer docs")
        if source_id == "src_flutter_health_package" and "pub.dev/packages/health" not in url:
            failures.append("Flutter health source must cite pub.dev/packages/health")
        if not item.get("retrieved_at"):
            failures.append(f"wearable DAI source {source_id} missing retrieved_at")
        if not item.get("product_use"):
            failures.append(f"wearable DAI source {source_id} missing product_use")

    quality = json.dumps(source_data.get("wearable_quality_bar", [])).lower()
    for phrase in [
        "same persisted session state",
        "explicit modifier language",
        "opt-in",
        "permission-pending and unavailable snapshots must fail closed",
        "live device sync requires separate hardware proof",
    ]:
        if phrase not in quality:
            failures.append(f"wearable quality bar must include: {phrase}")

    panel = source_data.get("team_panel_proxy", {})
    if panel.get("simulated_users") != 20:
        failures.append("team_panel_proxy must record 20 simulated users")
    for group in [
        "designers",
        "fitness_coaches",
        "ai_engineers",
        "behavioral_science_specialists",
        "privacy_safety_reviewers",
    ]:
        if not isinstance(panel.get(group), int) or panel.get(group, 0) <= 0:
            failures.append(f"team_panel_proxy missing positive count for {group}")
    boundary = str(panel.get("boundary", "")).lower()
    for phrase in ["no outreach", "endorsement", "public claim", "private wearable data export"]:
        if phrase not in boundary:
            failures.append(f"team_panel_proxy boundary must include: {phrase}")

    visible_app_text = text["today"].lower()
    for banned in sorted(APP_BANNED_TERMS):
        if banned in visible_app_text:
            failures.append(f"visible Today wearable/DAI surface contains banned term: {banned}")

    return {
        "schema": "transformfit.wearable_dai_interface_gate.v1",
        "repo_root": str(repo_root),
        "verdict": "GREEN" if not failures else "RED",
        "failures": failures,
        "required_source_ids": sorted(REQUIRED_SOURCE_IDS),
    }


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", default=".", help="TransformFit repo root")
    args = parser.parse_args(argv)

    result = run(pathlib.Path(args.repo_root).resolve())
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if result["verdict"] == "GREEN" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
