#!/usr/bin/env bash
# Run VoiceSplitr unit tests.
# Usage: ./scripts/run-tests.sh [test-name]
# Example: ./scripts/run-tests.sh SplitCalculatorTests
set -euo pipefail

cd "$(dirname "$0")/.."

SCHEME="VoiceSplitr"
DESTINATION="${VOICESPLITR_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17}"

ARGS=(
  -project VoiceSplitr.xcodeproj
  -scheme "$SCHEME"
  -destination "$DESTINATION"
  -only-testing:VoiceSplitrTests
)

if [[ $# -gt 0 ]]; then
  ARGS=(
    -project VoiceSplitr.xcodeproj
    -scheme "$SCHEME"
    -destination "$DESTINATION"
    -only-testing:"VoiceSplitrTests/$1"
  )
fi

if command -v xcbeautify >/dev/null 2>&1; then
  xcodebuild test "${ARGS[@]}" | xcbeautify
else
  xcodebuild test "${ARGS[@]}"
fi
