#!/usr/bin/env python3
"""Deterministic native iOS/Android setup gate for TransformFit.

This gate proves repository-level mobile setup. It intentionally separates
static app setup from machine-level store-build readiness: pass
--require-toolchain-builds when Android SDK + full Xcode build proof is required.
"""

from __future__ import annotations

import argparse
import json
import plistlib
import re
import struct
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


APP_NAME = "TransformFitAI"
BUNDLE_ID = "com.rigintelligence.transformfitai"
ANDROID_PLAY_MIN_TARGET_SDK = 35
APPLE_APP_STORE_MIN_SDK_MAJOR = 26

ANDROID_DENSITY_SIZES = {
    "mipmap-mdpi/ic_launcher.png": (48, 48),
    "mipmap-hdpi/ic_launcher.png": (72, 72),
    "mipmap-xhdpi/ic_launcher.png": (96, 96),
    "mipmap-xxhdpi/ic_launcher.png": (144, 144),
    "mipmap-xxxhdpi/ic_launcher.png": (192, 192),
}

ANDROID_NS = {"android": "http://schemas.android.com/apk/res/android"}


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def png_size(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) < 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG file")
    width, height = struct.unpack(">II", header[16:24])
    return width, height


def add_failure(failures: list[str], condition: bool, message: str) -> None:
    if not condition:
        failures.append(message)


def parse_flutter_android_sdk_defaults(repo_root: Path) -> dict[str, int | str | None]:
    local_properties = repo_root / "android/local.properties"
    flutter_sdk = None
    if local_properties.exists():
        for line in read(local_properties).splitlines():
            if line.startswith("flutter.sdk="):
                flutter_sdk = line.split("=", 1)[1].strip()
                break

    gradle_utils = (
        Path(flutter_sdk) / "packages/flutter_tools/lib/src/android/gradle_utils.dart"
        if flutter_sdk
        else None
    )
    values: dict[str, int | str | None] = {
        "flutter_sdk": flutter_sdk,
        "compile_sdk": None,
        "target_sdk": None,
        "min_sdk": None,
    }
    if not gradle_utils or not gradle_utils.exists():
        return values

    text = read(gradle_utils)
    patterns = {
        "compile_sdk": r"const compileSdkVersionInt = ([0-9]+);",
        "target_sdk": r"const targetSdkVersion = '([0-9]+)';",
        "min_sdk": r"const minSdkVersionInt = ([0-9]+);",
    }
    for key, pattern in patterns.items():
        match = re.search(pattern, text)
        if match:
            values[key] = int(match.group(1))
    return values


