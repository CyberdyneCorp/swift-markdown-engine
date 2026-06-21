## Context

The Live editor renders the document into one `UITextView` (TextKit 2). Text blocks
(heading/paragraph/simple quote) are rendered as styled attributed text with their
Markdown source preserved literally; everything else is a `BlockAttachment` hosting a
read-only `MarkdownView`, tapped to edit in a sheet. `LiveStyler.isTextBlock` decides
which path a block takes. Inline spans (bold/italic/strike/highlight/code/link/`$…$`
math) are styled live, with syntax markers collapsed off the active line.

Lists currently fall in the attachment path, so they are not inline-editable.

## Goals / Non-Goals

**Goals:**
- Flat lists (bullet, ordered, task) are inline-editable text in the Live editor.
- Enter continues a list; Enter on an empty item ends it. Tab indents.
- Tapping a checkbox toggles `[ ]` ↔ `[x]`.
- Markdown remains the source of truth; lists round-trip with no attachment indirection.

**Non-Goals:**
- Nested/complex lists (items containing multiple blocks, or sub-lists) — these keep the
  tap-to-edit block rendering.
- Replacing raw markers with glyph bullets (`-` → `•`) — deferred; raw markers are shown
  but styled. Checkbox glyphs and Shift-Tab outdent are also deferred.

## Decisions

- **Flat-list detection (`isFlatList`)**: a `.list` whose every item has exactly one
  `paragraph` block (the item may carry a `checkbox`). Mirrors `BlockEditorView`'s "flat"
  test. Flat lists become text blocks; non-flat lists stay attachments.
- **Rendering**: a `styleListMarkers` pass in `LiveStyler.styled` matches each line's
  leading marker (`^\s*([-*+]|\d+\.)\s+(\[[ xX]\])?`) and styles the marker (accent,
  semibold) and the checkbox token distinctly. The item text is normal body text. Because
  the marker stays literal text, reconstruction and the active-line model are unchanged.
- **Enter / Tab** are handled in `textView(_:shouldChangeTextIn:replacementText:)`:
  - `"\n"`: if the current line is a list item, insert `"\n" + nextMarker`; if the item
    body is empty, instead delete the marker (ends the list). Return `false`.
  - `"\t"`: if at a list item, insert two spaces of indent at the line start. Return
    `false`.
  - After a handled edit, update the binding and restyle (same path as programmatic edits).
- **Checkbox toggle**: in the existing tap recognizer, before block handling, if the tap
  lands on a `[ ]`/`[x]` token at a list-item line start, flip the character in storage,
  then reconstruct + restyle.

## Risks / Trade-offs

- Hand-rolling Enter/Tab in `shouldChangeTextIn` risks cursor/selection edge cases (empty
  item, multi-line selection). Mitigated by handling only the simple caret cases and
  falling back to default behavior otherwise.
- Raw markers (no glyph bullets) are a cosmetic compromise for v1, chosen to avoid the
  per-line char-substitution/reveal machinery that glyphs would require.
- Regression surface: switching lists from attachments to text changes block separators
  in reconstruction (single `\n` within a list, `\n\n` between blocks). Covered by the
  round-trip serializer tests and the on-device Live screenshot/typing checks.
