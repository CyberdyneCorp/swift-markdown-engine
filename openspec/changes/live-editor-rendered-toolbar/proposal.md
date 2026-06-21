## Why

The Live editor showed Markdown markers (`#`, `**`) as dimmed source and had no toolbar — it
read as Markdown rather than rendered, and offered no formatting/insert affordances.

## What Changes

- **Rendered look while editing**: inline Markdown markers are now **hidden** (collapsed to
  zero width) and **revealed only on the line the cursor is on**, so text reads as rendered
  (headings, bold, italic, strikethrough, inline code) while remaining editable.
- **Live restyling**: typing Markdown re-styles the current paragraph immediately.
- **Toolbar**: a heading menu, inline formatting (bold/italic/strikethrough/code/link), and an
  Insert menu (list, quote, table, code, diagrams, math, image).

## Capabilities

### Modified Capabilities
- `continuous-live-editor`: markers are hidden/revealed (not just dimmed), typing restyles
  live, and a formatting + insert toolbar is provided.

## Impact

- Code: `LiveEditorView` toolbar + `LiveEditorController`; `LiveStyler` collapses/reveals
  markers; coordinator restyles the active paragraph on edit. App-only, no engine changes.
