#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "Building macOS app..."
flutter build macos --release
echo "macOS app built at build/macos/Build/Products/Release/TransformFit.app"
