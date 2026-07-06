#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="TransformFitAI"
BUNDLE_ID="com.rigintelligence.transformfitai"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEX_ROOT="/Users/rig128gb/Documents/Codex/2026-07-01/full-sprint-complete-all-four-repos"
OUTPUT_ROOT="$CODEX_ROOT/outputs/TransformFit Native"
MAC_STAGE="$OUTPUT_ROOT/TransformFitAI Native.app"
IOS_STAGE="$OUTPUT_ROOT/TransformFitAI iOS Simulator.app"
STATUS_JSON="$OUTPUT_ROOT/native-build-status.json"

cd "$ROOT_DIR"
mkdir -p "$OUTPUT_ROOT"

json_escape() {
  /usr/bin/python3 -c 'import json,sys; print(json.dumps(sys.stdin.read())[1:-1])'
}

write_status() {
  local verdict="$1"
  local phase="$2"
  local detail="$3"
  local escaped_detail
  escaped_detail="$(printf '%s' "$detail" | json_escape)"
  local temp_status="$STATUS_JSON.$$"
  cat >"$temp_status" <<JSON
{
  "schemaVersion": "transformfit.nativeBuild.status.v1",
  "generatedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "verdict": "$verdict",
  "phase": "$phase",
  "detail": "$escaped_detail",
  "repo": "$ROOT_DIR",
  "macStage": "$MAC_STAGE",
  "iosSimulatorStage": "$IOS_STAGE",
  "bundleId": "$BUNDLE_ID",
  "externalActions": "local Flutter/Xcode build only; no signing-provider writes, pushes, deploys, sends, paid jobs, or credential changes"
}
JSON
  /bin/mv "$temp_status" "$STATUS_JSON"
}

developer_dir() {
  if [ -n "${DEVELOPER_DIR:-}" ] && [ -x "$DEVELOPER_DIR/usr/bin/xcodebuild" ]; then
    printf '%s\n' "$DEVELOPER_DIR"
    return 0
  fi
  if [ -x "/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild" ]; then
    printf '%s\n' "/Applications/Xcode.app/Contents/Developer"
    return 0
  fi
  return 1
}

require_xcode() {
  local dir
  if ! dir="$(developer_dir)"; then
    write_status "BLOCKED" "toolchain" "Full Xcode is not installed. Install Xcode.app or run with DEVELOPER_DIR pointing at a full Xcode developer directory."
    cat >&2 <<'EOF'
TransformFit native build requires full Xcode.

Current machine has Command Line Tools but no full Xcode.app developer directory.
Install Xcode.app, or run with:
  DEVELOPER_DIR=/path/to/Xcode.app/Contents/Developer ./script/build_and_run.sh
EOF
    return 64
  fi
  export DEVELOPER_DIR="$dir"
}

stop_app() {
  /usr/bin/pkill -x "$APP_NAME" >/dev/null 2>&1 || true
}

build_macos() {
  require_xcode
  flutter pub get
  flutter build macos --release
}

stage_macos() {
  local built_app="$ROOT_DIR/build/macos/Build/Products/Release/$APP_NAME.app"
  if [ ! -d "$built_app" ]; then
    write_status "FAIL" "stage-macos" "Missing built macOS app at $built_app"
    echo "Missing built macOS app: $built_app" >&2
    return 65
  fi
  /bin/rm -rf "$MAC_STAGE"
  /bin/cp -R "$built_app" "$MAC_STAGE"
}

build_ios_simulator() {
  require_xcode
  flutter pub get
  flutter build ios --simulator --debug
}

stage_ios_simulator() {
  local built_app="$ROOT_DIR/build/ios/iphonesimulator/Runner.app"
  if [ ! -d "$built_app" ]; then
    write_status "FAIL" "stage-ios-simulator" "Missing built iOS simulator app at $built_app"
    echo "Missing built iOS simulator app: $built_app" >&2
    return 66
  fi
  /bin/rm -rf "$IOS_STAGE"
  /bin/cp -R "$built_app" "$IOS_STAGE"
}

verify_staged() {
  local failures=0
  local present=0
  if [ -d "$MAC_STAGE" ]; then
    present=$((present + 1))
    /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$MAC_STAGE/Contents/Info.plist" | /usr/bin/grep -qx "$BUNDLE_ID" || failures=$((failures + 1))
    /usr/libexec/PlistBuddy -c 'Print :CFBundleName' "$MAC_STAGE/Contents/Info.plist" | /usr/bin/grep -qx "$APP_NAME" || failures=$((failures + 1))
  fi
  if [ -d "$IOS_STAGE" ]; then
    present=$((present + 1))
    /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$IOS_STAGE/Info.plist" | /usr/bin/grep -qx "$BUNDLE_ID" || failures=$((failures + 1))
    /usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$IOS_STAGE/Info.plist" | /usr/bin/grep -qx "$APP_NAME" || failures=$((failures + 1))
  fi
  if [ "$present" -eq 0 ]; then
    write_status "FAIL" "verify" "No staged native artifacts exist yet"
    return 68
  fi
  if [ "$failures" -gt 0 ]; then
    write_status "FAIL" "verify" "$failures staged native artifact metadata checks failed"
    return 67
  fi
  write_status "PASS" "verify" "Native staged artifact metadata checks passed"
}

launch_macos() {
  stage_macos
  /usr/bin/open -n "$MAC_STAGE"
}

doctor() {
  local xcode_status="missing"
  local xcode_version=""
  if require_xcode >/dev/null 2>&1; then
    xcode_status="present"
    xcode_version="$(xcodebuild -version | tr '\n' ' ')"
  fi
  local flutter_version
  flutter_version="$(flutter --version | head -1)"
  local detail="xcode=$xcode_status; $xcode_version; $flutter_version"
  if [ "$xcode_status" = "present" ]; then
    write_status "READY" "doctor" "$detail"
    printf '%s\n' "$detail"
  else
    write_status "BLOCKED" "doctor" "$detail"
    printf '%s\n' "$detail"
    return 64
  fi
}

usage() {
  cat <<EOF
usage: $0 [run|--macos|--ios-simulator|--all|--stage|--verify|--doctor|--logs]

run             Build, stage, and launch native macOS TransformFitAI.
--macos         Build and stage native macOS TransformFitAI.
--ios-simulator Build and stage the iOS Simulator app.
--all           Build and stage both native macOS and iOS Simulator apps.
--stage         Stage already-built native artifacts into outputs.
--verify        Verify staged native artifact metadata.
--doctor        Check local native-build prerequisites without building.
--logs          Stream macOS logs for TransformFitAI after launch.
EOF
}

case "$MODE" in
  run|--run)
    stop_app
    build_macos
    launch_macos
    write_status "PASS" "run" "macOS app built, staged, and launched"
    ;;
  --macos|macos)
    stop_app
    build_macos
    stage_macos
    write_status "PASS" "macos" "macOS app built and staged"
    ;;
  --ios-simulator|ios-simulator)
    build_ios_simulator
    stage_ios_simulator
    write_status "PASS" "ios-simulator" "iOS Simulator app built and staged"
    ;;
  --all|all)
    stop_app
    build_macos
    stage_macos
    build_ios_simulator
    stage_ios_simulator
    verify_staged
    ;;
  --stage|stage)
    stage_macos || true
    stage_ios_simulator || true
    verify_staged
    ;;
  --verify|verify)
    verify_staged
    ;;
  --doctor|doctor)
    doctor
    ;;
  --logs|logs)
    stop_app
    build_macos
    launch_macos
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --help|help|-h)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
