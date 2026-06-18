# Roadmap — SwiftMarkdownEngine (iOS / macOS / watchOS)

A phased plan from empty repo to a shippable, fully native Markdown renderer and editor.
Each phase is independently demoable and maps to OpenSpec capabilities under
`openspec/changes/add-markdown-renderer-editor/specs/`.

Legend: 🎯 milestone · ⬜ not started · 🟦 in progress · ✅ done.

> **Status:** Specification complete on `main`. **M0 done** — package builds on iOS,
> macOS, and watchOS; `swift test` green; CI configured. **M1 nearly done** — the
> document model and the CommonMark + GFM + extensions parser are implemented and
> tested. **M2 done** — native SwiftUI renderer, theming, services injection, and
> configuration; builds on iOS/macOS/watchOS. **M3 mostly done** — native Mermaid
> (all 11 types) on Canvas; code-block view done (LaTeX/Highlightr bridges
> network-blocked). **M4 done** — TextKit 2 editor: live styling, toolbar, smart
> lists, indentation, wiki-link completion, spell suppression, Apple Pencil
> double-tap/Scribble on iOS/macOS. **M5 mostly done** — watchOS subset, concurrency
> tests, LazyVStack, device-testing docs. **M3 now complete** — Highlightr code bridge
> and SwiftMath LaTeX bridge implemented and tested; inline math now flows as images.
> **M6 in progress** — DocC catalog, example app done (89 tests). Remaining: XCUITest
> host app (needs an Xcode app project), then 1.0 tag + archive.

---

## Phase 0 — Foundations (package & CI) ✅
**Goal:** the package builds on all three platforms with the test gate wired up.

- ✅ `Package.swift` with products `SwiftMarkdownEngine`, `MarkdownEditor`, `MarkdownEngineCodeBlocks`, `MarkdownEngineLatex`; iOS 17 / macOS 14 / watchOS 10; Swift 6 + strict concurrency.
- 🟦 Add the CommonMark spec suite and GFM example fixtures as test resources _(seed subset + JSON-driven driver in place; full suites pending vendoring)_.
- ✅ CI (GitHub Actions, macOS runner): `openspec validate --all --strict`, `swift test`, and iOS/watchOS builds.

🎯 **M0:** Package compiles for iOS, macOS, and watchOS; tests green. ✅
_Capabilities: `platform-support`_

## Phase 1 — Parser & document model 🟦
**Goal:** turn Markdown into a typed, immutable AST that passes conformance.

- ✅ `Sendable` value-type AST (`Block`, `Inline`, list/table/code nodes) with UTF-8 source ranges, incl. all extension nodes.
- ✅ CommonMark block + inline parsing (headings, lists, quotes, code, links, images, emphasis, escapes).
- ✅ GFM extensions: tables (alignment), task items, strikethrough, extended autolinks.
- ✅ Extension parsing: math, mermaid fences, frontmatter, footnotes, callouts, wiki-links.
- ✅ Malformed-input resilience + deterministic-parse guarantees.
- 🟦 Pass CommonMark + GFM conformance suites; regression test per extension _(28 regression tests green; full spec.json run pending vendoring)_.

🎯 **M1:** Any Markdown string parses to a stable model; conformance suite green.
_Capabilities: `markdown-parsing`_

## Phase 2 — Core rendering & theming ✅
**Goal:** render the parsed model natively in SwiftUI on iOS/macOS.

- ✅ `MarkdownTheme` semantic tokens (light/dark) + per-element styling + environment injection.
- ✅ Service protocols (`SyntaxHighlighter`, `LatexRenderer`, `WikiLinkResolver`, `EmbeddedImageProvider`) with safe defaults.
- ✅ `MarkdownConfiguration` (feature toggles, interactivity, code options, reading width).
- ✅ Recursive block renderer (headings, paragraphs, quotes, rules, lists, task lists, callouts, tables).
- ✅ Inline renderer (emphasis, links, wiki-links, inline code, images, line breaks).
- ✅ GFM table rendering with alignment + horizontal overflow.
- ✅ Image loading via provider (placeholders, alt-text), accessibility, Dynamic Type.

🎯 **M2:** `MarkdownView` renders a full CommonMark+GFM document with theming. ✅
_Capabilities: `document-rendering`, `theming-customization`, `extensibility-services`_

