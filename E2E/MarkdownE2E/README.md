# MarkdownE2E — XCUITest host app

Generated Xcode app + UI-test targets that run end-to-end tests against
`MarkdownView` and `MarkdownEditor` on **iOS and macOS**. The `.xcodeproj` is
**generated** from `project.yml` (via [XcodeGen](https://github.com/yonaskolb/XcodeGen))
and is git-ignored. There are two schemes: `MarkdownE2E` (iOS) and `MarkdownE2E-mac`.

## Run locally

```bash
brew install xcodegen          # once
cd E2E/MarkdownE2E
xcodegen generate

# iOS (iPhone or iPad simulator)
xcodebuild test -project MarkdownE2E.xcodeproj -scheme MarkdownE2E \
  -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO

# macOS (ad-hoc signed so the UI-test runner can launch)
xcodebuild test -project MarkdownE2E.xcodeproj -scheme MarkdownE2E-mac \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=YES
```

CI runs the same steps (see `.github/workflows/ci.yml`, jobs `e2e` for iPhone/iPad and
`e2e-mac` for macOS).

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

Toolbar commands are reliable because the toolbar fits inline (primary buttons + a
**More** overflow menu) rather than relying on a horizontal `ScrollView`, whose button
taps XCUITest can't reliably trigger on iPad.

### Platform notes

- The UI-test code is cross-platform: it uses `click()` vs `tap()` and `menuItems` vs
  `buttons` per platform, and asserts on `label OR value` (a `Text`'s content is the
  accessibility label on iOS but the value on macOS).
- On **macOS**, `testCheckboxToggleCommand` and `testIndentCommand` are skipped: SwiftUI
  `Menu` items in the overflow menu aren't reliably drivable by XCUITest on macOS. Those
  commands are covered on iOS/iPad and by the `MarkdownEditCommands` unit tests. The other
  four flows (render, toolbar command, list continuation, wiki completion) run on macOS.

The full flow catalog and the on-device Apple Pencil plan live in
[`docs/DEVICE_TESTING.md`](../../docs/DEVICE_TESTING.md). Extend the destination matrix to
Mac as those flows are added.
