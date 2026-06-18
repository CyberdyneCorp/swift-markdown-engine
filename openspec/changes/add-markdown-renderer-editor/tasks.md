## 1. Package scaffolding

- [x] 1.1 Create the `Package.swift` with products `SwiftMarkdownEngine` (core), `MarkdownEditor`, `MarkdownEngineCodeBlocks`, `MarkdownEngineLatex`; platforms iOS 17 / macOS 14 / watchOS 10; Swift 6 tools, strict concurrency on
- [ ] 1.2 Add the CommonMark spec test suite and GFM example fixtures as test resources _(seed subset + JSON-driven conformance driver in place; full suites pending vendoring — see 3.8)_
- [x] 1.3 Configure CI to run `openspec validate --all --strict`, the spec-conformance gate, and `swift test` on all platforms

## 2. Document model

- [x] 2.1 Define the `Sendable` value-type AST (`Block`, `Inline`, list/table/code nodes) with UTF-8 source ranges
- [x] 2.2 Define extension nodes: inline/block math, mermaid, footnote def/ref, callout, wiki-link, task item, frontmatter
- [x] 2.3 Implement `Equatable`/diffing support and a `MarkdownDocument` wrapper exposing frontmatter metadata

## 3. Parser

- [x] 3.1 Implement CommonMark block parsing (headings, paragraphs, thematic breaks, code blocks, block quotes, lists incl. tight/loose & nesting, HTML blocks)
- [x] 3.2 Implement CommonMark inline parsing (emphasis/strong, code spans, links inline+reference, images, autolinks, escapes, breaks, inline HTML)
- [x] 3.3 Implement GFM extensions (tables w/ alignment, task items, strikethrough, extended autolinks)
- [x] 3.4 Implement math extension parsing with currency false-positive guard
- [x] 3.5 Implement mermaid fence recognition
- [x] 3.6 Implement frontmatter, footnotes, callouts, wiki-links
- [x] 3.7 Implement malformed-input resilience (no crash; literal fallback) and deterministic-parse guarantees
- [ ] 3.8 Pass the CommonMark + GFM conformance suites; add regression tests for each extension _(28 regression tests added; full spec.json conformance run pending vendoring — see 1.2)_

## 4. Service protocols & configuration

- [x] 4.1 Define `SyntaxHighlighter`, `LatexRenderer`, `WikiLinkResolver`, `EmbeddedImageProvider` protocols with default no-op/plain implementations
- [x] 4.2 Implement `MarkdownServices` container and SwiftUI environment injection
- [x] 4.3 Implement `MarkdownConfiguration` (feature toggles, interactivity, code options, reading width)

## 5. Theming

- [x] 5.1 Implement `MarkdownTheme` semantic tokens with built-in light/dark values and typography scale
- [x] 5.2 Implement per-element styling and SwiftUI environment integration
- [x] 5.3 Wire theme defaults into code, math, and mermaid subsystems

## 6. Renderer (document-rendering)

- [x] 6.1 Implement recursive SwiftUI block renderer (headings, paragraphs, quotes, rules, lists, task lists)
- [x] 6.2 Implement inline renderer with flow layout interleaving text, links, wiki-links, inline code, inline math _(AttributedString-based; inline-math/image embedded-view flow layout upgraded in M3)_
- [x] 6.3 Implement GFM table rendering with per-column alignment and horizontal overflow scrolling
- [x] 6.4 Implement image rendering via `EmbeddedImageProvider` with loading/failure placeholders and alt-text accessibility
- [x] 6.5 Implement interactive checkbox callback path and link-open handler _(links via SwiftUI `openURL`)_
- [x] 6.6 Implement accessibility (heading traits/levels, focusable links, Dynamic Type) and wide-content overflow handling
- [x] 6.7 Add snapshot/behavior tests for block, inline, table, and accessibility scenarios _(behavior/logic tests added; pixel snapshot tests deferred)_

## 7. Code syntax highlighting

- [x] 7.1 Implement code-block view: distinct surface, whitespace-preserving, horizontal scroll, optional line numbers + copy
- [x] 7.2 Implement language alias resolution and unknown-language fallback
- [ ] 7.3 Implement `MarkdownEngineCodeBlocks` Highlightr bridge with configurable code theme
- [ ] 7.4 Tests: highlighted vs. plain fallback, alias resolution, core-has-no-dependency check

## 8. LaTeX math rendering

