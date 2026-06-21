## Why

In the PencilNotes Live (Typora-style) editor, lists, numbered lists, and checklists
render correctly but are *not* editable inline — the user taps the block and edits it
in a sheet. Headings, paragraphs, quotes, and inline spans (bold/italic/links/math) are
fully live, so lists are the conspicuous gap on the way to a "what you type is what you
see" experience. Inline list editing (type to edit, Enter to continue, Tab to indent,
tap to toggle a checkbox) is the single biggest remaining piece.

## What Changes

- Flat lists (bulleted, numbered, GFM task lists) render as inline-editable text in the
  Live editor instead of read-only block attachments. Nested/complex lists (items with
  more than one block) keep the existing tap-to-edit block rendering.
- List markers are styled (the bullet/number/checkbox is visually distinct from the item
  text); the active line behaves like any other text line.
- **Enter** at the end of a list item continues the list with the next marker (numbered
  markers increment); pressing **Enter** on an empty item ends the list.
- **Tab** indents the current item; outdent happens by pressing Enter on an empty nested
  item (a later iteration may add Shift-Tab).
- **Tapping a checkbox** toggles `[ ]` ↔ `[x]` in the underlying Markdown.
- Markdown stays the single source of truth; list text round-trips through the existing
  reconstruction (lists are now literal text, no attachment indirection).

## Capabilities

### New Capabilities
- `live-editor-inline-lists`: inline editing of flat lists/checklists in the PencilNotes Live editor — rendering, Enter-continuation, Tab indentation, and tap-to-toggle checkboxes.

### Modified Capabilities

## Impact

- `Examples/PencilNotes/App/LiveEditorView.swift`: `LiveStyler.isTextBlock` (flat lists →
  text), new list-marker styling, `UITextViewDelegate.textView(_:shouldChangeTextIn:)`
  for Enter/Tab, and checkbox-tap handling in the tap recognizer.
- No changes to the SwiftMarkdownEngine core or to other editor modes.
