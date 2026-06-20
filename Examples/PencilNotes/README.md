# PencilNotes — iPad + Apple Pencil example

An iPad-first example app for SwiftMarkdownEngine that showcases the editor with
**Apple Pencil** next to a live, fully-featured preview. The app's Swift sources live
here in `Examples/PencilNotes/App/`; the Xcode project lives in
`Examples/PencilNotes/PencilNotes.xcodeproj` and is committed. **You open the app through
`PencilNotes.xcworkspace` at the repository root.**

![PencilNotes on iPad](screenshot.png)

## Run

```bash
cd /path/to/swift-markdown-engine     # the REPO ROOT
open PencilNotes.xcworkspace          # then pick your iPad + team and Run ▶
```

That's it — nothing to regenerate; both the workspace and the project are committed.

### Why a workspace (and not just the `.xcodeproj`)

**Xcode 16+ refuses to resolve a local Swift package that is an _ancestor_ of the
`.xcodeproj`** — it silently shows a stuck `?` next to the package under *Package
Dependencies* (Apple's own note:
<https://developer.apple.com/forums/thread/758317>). Because the engine's `Package.swift`
sits at the repo root, it is *always* an ancestor of any in-repo app project, so a normal
`XCLocalSwiftPackageReference` (what `xcodegen` emits) is doomed to the `?`.

The fix is to not reference the package from the project at all. Instead:

- `PencilNotes.xcworkspace` lists **two members**: the engine package (the repo root,
  `self:`) and this app project. The package is a first-class *workspace member*, not a
  project dependency, so the ancestor rule never applies.
- The app target links the engine **products** (`SwiftMarkdownEngine`, `MarkdownEditor`,
  `MarkdownEngineCodeBlocks`, `MarkdownEngineLatex`) by name; the workspace supplies them.
- `scripts/generate-pencilnotes.sh` runs `xcodegen` and then strips the project-level
  local-package reference (`scripts/strip_local_package_ref.py`) so the generated project
  never reintroduces the offending ancestor reference.

> **Only regenerate when you change `Examples/PencilNotes/project.yml`** (e.g. add a
> source path or product). Do it with Xcode closed, then commit the result:
>
> ```bash
> brew install xcodegen                  # once
> cd /path/to/swift-markdown-engine
> scripts/generate-pencilnotes.sh        # xcodegen generate + strip the ancestor ref
> ```
>
> Do **not** run bare `xcodegen` — that re-adds the ancestor package reference and the `?`
> comes back. Also avoid opening `Package.swift` directly in Xcode alongside this app; it
> creates a competing `.swiftpm/xcode/package.xcworkspace` for the same folder.

Command-line build (simulator):

```bash
xcodebuild build -workspace PencilNotes.xcworkspace -scheme PencilNotes \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M4)' CODE_SIGNING_ALLOWED=NO
```

## What it demonstrates

- **Apple Pencil** — Scribble writes/edits text in the `MarkdownEditor` on iPad, and a
  **configured double-tap** toggles bold via `MarkdownEditor(text:onPencilDoubleTap:)`,
  with an on-screen toast confirming the action.
- **Adaptive layout** — side-by-side editor + preview on iPad (regular width); tabbed on
  compact width.
- **Live preview** with the optional bridges injected through `MarkdownServices`:
  - highlighted code (`MarkdownEngineCodeBlocks` → Highlightr),
  - rendered LaTeX (`MarkdownEngineLatex` → SwiftMath),
  - native Mermaid diagrams, GFM tables, and interactive task checkboxes.
- **Theming** — light/dark toggle using a customized `MarkdownTheme` (indigo accent,
  reading-width column).

## Apple Pencil on a real device

Scribble, hover, and squeeze can't be exercised in the simulator or by automated tests —
they need a physical iPad. See [`docs/DEVICE_TESTING.md`](../../docs/DEVICE_TESTING.md)
for the manual on-device checklist.

## App icon

A stylish pencil on an indigo→cyan gradient, in `App/Assets.xcassets/AppIcon.appiconset`.
Regenerate with `python3 AppIconGenerator.py` (requires Pillow).
