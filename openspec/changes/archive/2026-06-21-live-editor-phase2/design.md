## Context

Phase-2 polish for the continuous Live editor. Two changes, both app-side.

## Decisions

### Incremental block rendering with a generation guard
`LiveTextView` builds the attributed string with placeholder attachments (fixed-height), then
renders each block image on subsequent runloop ticks and swaps it into the attachment, calling
`textStorage.edited(.editedAttributes, range:)` to relayout just that range. A monotonically
increasing generation token is captured per rebuild; renders from a stale generation are dropped
so a new rebuild (e.g. external edit) never has old images land.

### Shared BlockEditorView for per-type editing
Extract the WYSIWYG editor's per-block routing into a reusable `BlockEditorView(markdown:theme:)`
that switches on the block kind and shows the right editor. The WYSIWYG editor uses it (behavior
preserved); the Live editor's tap-to-edit sheet uses it too, with a `MarkdownView` preview above.

## Risks / Trade-offs

- Incremental rendering means blocks briefly show placeholders; acceptable and far better than a
  hang. Generation guard prevents stale images.
- Extracting shared routing touches the working WYSIWYG editor; covered by the existing UI suite.

## Migration Plan

Additive, app-only. No spec/behavior removal; the Live editor simply gets faster and edits blocks properly.