## Phase 3 — Rich content (code · math · Mermaid) 🟦
**Goal:** the differentiators — highlighted code, LaTeX, and native diagrams.

- ✅ Code block view: distinct surface, horizontal scroll, optional line numbers + copy; alias resolution; unknown-language fallback.
- ✅ `MarkdownEngineCodeBlocks` Highlightr bridge (configurable code theme).
- ✅ Inline + block math views; invalid-LaTeX fallback; theme-aware color (inline math flows as images via the LatexRenderer; block centered).
- ✅ `MarkdownEngineLatex` SwiftMath bridge.
- ✅ Mermaid: native Canvas renderers for **all 11 types** (flowchart, sequence, pie, state, class, ER, mindmap, gantt, gitGraph, journey, timeline). Subgraph boxes & self-loop curves are a future refinement.
- ✅ Mermaid inline-style + theme-fallback colors; unsupported-type fallback to highlighted source; overflow scrolling.

🎯 **M3:** Code, LaTeX, and all 11 Mermaid types render natively with graceful fallback. ✅
_Capabilities: `code-syntax-highlighting`, `latex-math-rendering`, `mermaid-diagrams`_

## Phase 4 — Editor (iOS / macOS) ✅
**Goal:** edit Markdown source with live styling and formatting commands.

- ✅ TextKit 2 text view + SwiftUI Representable wrapper with two-way binding.
- ✅ Live syntax styling driven by source ranges (regex-based styler).
- ✅ Formatting commands + toolbar + keyboard shortcuts (bold, italic, strike, code, heading, link, list, task, quote).
- ✅ Smart list continuation, tab/shift-tab indentation, checkbox toggle command.
- ✅ Wiki-link completion via resolver (suggestion overlay).
- ✅ Spelling/grammar suppression for code/math/wiki spans; bottom overscroll + reading column.
- ✅ **Apple Pencil on iPad**: Scribble via UITextView + double-tap via UIPencilInteraction (squeeze/hover preview pending hardware APIs).

🎯 **M4:** `MarkdownEditor` edits Markdown live on iOS and macOS, with Apple Pencil on iPad. ✅
_Capabilities: `markdown-editor`_

## Phase 5 — watchOS subset & hardening 🟦
**Goal:** rendering on the watch and production-quality polish.

- ✅ watchOS render subset (text, lists, tables, code, inline formatting); Mermaid degrades to source.
- ✅ Editor excluded from watchOS; off-main-actor parsing verified under strict concurrency (async tests).
- ✅ Performance: `LazyVStack` off-screen rendering. (Incremental re-style + large-doc profiling: future.)
- 🟦 Accessibility audit across platforms (heading traits, alt text, Dynamic Type in place; full audit pending).
- 🟦 **E2E tests on simulators in CI/CD**: flows specified in `docs/DEVICE_TESTING.md`; XCUITest host app pending an Xcode app project.
- ✅ **On-device iPad + Apple Pencil plan** documented (`docs/DEVICE_TESTING.md`); Scribble + double-tap supported.

🎯 **M5:** Documents render legibly on Apple Watch; engine is concurrency-safe and fast; E2E green on simulators and verified on an iPad with Apple Pencil.
_Capabilities: `platform-support`, `markdown-editor`_

## Phase 6 — Docs, example app & v1.0 🟦
**Goal:** a polished, documented, stable 1.0 release.

- ✅ README feature matrix + DocC catalog for the public API.
- ✅ Example app (`Examples/MarkdownDemo`): rendering + editing on iOS/macOS, rendering on watchOS.
- 🟦 Stabilize the public API surface; semantic-version 1.0 (pending the network-blocked bridges).
- ⬜ Tag `1.0.0`; `openspec archive add-markdown-renderer-editor`.

🎯 **M6 (v1.0):** Documented, example-backed, API-stable release.

---

## Post-1.0 (candidate future changes)

- ⬜ Incremental (range-based) re-parsing for very large documents.
- ⬜ Markdown → HTML / PDF export.
- ⬜ Additional Mermaid diagram types (quadrant, sankey, C4, requirement, etc.).
- ⬜ Default networking image provider with caching.
- ⬜ `AttributedString` convenience for non-SwiftUI hosts.
- ⬜ Writing Tools / system intelligence integration on supported OS versions.

Each post-1.0 item flows through the normal OpenSpec cycle (propose → apply → validate →
archive) as its own change.
