## Why

There is no single native Swift package that both **renders** and **edits** the full
Markdown surface — CommonMark + GFM plus code highlighting, tables, LaTeX math, and
Mermaid diagrams — across iOS, macOS, and watchOS without a WebView. Existing options
each cover only part of the problem: `nodes-app/swift-markdown-engine` is a macOS-only
TextKit 2 editor, and our `ios_learning_platform` has excellent native Mermaid/LaTeX
rendering but it is tangled into app code and not reusable. This change introduces a
standalone, reusable engine that consolidates both strengths.

Going fully native (no WebKit/JS runtime) is what makes watchOS rendering, offline use,
and high performance possible — and both reference projects already prove it works.

## What Changes

- Introduce a new Swift Package (`SwiftMarkdownEngine`) targeting iOS 17+, macOS 14+, watchOS 10+.
- **Parsing**: a CommonMark + GFM compliant parser producing a typed, immutable document model (AST), with extension nodes for math, Mermaid, footnotes, callouts/admonitions, wiki-links, task lists, and YAML frontmatter.
- **Rendering**: a native SwiftUI renderer for all block and inline elements (no WebView).
- **Code**: fenced code blocks with native syntax highlighting via an injectable service (optional Highlightr bridge).
- **Math**: inline `$…$` / `\(…\)` and block `$$…$$` / `\[…\]` LaTeX via an injectable service (optional SwiftMath bridge), rendered with CoreText.
- **Mermaid**: native rendering of 11 diagram types (flowchart, state, sequence, class, ER, pie, gantt, git graph, journey, mindmap, timeline) using SwiftUI Canvas + a layout engine; graceful fallback to highlighted source for unrecognized input.
- **Editor**: a TextKit 2 based Markdown editor on iOS + macOS with live syntax styling, formatting toolbar/commands, interactive task checkboxes, and wiki/image affordances. watchOS is **render-only**.
- **Theming**: semantic theme tokens with light/dark and full color/typography customization.
- **Extensibility**: a zero-dependency core with optional bridge products and four service protocols (`SyntaxHighlighter`, `LatexRenderer`, `WikiLinkResolver`, `EmbeddedImageProvider`).
- Establish the platform support matrix (what each platform renders/edits, watchOS subset).

## Capabilities

### New Capabilities

- `markdown-parsing`: Parse CommonMark + GFM + extensions into a typed immutable document model.
- `document-rendering`: Natively render all block and inline Markdown elements in SwiftUI.
- `code-syntax-highlighting`: Render fenced code blocks with language-aware syntax highlighting.
- `latex-math-rendering`: Render inline and block LaTeX math natively (CoreText).
- `mermaid-diagrams`: Natively render Mermaid diagrams (11 types) with fallback.
- `markdown-editor`: Edit Markdown with live styling, toolbar, and interactive elements on iOS/macOS.
- `theming-customization`: Theme and customize rendering and editing appearance.
- `extensibility-services`: Inject custom highlighters, math renderers, link resolvers, and image providers; zero-dep core with optional bridges.
- `platform-support`: Define per-platform capability matrix and watchOS constraints.

### Modified Capabilities

_None — greenfield project; no existing specs._

## Impact

- **New code**: a new SPM package with a zero-dependency core target plus optional bridge targets.
- **Dependencies**: none in core; optional products may depend on Highlightr and SwiftMath.
- **APIs**: public SwiftUI views (`MarkdownView`, `MarkdownEditor`), a `MarkdownDocument` model, `MarkdownTheme`, and service protocols.
- **Platforms**: iOS 17+, macOS 14+, watchOS 10+ (render-only on watchOS).
- **Reference architecture**: parsers and layout from `ios_learning_platform/Kit/Sources/ContentRendering` (value-type, UI-free) and the service-protocol/TextKit 2 design from `nodes-app/swift-markdown-engine`.
