#!/usr/bin/env bash
# Builds the iPhone app (dev flavour, release mode) with the commit and the build
# date recorded from THIS checkout, so Me › Settings › About shows exactly which
# source is installed. Pass extra flutter flags after the script name.
#
#   tool/build_ios.sh
#   tool/build_ios.sh --dart-define=DEV_PREMIUM=true   # owner's Premium test build
#
# Then update in place (never `flutter install`, which uninstalls and wipes data):
#   xcrun devicectl device install app --device <id> build/ios/iphoneos/Runner.app
set -euo pipefail
cd "$(dirname "$0")/.."
sha="$(git rev-parse --short HEAD)"
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then sha="${sha}-dirty"; fi
built="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Building ${sha} at ${built}"
flutter build ios --release --flavor dev \
  --dart-define-from-file=env/dev.json \
  --dart-define=GIT_SHA="${sha}" \
  --dart-define=BUILD_DATE="${built}" \
  "$@"
