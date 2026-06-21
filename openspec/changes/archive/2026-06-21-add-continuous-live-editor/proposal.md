## Why

PencilNotes has a block-based WYSIWYG editor. Users also want a continuous, Typora-style
"Live" editor: one flowing surface where you type Markdown and it renders in place — inline
formatting live-styled with markers that reveal only where the cursor is, and block elements
(code, tables, diagrams, math, images) rendered inline rather than shown as source.

## What Changes

- Add a **continuous "Live" editor** as a 4th PencilNotes mode (Raw | Preview | Live | Edit),
  built on a TextKit 2 `UITextView`.
- **Inline text** is live-styled (headings sized; bold/italic/strikethrough/inline code); the
  Markdown markers (`#`, `**`, …) are dimmed off the active line and fully revealed on the line
  the cursor is on (reveal-on-edit).
- **Block elements** (fenced code, math, Mermaid, tables, images) render **inline** via
  `NSTextAttachmentViewProvider` hosting the existing SwiftUI renderers.
- Markdown stays the source of truth: the editor reconstructs Markdown from its text + the
  source carried by each block attachment.

Phasing (honest scope):
- **Phase 1 (this change)**: the continuous surface — live inline text styling with
  reveal-on-active-line, block elements rendered inline (read-only) with tap-to-edit that opens
  the existing per-type editor in a sheet, and Markdown reconstruction. Added as the Live mode.
- **Phase 2 (future)**: in-place editing of block elements within the flow, undo/perf hardening,
  and richer cursor behavior around attachments.

## Capabilities

### New Capabilities
- `continuous-live-editor`: a continuous Typora-style editing surface over Markdown with live
  inline styling, reveal-on-active-line markers, and inline-rendered block elements.

## Impact

- Code: new `LiveEditorView` (TextKit 2 representable + attachment view providers) in the
  PencilNotes app; a 4th mode in the mode switch; reuses existing renderers and per-type editors.
- Dependencies: none new (UIKit/TextKit 2, already available).
- Risk: TextKit attachment/cursor edge cases — phased and flagged.
- Tests: a Live-mode smoke test (renders, text editing reconstructs Markdown).
