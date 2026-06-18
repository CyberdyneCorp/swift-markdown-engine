# SwiftMarkdownEngine

A complete, **fully native** Markdown renderer and editor for **iOS, macOS, and watchOS** —
CommonMark + GFM plus code highlighting, tables, LaTeX math, and Mermaid diagrams. No
WebView, no JavaScript runtime.

> **Status:** Specified, pre-implementation. The full specification lives in
> [`openspec/`](openspec/changes/add-markdown-renderer-editor/). This README describes the
> engine being built.

---

## Why

Existing options each cover only part of the problem: some render but don't edit, some are
macOS-only, and most lean on a `WKWebView` for math and diagrams. SwiftMarkdownEngine does
all of it natively in one package, so it works offline, runs fast, and reaches the watch.

## Features

| Area | What you get |
|------|--------------|
| **Markdown** | Full CommonMark — headings, lists (nested, tight/loose), block quotes, code, links, images, emphasis |
| **GFM** | Tables with per-column alignment, task lists, strikethrough, autolinks |
| **Code** | Fenced blocks with language-aware syntax highlighting, line numbers, copy button |
| **Math** | Inline `$…$` / `\(…\)` and block `$$…$$` / `\[…\]` LaTeX, rendered with CoreText |
| **Mermaid** | 11 diagram types rendered natively (see below) |
| **Extensions** | Footnotes, callouts/admonitions, wiki-links `[[…]]`, YAML frontmatter |
| **Editor** | TextKit 2 editor with live styling, formatting toolbar, interactive checkboxes (iOS/macOS) |
| **Theming** | Semantic light/dark tokens, full per-element customization |

**Mermaid diagram types:** flowchart · state · sequence · class · ER · pie · gantt ·
git graph · journey · mindmap · timeline. Unsupported syntax falls back to a highlighted
source block instead of failing.

## Platform support

| Platform | Render | Edit |
|----------|:------:|:----:|
| iOS 17+ | ✅ Full | ✅ Full |
| macOS 14+ | ✅ Full | ✅ Full |
| watchOS 10+ | ✅ Subset¹ | — |

¹ watchOS renders text, lists, tables, code, and inline formatting; layout-heavy diagrams
degrade to a simplified view or their source.

---

## Installation

Add the package with Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/CyberdyneCorp/swift-markdown-engine.git", from: "1.0.0")
]
```

Then add the products you need:

```swift
.target(name: "MyApp", dependencies: [
    .product(name: "SwiftMarkdownEngine", package: "swift-markdown-engine"), // core: parse + render + mermaid + theming
    .product(name: "MarkdownEditor",      package: "swift-markdown-engine"), // editor (iOS/macOS)

    // Optional bridges — the core stays dependency-free without them:
    .product(name: "MarkdownEngineCodeBlocks", package: "swift-markdown-engine"), // Highlightr-backed code
    .product(name: "MarkdownEngineLatex",      package: "swift-markdown-engine"), // SwiftMath-backed math
])
```

> The **core has zero external dependencies**. Syntax highlighting (Highlightr) and LaTeX
> (SwiftMath) are opt-in bridge products you only pull in if you use them.

---

## Quick start

### Render Markdown

```swift
import SwiftUI
import SwiftMarkdownEngine

struct ContentView: View {
    var body: some View {
        MarkdownView("""
        # Hello

        Some **bold** text, a `code span`, and inline math $E=mc^2$.

        - [x] Native rendering
        - [ ] No WebView

        ```swift
        print("highlighted")
        ```

        ```mermaid
        flowchart LR
          A[Start] --> B{OK?}
          B -->|yes| C[Done]
        ```
        """)
    }
}
```

### Edit Markdown (iOS / macOS)

```swift
import SwiftUI
import MarkdownEditor

struct EditorScreen: View {
    @State private var text = "# Draft\n\nType **Markdown** here…"

    var body: some View {
        MarkdownEditor(text: $text)
    }
}
```

The editor keeps your buffer as plain Markdown and styles it live — `**bold**` stays
`**bold**` in the text while rendering bold.

---

## Customization

### Theming

```swift
MarkdownView(source)
    .markdownTheme(.dark)            // built-in light / dark
    // or a custom theme:
    .markdownTheme(myTheme)
```

A `MarkdownTheme` exposes semantic tokens (backgrounds, text colors, accents, borders) and
per-element typography. Code, math, and Mermaid all derive their defaults from the active
theme for a cohesive look, and it adapts to light/dark automatically.

### Configuration

```swift
MarkdownView(source)
    .markdownConfiguration(
        MarkdownConfiguration(
            interactiveCheckboxes: true,
            showCodeLineNumbers: true,
            enabledExtensions: [.math, .mermaid, .footnotes, .wikiLinks]
        )
    )
```

### Injecting services

Customize behavior through four protocols — supply your own or skip them for sensible
defaults:

```swift
let services = MarkdownServices(
    syntaxHighlighter: HighlightrHighlighter(theme: "atom-one-dark"), // MarkdownEngineCodeBlocks
    latexRenderer:     SwiftMathRenderer(),                           // MarkdownEngineLatex
    wikiLinkResolver:  myResolver,
    imageProvider:     myImageProvider
)

MarkdownView(source)
    .markdownServices(services)
```

| Protocol | Responsibility | Default |
|----------|----------------|---------|
| `SyntaxHighlighter` | Color code blocks | Plain monospaced |
| `LatexRenderer` | Render math | Raw source |
| `WikiLinkResolver` | Resolve `[[…]]` targets | Plain text |
| `EmbeddedImageProvider` | Load images | Built-in loader |

---

## Architecture

```
Markdown source
      │  parse (CommonMark + GFM + extensions, zero-dependency)
      ▼
MarkdownDocument  ── immutable, Sendable AST with source ranges
      │
      ├── MarkdownView    → native SwiftUI renderer
      │     ├── code   → SyntaxHighlighter service
      │     ├── math   → LatexRenderer service (CoreText)
      │     └── mermaid→ SwiftUI Canvas + layout engine
      │
      └── MarkdownEditor  → TextKit 2 + live styling (iOS/macOS)
```

- **Native everywhere** — SwiftUI `Canvas`, CoreText, and TextKit 2; no WebKit or JS.
- **Zero-dependency core** — heavy integrations live in optional bridge products.
- **Swift 6, strict concurrency** — the document model is a `Sendable` value type, so
  parsing runs safely off the main actor.

---

## Project status & specs

This project is **spec-driven** with [OpenSpec](https://openspec.dev). The complete,
testable specification — parsing, rendering, code, math, Mermaid, editor, theming,
services, and platform support — is in:

```
openspec/changes/add-markdown-renderer-editor/
├── proposal.md     # why + scope
├── design.md       # architecture & decisions
├── tasks.md        # implementation checklist
└── specs/          # 9 capability specs (requirements + scenarios)
```

Browse it with `openspec show add-markdown-renderer-editor` or read the spec files
directly. The phased delivery plan lives in [ROADMAP.md](ROADMAP.md).

## License

[MIT](LICENSE).
