## Context

This is a greenfield Swift Package. The goal is one reusable engine that both renders and
edits the full Markdown surface across Apple platforms, with no WebView. Two existing
projects inform the design:

- `ios_learning_platform/Kit/Sources/ContentRendering` — proven, fully native renderers:
  a Markdown segmenter, GFM table parser, inline-math tokenizer, 11 Mermaid parsers +
  SwiftUI Canvas renderers, a Highlightr-backed code view, and a SwiftMath-backed math
  view. Its parsers are value-type and UI-free, hence highly portable.
- `nodes-app/swift-markdown-engine` — a TextKit 2 macOS editor with a zero-dependency core
  and four service protocols (`WikiLinkResolver`, `EmbeddedImageProvider`,
  `SyntaxHighlighter`, `LatexRenderer`) plus optional bridge products.

This design merges the rendering depth of the former with the editor architecture and
dependency hygiene of the latter, and extends both to iOS/macOS/watchOS.

## Goals / Non-Goals

**Goals:**
- A single SPM package: CommonMark + GFM + extensions, parse → model → render, plus an editor.
- Fully native rendering (SwiftUI Canvas / CoreText / TextKit 2); no WebKit or JS runtime.
- Zero-dependency core; optional Highlightr and SwiftMath bridges behind service protocols.
- Rendering on iOS/macOS/watchOS; editor on iOS/macOS; watchOS render-only.
- Swift 6 strict concurrency; `Sendable` value-type document model.

**Non-Goals:**
- Full WYSIWYG rich-text editing — the editor edits Markdown source with live styling, not a hidden representation.
- 100% pixel parity with mermaid.js / KaTeX; we target faithful native rendering with graceful fallback.
- Markdown → HTML/PDF export (a possible later change).
- watchOS editing.
- A networking/image-cache stack beyond a default `EmbeddedImageProvider` (consumers can inject their own).

## Decisions

### Parser: own CommonMark+GFM parser vs. reuse
**Decision:** Build a self-contained parser producing a typed, immutable, `Sendable` model
with source ranges, rather than depending on `apple/swift-markdown` (which wraps cmark and
adds a C dependency) so the core stays dependency-free and gives us the extension hooks
(math, mermaid, wiki-links, callouts, frontmatter) and source ranges the editor needs.
**Alternative considered:** depend on `swift-markdown` — rejected to preserve the
zero-dependency core and full control over extensions and incremental editing.

### Document model
**Decision:** An enum/struct AST of value types (`Block`, `Inline`, extension nodes), each
carrying its UTF-8 source range; the whole tree is `Sendable`. This enables off-main-actor
parsing, deterministic equality for diffing, and editor mapping between source and render.

### Rendering: SwiftUI, native
**Decision:** A recursive SwiftUI renderer walking the model. Prose uses native `Text`
composition; mixed inline math/links use a flow-layout that interleaves `Text` runs with
formula/inline views. Mermaid uses SwiftUI `Canvas` + a pure layout engine. Code uses the
`SyntaxHighlighter` service → `AttributedString`. Math uses the `LatexRenderer` service →
a platform view via `UIViewRepresentable`/`NSViewRepresentable`.
**Alternative considered:** render to `NSAttributedString`/TextKit for the read view too —
rejected; SwiftUI composition is simpler and unifies iOS/macOS/watchOS.

### Editor: TextKit 2 bridged to SwiftUI
**Decision:** Follow nodes-app — a TextKit 2 text view (UIKit `UITextView` / AppKit
`NSTextView` over `NSTextLayoutManager`) wrapped via Representable, applying live attribute
styling driven by the parser's source ranges. This keeps the buffer as plain Markdown while
styling it, supports large documents, and gives us spelling/grammar suppression by range.
**Alternative considered:** a pure-SwiftUI `TextEditor` — rejected; insufficient control
over per-range styling, layout, and interaction.

### Mermaid layout engine
**Decision:** Port the learning platform's per-type parsers and layout engines (flowchart,
state, sequence, class, ER, pie, gantt, git graph, journey, mindmap, timeline) as pure
value-type code, with a thin Canvas renderer per family. Unknown types fall back to a
highlighted code block.

### Dependency packaging
**Decision:** SPM products: `SwiftMarkdownEngine` (core: parser, model, renderer, mermaid,
theming, services), `MarkdownEditor` (editor, iOS/macOS), `MarkdownEngineCodeBlocks`
(Highlightr bridge), `MarkdownEngineLatex` (SwiftMath bridge). Core depends on neither
bridge.

### watchOS subset
**Decision:** The renderer compiles everywhere; on watchOS the editor target and
layout-heavy diagram paths are excluded via availability/conditional compilation, with
diagrams degrading to simplified output or source.

## Risks / Trade-offs

- **Reimplementing CommonMark is error-prone** → validate against the CommonMark spec test
  suite and GFM examples in CI; treat the spec suite as a gate.
- **Mermaid surface is huge; we cover 11 types** → explicit graceful fallback to source;
  document the supported subset; expand by future changes.
- **LaTeX/code via JS-backed bridges (SwiftMath is native; Highlightr uses JavaScriptCore)**
  → core stays free of them; Highlightr's JSCore cost is opt-in and absent on watchOS.
- **TextKit 2 maturity differences across OS versions** → gate advanced editor features
  (e.g. Writing Tools) by OS version; keep a baseline that works on the stated minimums.
- **Performance on large documents** → off-main-actor parsing, immutable model for cheap
  diffing, lazy rendering of off-screen blocks, and incremental re-style in the editor.
- **Strict concurrency friction** → model and theme are `Sendable` value types from day one.

## Migration Plan

Greenfield — no migration. Rollout: (1) package skeleton + targets; (2) parser + model
behind the CommonMark/GFM test gate; (3) renderer; (4) code/math/mermaid subsystems +
bridges; (5) editor; (6) watchOS subset; (7) docs + example app. Each is independently
shippable behind the public API.

## Open Questions

- Should incremental (range-based) re-parsing land in v1, or full re-parse with debounce first?
- Default `EmbeddedImageProvider` — bundle a minimal `URLSession` loader in core, or require injection?
- Do we want a Markdown→AttributedString convenience for non-SwiftUI hosts in v1?
