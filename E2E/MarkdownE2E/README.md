# MarkdownE2E — XCUITest host app

A generated Xcode app + UI-test target that runs end-to-end tests against
`MarkdownView` and `MarkdownEditor` on the iOS simulator. The `.xcodeproj` is
**generated** from `project.yml` (via [XcodeGen](https://github.com/yonaskolb/XcodeGen))
and is git-ignored.

## Run locally

```bash
brew install xcodegen          # once
cd E2E/MarkdownE2E
xcodegen generate
xcodebuild test \
  -project MarkdownE2E.xcodeproj \
  -scheme MarkdownE2E \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO
```

CI runs the same steps (see `.github/workflows/ci.yml`, job `e2e`).

## What it covers

Four flows, green on **iPhone and iPad** simulators (CI runs both):

- **`testRendersComplexDocument`** — renders a document with a heading, GFM table,
  fenced code, inline math, a task list, and a Mermaid flowchart; asserts the heading
  appears.
- **`testEditorToolbarCommandMutatesBuffer`** — types text, taps the **Strikethrough**
  toolbar button, and asserts the buffer gains `~` markers.
- **`testSmartListContinuation`** — types `- a` + Return in the editor and asserts a new
  `- ` marker is inserted (buffer mirrored into a `Text` with identifier `editorMirror`,
  newlines shown as `⏎`).
- **`testWikiLinkCompletion`** — types `[[Pa`, asserts the suggestion overlay appears,
  taps a suggestion, and asserts the target is inserted with `]]`.

The full flow catalog and the on-device Apple Pencil plan live in
[`docs/DEVICE_TESTING.md`](../../docs/DEVICE_TESTING.md). Extend the destination matrix to
Mac as those flows are added.
