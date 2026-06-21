## Why

Phase 1's WYSIWYG editor renders diagrams but edits them as raw Mermaid source. Phase 2
adds **visual builders** so users can author diagrams without writing Mermaid. Building one
per diagram type is an epic, so this change delivers the two highest-value, most tractable
types first; the rest keep the source-with-live-preview editor.

## What Changes

- Add a **visual flowchart builder**: choose a direction (LR/TD/…), add/edit/remove **nodes**
  (id, label, shape) and **edges** (from → to, optional label) through forms; serialize to a
  `flowchart` Mermaid block.
- Add a **visual pie-chart builder**: set a title and add/edit/remove **slices** (label +
  value); serialize to a `pie` Mermaid block.
- Route `flowchart`/`graph` and `pie` blocks in the WYSIWYG editor to these builders; all other
  Mermaid types (sequence, class, state, ER, gantt, gitGraph, journey, mindmap, timeline) keep
  the Phase-1 source editor with live preview.
- The rendered diagram shown above each builder is the live preview.

Out of scope (future): visual builders for the remaining diagram types.

## Capabilities

### New Capabilities
- `visual-diagram-builders`: form-based visual editing for Mermaid flowcharts and pie charts in
  the WYSIWYG editor, serialized to Mermaid source (no syntax shown), with the rendered diagram
  as live preview.

### Modified Capabilities
- None. Extends the PencilNotes WYSIWYG editor (the `wysiwyg-editor` capability) by routing two
  diagram types to visual builders; other types are unchanged.

## Impact

- Code: new builder views in the PencilNotes app (flowchart, pie); routing update in
  `WysiwygEditorView`. No engine changes (reuses the existing Mermaid renderer).
- Dependencies: none new.
- Tests: extend the PencilNotes UI test suite with a diagram-builder case; existing suites
  unaffected.