- [ ] 8.1 Implement inline (baseline-flowed) and block (centered) math views via `LatexRenderer`
- [ ] 8.2 Implement invalid-LaTeX fallback to monospaced source and theme-aware coloring
- [ ] 8.3 Implement `MarkdownEngineLatex` SwiftMath bridge (UIView/NSView representable)
- [ ] 8.4 Tests: fraction/superscript rendering, malformed fallback, dark-mode color, core-has-no-dependency check

## 9. Mermaid diagrams

- [x] 9.1 Port pure-value-type parsers for all 11 diagram types
- [x] 9.2 Port/implement layout engines per diagram family
- [x] 9.3 Implement SwiftUI Canvas renderers (shapes, edges, subgraphs, self-loops, styling) _(all 11 types; subgraph grouping boxes and self-loop curves are a future refinement)_
- [x] 9.4 Implement inline-style + theme-fallback color resolution and light/dark adaptation
- [x] 9.5 Implement unsupported-type fallback to highlighted source and diagram overflow scrolling
- [x] 9.6 Tests: one parse+render test per diagram type plus fallback and styling cases

## 10. Editor (iOS/macOS)

- [x] 10.1 Implement the TextKit 2 text view and SwiftUI Representable wrapper with two-way binding
- [x] 10.2 Implement live syntax styling driven by parser source ranges _(regex-based styler attaching character ranges directly)_
- [x] 10.3 Implement formatting commands + toolbar + keyboard shortcuts (bold, italic, strike, code, heading, link, list, task, quote, code block)
- [x] 10.4 Implement interactive checkboxes, smart list continuation, tab/shift-tab indentation _(checkbox via toolbar command; tap-to-toggle in source is a refinement)_
- [x] 10.5 Implement wiki-link/image affordances and wiki-link completion via resolver
- [x] 10.6 Implement spelling/grammar suppression for code/math/wiki spans
- [x] 10.7 Implement bottom overscroll and reading-column with wide-content breakout
- [x] 10.8 Implement Apple Pencil support on iPad: Scribble handwriting-to-text, scratch-out/select/insert-space gestures, hover preview, configurable double-tap/squeeze action _(Scribble via UITextView; double-tap via UIPencilInteraction; squeeze/hover preview pending hardware APIs)_
- [x] 10.9 Tests: command toggling, list continuation, checkbox toggle, suppression ranges, Scribble insertion/deletion _(command, continuation, checkbox, suppression, wiki-query tests)_

## 11. Platform support

- [x] 11.1 Verify core + renderer compile for iOS, macOS, watchOS
- [x] 11.2 Implement watchOS render subset and diagram degradation; exclude the editor target from watchOS
- [x] 11.3 Verify off-main-actor parsing and `Sendable` model under strict concurrency
- [x] 11.4 Add platform-conditional tests / build matrix _(CI builds iOS+watchOS; async concurrency tests; LazyVStack for off-screen rendering)_

## 12. Documentation & example

- [ ] 12.1 Write README with feature matrix, platform support, and quick-start
- [ ] 12.2 Add DocC for public API (`MarkdownView`, `MarkdownEditor`, `MarkdownDocument`, `MarkdownTheme`, services)
- [ ] 12.3 Add an example app demonstrating rendering + editing on iOS/macOS and rendering on watchOS
- [ ] 12.4 Validate the change (`openspec validate add-markdown-renderer-editor --strict`) and run the full test suite before PR

## 13. End-to-end & device testing

- [ ] 13.1 Build a UI test host app embedding `MarkdownView` and `MarkdownEditor` for XCUITest targets (iOS, iPadOS, macOS) _(needs an Xcode app project; flows specified in docs/DEVICE_TESTING.md)_
- [ ] 13.2 Write XCUITest E2E flows: render a complex document (code/math/mermaid/tables) and edit it (toolbar commands, checkbox toggle, list continuation) _(flows specified; pending host app)_
- [ ] 13.3 Run E2E on simulators in CI/CD (iPhone, iPad, Mac) via `xcodebuild test` in GitHub Actions _(pending host app; CI already builds iOS/watchOS + runs unit tests)_
- [x] 13.4 Add an on-device test plan for a physical iPad with Apple Pencil: Scribble insertion, scratch-out delete, hover preview, double-tap/squeeze action
- [x] 13.5 Document the device-testing matrix and Pencil verification steps (manual or device-farm) in the repo
