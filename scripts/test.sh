#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/gen.sh
xcodebuild test \
  -project SoundTest.xcodeproj \
  -scheme SoundTest \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' \
  CODE_SIGNING_ALLOWED=NO | tail -40