def check_android(repo_root: Path, failures: list[str]) -> dict[str, object]:
    build_gradle = repo_root / "android/app/build.gradle.kts"
    manifest_path = repo_root / "android/app/src/main/AndroidManifest.xml"
    strings_path = repo_root / "android/app/src/main/res/values/strings.xml"
    key_example_path = repo_root / "android/key.properties.example"
    res_root = repo_root / "android/app/src/main/res"
    sdk_defaults = parse_flutter_android_sdk_defaults(repo_root)

    for path in [build_gradle, manifest_path, strings_path, key_example_path]:
        add_failure(failures, path.exists(), f"missing Android file: {path.relative_to(repo_root)}")

    build_text = read(build_gradle) if build_gradle.exists() else ""
    add_failure(
        failures,
        f'namespace = "{BUNDLE_ID}"' in build_text,
        f"Android namespace must be {BUNDLE_ID}",
    )
    add_failure(
        failures,
        f'applicationId = "{BUNDLE_ID}"' in build_text,
        f"Android applicationId must be {BUNDLE_ID}",
    )
    add_failure(
        failures,
        "compileSdk = flutter.compileSdkVersion" in build_text,
        "Android compileSdk must follow the pinned Flutter SDK default",
    )
    add_failure(
        failures,
        "targetSdk = flutter.targetSdkVersion" in build_text,
        "Android targetSdk must follow the pinned Flutter SDK default",
    )
    add_failure(
        failures,
        int(sdk_defaults.get("target_sdk") or 0) >= ANDROID_PLAY_MIN_TARGET_SDK,
        f"Flutter target SDK must be >= API {ANDROID_PLAY_MIN_TARGET_SDK} for current Google Play policy",
    )
    add_failure(
        failures,
        int(sdk_defaults.get("compile_sdk") or 0) >= ANDROID_PLAY_MIN_TARGET_SDK,
        f"Flutter compile SDK must be >= API {ANDROID_PLAY_MIN_TARGET_SDK}",
    )
    add_failure(
        failures,
        "signingConfigs.getByName(\"debug\")" not in build_text,
        "Android release build must not use debug signing",
    )
    add_failure(
        failures,
        "key.properties" in build_text and "hasReleaseSigning" in build_text,
        "Android release signing must be driven by uncommitted key.properties",
    )

    manifest_details: dict[str, object] = {}
    if manifest_path.exists():
        root = ET.parse(manifest_path).getroot()
        permissions = {
            node.attrib.get(f"{{{ANDROID_NS['android']}}}name")
            for node in root.findall("uses-permission")
        }
        manifest_details["permissions"] = sorted(p for p in permissions if p)
        add_failure(
            failures,
            "android.permission.INTERNET" in permissions,
            "Android release manifest must declare INTERNET for Supabase/coaching network access",
        )
        add_failure(
            failures,
            "android.permission.ACCESS_NETWORK_STATE" in permissions,
            "Android release manifest must declare ACCESS_NETWORK_STATE for resilient mobile network UX",
        )
        application = root.find("application")
        add_failure(failures, application is not None, "Android manifest must contain application")
        if application is not None:
            label = application.attrib.get(f"{{{ANDROID_NS['android']}}}label")
            icon = application.attrib.get(f"{{{ANDROID_NS['android']}}}icon")
            add_failure(failures, label == "@string/app_name", "Android app label must use @string/app_name")
            add_failure(failures, icon == "@mipmap/ic_launcher", "Android launcher icon must use @mipmap/ic_launcher")
            activity = application.find("activity")
            add_failure(failures, activity is not None, "Android manifest must contain launcher activity")
            if activity is not None:
                exported = activity.attrib.get(f"{{{ANDROID_NS['android']}}}exported")
                add_failure(failures, exported == "true", "Android launcher activity must be exported=true")
            embedding = application.find("meta-data[@android:name='flutterEmbedding']", ANDROID_NS)
            add_failure(
                failures,
                embedding is not None
                and embedding.attrib.get(f"{{{ANDROID_NS['android']}}}value") == "2",
                "Android manifest must use Flutter embedding v2",
            )

    if strings_path.exists():
        strings_root = ET.parse(strings_path).getroot()
        app_name = None
        for node in strings_root.findall("string"):
            if node.attrib.get("name") == "app_name":
                app_name = node.text
                break
        add_failure(failures, app_name == APP_NAME, f"Android app_name must be {APP_NAME}")

    icon_details = {}
    for rel_path, expected in ANDROID_DENSITY_SIZES.items():
        icon_path = res_root / rel_path
        add_failure(failures, icon_path.exists(), f"missing Android launcher icon: {rel_path}")
        if icon_path.exists():
            actual = png_size(icon_path)
            icon_details[rel_path] = {"expected": expected, "actual": actual}
            add_failure(failures, actual == expected, f"Android launcher icon {rel_path} must be {expected}, got {actual}")

    return {
        "bundle_id": BUNDLE_ID,
        "sdk_defaults": sdk_defaults,
        "manifest": manifest_details,
        "icons": icon_details,
    }


def parse_scale(scale: str) -> float:
    return float(scale.rstrip("x"))


def parse_size(size: str) -> tuple[float, float]:
    width, height = size.split("x")
    return float(width), float(height)


