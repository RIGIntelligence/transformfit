#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "Building iOS app..."
flutter build ios --release --no-codesign
echo "iOS app built at build/ios/iphoneos/Runner.app"
