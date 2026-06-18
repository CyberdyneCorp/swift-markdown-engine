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

Six flows, green on **iPhone and iPad** simulators (CI runs both). The editor buffer is
mirrored into a `Text` (identifier `editorMirror`) with newlines shown as `⏎` and spaces
as `·`, so assertions are stable across devices (iPhone collapses whitespace in
accessibility labels; iPad does not).

- **`testRendersComplexDocument`** — renders a document with a heading, GFM table,
  fenced code, inline math, a task list, and a Mermaid flowchart; asserts the heading
  appears.
- **`testEditorToolbarCommandMutatesBuffer`** — types text, taps the **Strikethrough**
  toolbar button, asserts the buffer gains `~` markers.
- **`testSmartListContinuation`** — types `- a` + Return, asserts a new `- ` marker
  (`⏎-·`).
- **`testWikiLinkCompletion`** — types `[[Pa`, asserts the suggestion overlay, taps a
  suggestion, asserts the target is inserted (`Page·One]]`).
- **`testCheckboxToggleCommand`** — types a task line, opens the **More** menu, taps
  Toggle checkbox, asserts `[x]`.
- **`testIndentCommand`** — types two lines, opens **More**, taps Indent, asserts the
  second line is indented (`⏎··b`).

Toolbar commands are reliable on both devices because the toolbar fits inline (primary
buttons + a **More** overflow menu) rather than relying on a horizontal `ScrollView`,
whose button taps XCUITest can't reliably trigger on iPad.

The full flow catalog and the on-device Apple Pencil plan live in
[`docs/DEVICE_TESTING.md`](../../docs/DEVICE_TESTING.md). Extend the destination matrix to
Mac as those flows are added.