def check_ios(repo_root: Path, failures: list[str]) -> dict[str, object]:
    info_plist = repo_root / "ios/Runner/Info.plist"
    project_file = repo_root / "ios/Runner.xcodeproj/project.pbxproj"
    launch_screen = repo_root / "ios/Runner/Base.lproj/LaunchScreen.storyboard"
    icon_dir = repo_root / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents_json = icon_dir / "Contents.json"

    for path in [info_plist, project_file, launch_screen, contents_json]:
        add_failure(failures, path.exists(), f"missing iOS file: {path.relative_to(repo_root)}")

    plist: dict[str, object] = {}
    if info_plist.exists():
        with info_plist.open("rb") as handle:
            plist = plistlib.load(handle)
        add_failure(failures, plist.get("CFBundleDisplayName") == APP_NAME, f"iOS display name must be {APP_NAME}")
        add_failure(failures, plist.get("CFBundleName") == APP_NAME, f"iOS bundle name must be {APP_NAME}")
        add_failure(
            failures,
            plist.get("CFBundleIdentifier") == "$(PRODUCT_BUNDLE_IDENTIFIER)",
            "iOS Info.plist must use PRODUCT_BUNDLE_IDENTIFIER",
        )
        add_failure(failures, plist.get("UILaunchStoryboardName") == "LaunchScreen", "iOS must use LaunchScreen storyboard")
        add_failure(failures, plist.get("UIMainStoryboardFile") == "Main", "iOS must use Main storyboard")
        add_failure(
            failures,
            plist.get("ITSAppUsesNonExemptEncryption") is False,
            "iOS export-compliance key ITSAppUsesNonExemptEncryption must be false for standard-only encryption posture",
        )
        orientations = set(plist.get("UISupportedInterfaceOrientations", []))
        add_failure(
            failures,
            "UIInterfaceOrientationPortrait" in orientations,
            "iOS phone orientations must include portrait",
        )

    if project_file.exists():
        project_text = read(project_file)
        add_failure(
            failures,
            f"PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID};" in project_text,
            f"iOS PRODUCT_BUNDLE_IDENTIFIER must be {BUNDLE_ID}",
        )
        add_failure(
            failures,
            "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;" in project_text,
            "iOS project must compile AppIcon asset catalog",
        )
        targets = [float(value) for value in re.findall(r"IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);", project_text)]
        add_failure(failures, bool(targets), "iOS deployment target must be declared")
        add_failure(
            failures,
            all(target >= 13.0 for target in targets),
            f"iOS deployment targets must be >= 13.0, got {targets}",
        )

    if launch_screen.exists():
        launch_text = read(launch_screen)
        add_failure(
            failures,
            'red="1" green="1" blue="1"' not in launch_text,
            "iOS launch screen must not flash white behind the black TransformFitAI mark",
        )
        add_failure(
            failures,
            'image="LaunchImage"' in launch_text,
            "iOS launch screen must include the TransformFitAI launch image",
        )

    icon_details: list[dict[str, object]] = []
    if contents_json.exists():
        contents = json.loads(read(contents_json))
        images = contents.get("images", [])
        add_failure(failures, len(images) >= 18, "iOS AppIcon catalog must include iPhone, iPad, and marketing slots")
        marketing = [image for image in images if image.get("idiom") == "ios-marketing"]
        add_failure(failures, bool(marketing), "iOS AppIcon catalog must include ios-marketing icon")
        for image in images:
            filename = image.get("filename")
            if not filename:
                continue
            path = icon_dir / filename
            add_failure(failures, path.exists(), f"missing iOS AppIcon file: {filename}")
            if not path.exists():
                continue
            size = parse_size(image["size"])
            scale = parse_scale(image["scale"])
            expected = (round(size[0] * scale), round(size[1] * scale))
            actual = png_size(path)
            icon_details.append({"filename": filename, "expected": expected, "actual": actual})
            add_failure(failures, actual == expected, f"iOS AppIcon {filename} must be {expected}, got {actual}")

    return {
        "bundle_id": BUNDLE_ID,
        "app_store_sdk_requirement": f"Xcode {APPLE_APP_STORE_MIN_SDK_MAJOR}+ with iOS/iPadOS {APPLE_APP_STORE_MIN_SDK_MAJOR} SDK+",
        "info_plist_keys": sorted(plist.keys()) if plist else [],
        "icons_checked": icon_details,
    }


