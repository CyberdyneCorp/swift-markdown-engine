# MarkdownDemo example

Sample app showing SwiftMarkdownEngine on iOS, macOS, and watchOS. These files are
**not** built by the Swift package — they are reference source you drop into an Xcode
app target.

## Run it

1. In Xcode: **File ▸ New ▸ Project ▸ Multiplatform ▸ App**, name it `MarkdownDemo`.
2. **File ▸ Add Package Dependencies…** and add this repository
   (`https://github.com/CyberdyneCorp/swift-markdown-engine.git`).
3. Link products per target:
   - iOS & macOS targets: `SwiftMarkdownEngine` **and** `MarkdownEditor`
   - watchOS target: `SwiftMarkdownEngine` only (the editor is unavailable on watchOS)
4. Replace the generated `App.swift` with `MarkdownDemoApp.swift` from this folder.
5. Build & run.

## What it demonstrates

- **`ReaderView`** (all platforms): `MarkdownView` rendering headings, a GFM table,
  a task list with interactive checkboxes, inline + block LaTeX, a Mermaid flowchart,
  and a highlighted code block.
- **`SplitDemoView`** (iOS/macOS): a live `MarkdownEditor` beside a `MarkdownView`
  preview that updates as you type.

## Optional integrations

Inject the optional bridges to enable real syntax highlighting and LaTeX:

```swift
let services = MarkdownServices(
    syntaxHighlighter: /* MarkdownEngineCodeBlocks bridge */ nil,
    latexRenderer:     /* MarkdownEngineLatex bridge */ nil
)

MarkdownView(text).markdownServices(services)
```
