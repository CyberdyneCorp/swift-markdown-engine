## Context

WYSIWYG blocks render via the engine's Mermaid renderer; Phase 1 edits diagram source in a
text editor. Phase 2 adds visual builders for the two most common, most form-friendly types
(flowchart, pie) while leaving the rest on source-edit. No engine changes — builders produce
Mermaid source that the existing parser/renderer already handles.

## Goals / Non-Goals

Goals: form-based flowchart and pie builders in PencilNotes; round-trip (parse existing source
into the builder model, edit, serialize back); rendered diagram as live preview.

Non-Goals: freeform drag-canvas editing; builders for the other nine diagram types; engine
changes.

## Decisions

### Decompose via the engine's existing diagram parsers
The builders reuse the engine's `Flowchart.parse` / `PieChart.parse` models to populate their
forms from existing source, then serialize a fresh model back to Mermaid. This avoids a second
parser and keeps the visual model in sync with what actually renders. (Those parser types are
internal to the engine; the builders re-derive an equivalent editable model from the source
string to stay app-side — see Risks.)

### App-side editable models + serializers
Each builder holds a small editable model:
- Flowchart: `direction`, `[Node{id,label,shape}]`, `[Edge{from,to,label}]`.
- Pie: `title`, `[Slice{label,value}]`.
Serialization is a plain string build: `flowchart <dir>` + `id<shape-open>label<shape-close>`
lines + `A -->|label| B` lines; `pie title …` + `"label" : value` lines. Decomposition parses
the source string app-side (lightweight line parsing mirroring the engine's grammar).

### Routing
`WysiwygEditorView.blockKind` adds `.flowchart` and `.pie` for `mermaid` blocks whose first
keyword is `flowchart`/`graph` or `pie`; everything else stays `.diagram` (source editor).

## Risks / Trade-offs

- The engine's diagram parser types are internal, so the app re-parses the source with a small,
  grammar-matching parser. Risk: drift from the engine grammar. Mitigation: keep the builders'
  parsing minimal and aligned to the documented syntax; the rendered preview reveals mismatches
  immediately.
- Form-based (not drag-canvas) editing is less fluid for large graphs but is robust and
  shippable; a canvas can come later.

## Migration Plan

Additive, app-only. Selecting a flowchart/pie block now opens a builder instead of the source
editor; the underlying Markdown/Mermaid is unchanged in shape.
