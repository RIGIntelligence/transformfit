#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "Building all platforms..."
flutter build web
echo "Web: build/web"
flutter build apk --debug
echo "Android: build/app/outputs/flutter-apk/app-debug.apk"
flutter build macos --release 2>/dev/null || echo "macOS: skipped (Xcode not installed)"
flutter build ios --release --no-codesign 2>/dev/null || echo "iOS: skipped (Xcode not installed)"
echo "Done!"
