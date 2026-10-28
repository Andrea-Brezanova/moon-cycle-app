#!/usr/bin/env bash
# Everything CI checks, run locally before pushing, so a PR goes green the first time.
# The goldens match CI's macOS 15 runner, so differences found here are real; after an
# intentional visual change record them with `tool/precheck.sh --update-goldens`.
#
#   tool/precheck.sh                  # format, analyze, layers, all tests, all goldens
#   tool/precheck.sh --update-goldens # re-record goldens first, then run everything
set -euo pipefail
cd "$(dirname "$0")/.."
if [ "${1:-}" = "--update-goldens" ]; then
  flutter test --tags golden --update-goldens
fi
dart format --output=none --set-exit-if-changed .
flutter analyze
dart run tool/check_layers.dart
flutter test --exclude-tags golden
flutter test --tags golden
echo "precheck passed: safe to push."
