## Context

A continuous Typora-style editor over Markdown. Native SwiftUI has no primitive for mixing
editable continuous text with inline-rendered, interactive block views, so this uses TextKit 2
(`UITextView` + `NSTextAttachmentViewProvider`). Markdown is the source of truth.

## Decisions

### TextKit 2 UITextView via UIViewRepresentable
A `UITextView` (TextKit 2) hosts the document. Its attributed string is built from the parsed
blocks: text blocks become live-styled attributed text; block elements become a custom
`NSTextAttachment` whose `NSTextAttachmentViewProvider` hosts a SwiftUI `MarkdownView` for that
block. Each block attachment carries its Markdown source so the document can be reconstructed.

### Reveal-on-active-line
Markers are styled dim (faded, via foreground color) on inactive lines and full on the
paragraph containing the selection. Re-applied on selection change. (True glyph-hiding is a
Phase-2 refinement; Phase 1 uses dimming + active-line reveal.)

### Reconstruct Markdown from storage
`currentMarkdown()` walks the attributed string: text runs emit their characters; block
attachments emit their stored source. The result is written to the shared `@Binding<String>`,
debounced, so Raw/Preview/Edit stay in sync.

### Block editing via existing editors (Phase 1)
Tapping an inline block opens the matching per-type editor (text/table/code/math/diagram/builder)
in a sheet; on save the block's source updates and the surface rebuilds. In-place block editing
is deferred to Phase 2.

## Risks / Trade-offs

- Cursor/selection behavior around attachments, undo, and live re-layout are the hard parts;
  Phase 1 rebuilds on commit/debounce rather than per-keystroke to stay robust.
- Performance with many inline rendered blocks; mitigate by reusing the renderer and rebuilding
  lazily.
- Cannot be fully verified without on-device iteration; shipped as Phase 1 with a smoke test.

## Migration Plan

Additive, app-only — a new mode alongside the existing three. No engine changes.
