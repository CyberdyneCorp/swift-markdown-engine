## Context

Extends the visual-diagram-builders capability. Each builder decomposes a block's Mermaid
source into an editable model and serializes a fresh model back to a ```mermaid block; the
rendered diagram above is the live preview. No engine changes (reuses existing parsers/renderers).

## Decisions

- App-side editable models + lightweight source parsing mirroring each diagram's grammar, same
  pattern as the existing flowchart/pie/sequence/mindmap/gantt builders.
- Relationship/cardinality and operation types are exposed via pickers so users never type syntax.
- Routing in `WysiwygEditorView.blockKind` maps each Mermaid header keyword to its builder.

## Risks / Trade-offs

- Lightweight parsers can drift from the engine grammar on unusual input; the live preview
  surfaces mismatches immediately. Builders cover the common syntax for each type.

## Migration Plan

Additive, app-only. Selecting one of these six blocks now opens a builder instead of the source editor.
