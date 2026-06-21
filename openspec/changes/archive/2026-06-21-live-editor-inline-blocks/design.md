## Context

Fixes the Live editor so rich blocks actually render. Replaces the static snapshot approach
with live inline views. App-side only.

## Decisions

- **TextKit 2 attachment view providers**: `BlockAttachment` returns a `BlockViewProvider` that
  hosts a SwiftUI `MarkdownView` for the block. The hosting view has user interaction disabled
  so a tap falls through to the text view's block-tap handler (opens the per-type editor sheet).
  Attachment bounds come from `systemLayoutSizeFitting` at the container width.
- **Lists render as blocks**: `isTextBlock` no longer returns true for lists, so checklists/lists
  render via the view provider (checkboxes visible) and are edited via the list editor on tap.
- **Complete Insert menu** mirroring the block editor plus video, with diagrams in a submenu.

## Risks / Trade-offs

- Inline blocks are read-only previews (edit via sheet) — no in-place block editing yet.
- Async media (images/video) height is measured once; a slow-growing image may need a rebuild to
  resize. Acceptable for now; a reflow-on-size-change is a follow-up.

## Migration Plan

Additive, app-only; replaces the snapshot rendering with live views.
