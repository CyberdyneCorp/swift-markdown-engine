## Context

Refines the continuous Live editor so it reads as rendered, not as Markdown, and adds editing
affordances. App-side only.

## Decisions

### Collapse markers to zero width, reveal on the active line
Marker ranges are tagged during styling (with their base font). `collapseMarkers` sets off-line
markers to a ~0.01pt clear font (zero width, invisible) and on-line markers back to their base
font + a muted color. Re-applied on selection change and after edits. Keeping the markers in the
text storage preserves the source mapping (reconstruction is unchanged).

### Live restyle of the active paragraph
On text change, the cursor's paragraph is re-run through the styler (skipped if it holds a block
attachment), so typed Markdown renders immediately without a full rebuild.

### Toolbar via a controller
`LiveEditorController` holds the UITextView; the SwiftUI toolbar calls `wrap`, `setHeading`, and
`insertBlock`. Inline ops mutate the storage and re-sync; block insert appends source and rebuilds.

## Risks / Trade-offs

- Collapsing via a tiny font is an approximation of true glyph hiding; minor reflow occurs as the
  cursor enters/leaves a line (expected, Typora-like).
- Per-keystroke paragraph restyle is bounded to one paragraph for performance.

## Migration Plan

Additive, app-only; no spec removals.
