## Why

In the Live editor, block elements were static `ImageRenderer` snapshots, which couldn't show
async content (images/video) and missed Canvas/LaTeX; lists were rendered as plain text (so
checklists never appeared); and the Insert toolbar was incomplete.

## What Changes

- Render block elements as **live SwiftUI views inline** via a TextKit 2
  `NSTextAttachmentViewProvider` hosting `MarkdownView` — so images, video, Mermaid (Canvas),
  LaTeX, tables, and code render for real, asynchronously.
- Render **lists/checklists as blocks** (no longer treated as plain text), so checkboxes show.
- Complete the Live editor's **Insert toolbar**: bulleted/numbered/checklist, quote, table,
  code, math, image, video, and a Diagram submenu with all 11 Mermaid types.

## Capabilities

### Modified Capabilities
- `continuous-live-editor`: inline block elements render as live views (not snapshots), lists
  render as blocks, and the Insert toolbar is complete.

## Impact

- Code: `BlockAttachment` + `BlockViewProvider` (TextKit 2) replace the snapshot path in
  `LiveEditorView`; expanded toolbar Insert menu. App-only; no engine changes.
- Known limitation: inline blocks are read-only (tap to edit in a sheet); async media height is
  measured once (may need a rebuild if a slow image grows). Deferred.
