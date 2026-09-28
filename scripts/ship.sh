#!/bin/bash
set -o pipefail
cd "$(dirname "$0")/.."
pass=1
results=()

echo "--- ship: Moil-iOS-V1 ---"

echo "[1/1] xcodebuild build (scheme: Moil)"
if xcodebuild build -project Moil.xcodeproj -scheme Moil -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO > /tmp/ship-moil-build.log 2>&1; then
  results+=("build: PASS")
else
  results+=("build: FAIL (see /tmp/ship-moil-build.log)")
  pass=0
fi

echo ""
echo "--- ship: results ---"
for r in "${results[@]}"; do echo "$r"; done
[ "$pass" -eq 1 ] && echo "OVERALL: PASS" || { echo "OVERALL: FAIL"; exit 1; }
