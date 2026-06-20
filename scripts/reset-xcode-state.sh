#!/usr/bin/env bash
# Cold-start the PencilNotes workspace: clear every piece of Xcode/SwiftPM state that
# can pin a stale or conflicting view of the local engine package, then you reopen
# the workspace fresh.
#
# RUN THIS WITH XCODE FULLY QUIT (Cmd-Q, not just closing the window) — otherwise the
# live session rewrites the caches as you delete them.
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if pgrep -xq Xcode; then
  echo "Xcode is still running. Quit it (Cmd-Q) and re-run this script."
  exit 1
fi

echo "• Removing PencilNotes + standalone-package DerivedData…"
rm -rf ~/Library/Developer/Xcode/DerivedData/PencilNotes-* \
       ~/Library/Developer/Xcode/DerivedData/swift-markdown-engine-* \
       ~/Library/Developer/Xcode/DerivedData/MarkdownE2E-*

echo "• Removing the package's stray standalone workspace (.swiftpm)…"
rm -rf "$repo_root/.swiftpm"

echo "• Clearing Xcode saved window state (stops it restoring a broken session)…"
rm -rf ~/Library/Saved\ Application\ State/com.apple.dt.Xcode.savedState

echo
echo "Done. Now open ONLY the workspace — never Package.swift, never the .xcodeproj:"
echo "    open \"$repo_root/PencilNotes.xcworkspace\""
