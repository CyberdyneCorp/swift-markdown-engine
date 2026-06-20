## Context

- The engine parses Markdown → `MarkdownDocument` (`[BlockNode]`, each with inline children
  and a `SourceRange`) and renders it via `BlockView`/`MarkdownView`. There is **no**
  model → Markdown path today.
- The existing `MarkdownEditor` (TextKit) edits *raw* Markdown with live syntax styling — the
  syntax stays visible. It is unchanged by this work and remains the "Raw" mode.
- PencilNotes currently shows Raw editor + live Preview. We add a third "Edit" (WYSIWYG) mode.

Constraints: Markdown stays the single source of truth; reuse the existing renderer for block
display; the core stays dependency-free (serializer is pure Swift; visual editors live in the
PencilNotes app and may use the optional Highlightr/SwiftMath bridges already wired there).

## Goals / Non-Goals

Goals (Phase 1): block-based WYSIWYG surface; Markdown serialization with round-trip tests;
visual editors for text (+toolbar), tables, code, image/video, math; insert/reorder/delete;
diagram/chart blocks usable via source-edit-with-live-preview.

Non-Goals (Phase 1): full visual builders for Mermaid/charts; collaborative editing; arbitrary
HTML editing; changing the existing Raw editor.

## Decisions

### Markdown serialization lives in the engine (`MarkdownSerializer`)
Add `Sources/SwiftMarkdownEngine/Serialization/MarkdownSerializer.swift` with public entry
points `MarkdownDocument.markdown()` and `BlockNode.markdown()` / `InlineNode.markdown()`.
Pure functions, no dependencies. This is the foundation that makes visual edits persist and is
independently unit-tested for round-trip fidelity. Rationale: round-tripping is a general
engine capability, not app-specific, and is the riskiest correctness surface — it belongs in
the package with tests, not buried in the app.

### Editor state = ordered editable blocks; Markdown is derived
The WYSIWYG editor holds `[EditableBlock]` (id + the block's Markdown fragment). Rendering uses
the parsed `BlockNode` for each fragment via the existing renderer. Editing a block mutates its
fragment (text edit, table-grid change, etc.); the document's Markdown is the fragments joined
by blank lines and is written back to the same `@Binding<String>` the Raw/Preview modes use, so
all three modes stay in sync. Rationale: avoids a stateful full-document model and keeps the
binding-as-source-of-truth contract; per-block re-parse is cheap.

### Per-type visual editors (PencilNotes app)
A block renders read-only until selected; selecting routes to a type-specific editor:
- Text (paragraph/heading/list/quote/task): inline editable text + a formatting toolbar that
  wraps the selection in Markdown (`**`, `_`, `~~`, `` ` ``, `[]()`) or changes the block
  prefix (`#`, `-`, `1.`, `- [ ]`). Block-type picker converts between text kinds.
- Table: a grid of cell editors with add/remove row/column and per-column alignment control;
  serialized via `BlockNode.markdown()` for the table.
- Code: `TextEditor` + language `Picker`; live highlighted preview via the Highlightr bridge.
- Image/Video: a form (URL/picker + alt/caption) producing `![alt](url)`.
- Math: `TextEditor` for LaTeX + live `MathBlockView` preview.
- Diagram/chart (interim): source `TextEditor` + live `MermaidView` preview.

### Mode switch
PencilNotes gains a 3-way control (Raw | Preview | Edit). Edit binds to the same text. Block
list uses `LazyVStack` in a `ScrollView` for performance.

## Risks / Trade-offs

- **Serializer fidelity** is the main risk: emphasis nesting, list tightness, escaping. Mitigate
  with extensive round-trip tests; accept normalization (e.g. `*`→`_`, reflowed whitespace) as
  long as the re-parsed model is equivalent.
- **SwiftUI inline rich-text editing** is limited; Phase 1 uses focus-to-edit text with a
  Markdown-applying toolbar rather than true character-level live styling. Acceptable and
  shippable; can be upgraded later.
- **Re-parse on each edit**: bounded to the edited block where possible; full-doc re-parse only
  on structural changes. Documents are small in practice.

## Migration Plan

Additive. New public serialization API (no breaking changes); new app-only editor mode. Raw and
Preview modes are untouched. Diagram/chart blocks degrade gracefully to source-edit until their
visual builders ship in Phase 2.

## Open Questions

- Exact normalization guarantees of the serializer (document "equivalent, not byte-identical").
- Whether single-block re-parse needs reference-link/footnote context from the whole document
  (Phase 1: re-parse the whole document for rendering correctness; optimize later).