def check_flutter_metadata(repo_root: Path, failures: list[str]) -> dict[str, object]:
    pubspec = repo_root / "pubspec.yaml"
    brand_asset = repo_root / "assets/brand/transformfitai-logo-original.jpg"
    add_failure(failures, pubspec.exists(), "missing pubspec.yaml")
    add_failure(failures, brand_asset.exists(), "missing original TransformFitAI brand asset")
    metadata: dict[str, object] = {"brand_asset": str(brand_asset.relative_to(repo_root))}
    if pubspec.exists():
        text = read(pubspec)
        add_failure(failures, "version: 1.0.0+1" in text, "pubspec must declare version 1.0.0+1")
        add_failure(
            failures,
            "- assets/brand/transformfitai-logo-original.jpg" in text,
            "pubspec must register original TransformFitAI brand asset",
        )
        metadata["version"] = "1.0.0+1" if "version: 1.0.0+1" in text else None
    return metadata


def check_toolchain(repo_root: Path) -> dict[str, object]:
    try:
        completed = subprocess.run(
            ["flutter", "doctor", "-v"],
            cwd=repo_root,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=60,
            check=False,
        )
        output = completed.stdout
    except Exception as exc:  # pragma: no cover - fail-closed runtime evidence.
        return {"required": True, "verdict": "RED", "error": str(exc)}

    return {
        "required": True,
        "verdict": "GREEN" if "[✓] Android toolchain" in output and "[✓] Xcode" in output else "RED",
        "android_toolchain_green": "[✓] Android toolchain" in output,
        "xcode_green": "[✓] Xcode" in output,
        "returncode": completed.returncode,
    }


def run(repo_root: Path, require_toolchain_builds: bool) -> dict[str, object]:
    failures: list[str] = []
    result: dict[str, object] = {
        "schema": "transformfit.native_mobile_setup_gate.v1",
        "repo_root": str(repo_root),
        "android_policy_floor": {
            "source": "developer.android.com/google/play/requirements/target-sdk",
            "new_apps_and_updates": f"target Android 15 / API {ANDROID_PLAY_MIN_TARGET_SDK}+",
        },
        "apple_policy_floor": {
            "source": "developer.apple.com/app-store/submitting/",
            "app_store_uploads": f"Xcode {APPLE_APP_STORE_MIN_SDK_MAJOR}+ with iOS/iPadOS {APPLE_APP_STORE_MIN_SDK_MAJOR} SDK+",
        },
    }
    result["flutter"] = check_flutter_metadata(repo_root, failures)
    result["android"] = check_android(repo_root, failures)
    result["ios"] = check_ios(repo_root, failures)
    if require_toolchain_builds:
        toolchain = check_toolchain(repo_root)
        result["toolchain"] = toolchain
        if toolchain.get("verdict") != "GREEN":
            failures.append("local Android SDK and full Xcode toolchains must be GREEN for native store-build proof")
    else:
        result["toolchain"] = {
            "required": False,
            "note": "static repository setup mode; pass --require-toolchain-builds for device/store-build readiness",
        }

    result["failures"] = failures
    result["verdict"] = "GREEN" if not failures else "RED"
    return result


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", default=".", help="TransformFit Flutter repo root")
    parser.add_argument("--require-toolchain-builds", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)

    repo_root = Path(args.repo_root).resolve()
    result = run(repo_root, args.require_toolchain_builds)
    if args.json:
        print(json.dumps(result, indent=2))
    elif result["verdict"] == "GREEN":
        print(f"GREEN native_mobile_setup_gate: {repo_root}")
    else:
        print(f"RED native_mobile_setup_gate: {repo_root}", file=sys.stderr)
        for failure in result["failures"]:
            print(f"  - {failure}", file=sys.stderr)
    return 0 if result["verdict"] == "GREEN" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
