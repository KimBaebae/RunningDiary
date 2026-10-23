#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${SIMULATOR_ID:?Set SIMULATOR_ID to an installed simulator UDID (xcrun simctl list devices available)}"
result="${UI_FLOW_RESULT:-/tmp/RunningDiary-UIFlow-$(date +%Y%m%d-%H%M%S).xcresult}"
xcodebuild test -project RunDiary.xcodeproj -scheme RunDiary \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -only-testing:RunDiaryUITests -parallel-testing-enabled NO -collect-test-diagnostics never \
  -resultBundlePath "$result" CODE_SIGNING_ALLOWED=NO "$@"
printf 'UI test results: %s\n' "$result"
