#!/bin/bash
# Read-only environment check. Safe to run repeatedly. Never modifies anything.
echo "--- doctor: environment check ---"

if xcode-select -p >/dev/null 2>&1; then
  echo "[ok] Xcode CLI tools: $(xcode-select -p)"
else
  echo "[FAIL] Xcode CLI tools not configured. Run: sudo xcode-select --install"
fi

sim_count=$(xcrun simctl list devices available 2>/dev/null | grep -c "iPhone" || true)
if [ "$sim_count" -gt 0 ]; then
  echo "[ok] iOS simulators available: $sim_count iPhone device(s)"
else
  echo "[FAIL] No available iPhone simulators found. Run: xcodebuild -downloadPlatform iOS"
fi

if gh auth status >/dev/null 2>&1; then
  echo "[ok] gh CLI authenticated"
else
  echo "[FAIL] gh CLI not authenticated. Run: gh auth login"
fi

echo "--- doctor: done ---"
