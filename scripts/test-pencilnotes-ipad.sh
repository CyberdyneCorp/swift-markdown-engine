#!/usr/bin/env bash
# Run the PencilNotes UI tests on an iPad: a connected physical iPad if one is available,
# otherwise an iPad simulator. Regenerates the project first so the UITest target is present.
#
# Usage: scripts/test-pencilnotes-ipad.sh
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$repo_root/scripts/generate-pencilnotes.sh" >/dev/null

# --- Find a connected physical iPad (xctrace lists real devices before simulators) ---
phys_udid=$(xcrun xctrace list devices 2>/dev/null \
  | sed -n '1,/== Simulators ==/p' \
  | grep -i 'ipad' \
  | grep -oE '\([0-9A-Fa-f-]{8,}\)$' | tr -d '()' | head -1 || true)

cd "$repo_root"
if [ -n "${phys_udid:-}" ]; then
  echo "▶︎ Running on connected iPad ($phys_udid) — automatic signing"
  xcodebuild test \
    -workspace PencilNotes.xcworkspace \
    -scheme PencilNotes \
    -destination "platform=iOS,id=$phys_udid" \
    -only-testing:PencilNotesUITests
else
  # --- Fall back to an available iPad simulator ---
  sim_udid=$(xcrun simctl list devices available \
    | grep -iE 'ipad' | grep -oE '\([0-9A-F-]{36}\)' | tr -d '()' | head -1 || true)
  if [ -z "${sim_udid:-}" ]; then
    echo "No connected iPad and no iPad simulator available. Install an iPad simulator in Xcode."
    exit 1
  fi
  echo "▶︎ No iPad connected — running on iPad simulator ($sim_udid)"
  xcodebuild test \
    -workspace PencilNotes.xcworkspace \
    -scheme PencilNotes \
    -destination "platform=iOS Simulator,id=$sim_udid" \
    -only-testing:PencilNotesUITests \
    CODE_SIGNING_ALLOWED=NO
fi
