#!/usr/bin/env bash
# Regenerate the PencilNotes example app project.
#
# Run this ONLY when Examples/PencilNotes/project.yml changes (e.g. you add a source
# path or a product). Day-to-day you just open PencilNotes.xcworkspace — the project
# is committed.
#
# Why a wrapper instead of bare `xcodegen`:
# Xcode 16+ will not resolve a local Swift package that is an ancestor of the
# .xcodeproj — it shows a stuck "?" under Package Dependencies. So we let XcodeGen
# generate the project, then STRIP its project-level local-package reference. The
# engine is instead provided by the repo-root PencilNotes.xcworkspace as a workspace
# member, and the app target links the products by name. No ancestor reference => no "?".
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root/Examples/PencilNotes"

command -v xcodegen >/dev/null || { echo "error: xcodegen not found (brew install xcodegen)"; exit 1; }

xcodegen generate
python3 "$repo_root/scripts/strip_local_package_ref.py" \
  "$repo_root/Examples/PencilNotes/PencilNotes.xcodeproj/project.pbxproj"

echo "Done. Open $repo_root/PencilNotes.xcworkspace (NOT the .xcodeproj)."
