## Why

PencilNotes today offers a raw Markdown editor (styled source — the `#`/`**` stay visible)
and a separate live preview. Users who don't know Markdown want to *write* in a rich
editor — headings, bold, lists, tables, code, math, images, video — without ever seeing
syntax, while the file on disk stays plain Markdown. No such editing surface exists yet.

## What Changes

- Add a **block-based WYSIWYG editor** to PencilNotes as a **third mode** (Raw | Preview |
  **Edit**), keeping the existing two. The document is a stack of blocks; each renders
  WYSIWYG with the existing `SwiftMarkdownEngine` renderer and is edited in place. Supports
  an insert (`+`) menu, reordering, and deletion. Markdown remains the single source of truth.
- Add **Markdown serialization** to the engine (model → Markdown) for the whole document and
  for individual blocks, so visual edits round-trip back to Markdown. The parser is already
  Markdown → model; this adds the reverse with round-trip fidelity tests.
- **Phase 1 visual editors** (this change):
  - Text blocks (paragraph/heading/list/quote/task): inline editing + a formatting toolbar
    (bold, italic, strikethrough, inline code, link, heading level, bullet/ordered/checkbox).
  - **Table**: a grid editor — add/remove rows & columns, edit cells, per-column alignment.
  - **Code**: language picker + live syntax-highlighted preview.
  - **Image/Video**: insert via URL/picker with alt/caption.
  - **Math**: LaTeX field with live preview.
- **Phase 2 (documented, out of scope here)**: full visual builders for Mermaid diagrams and
  charts. Interim behavior in Phase 1: these blocks render and are edited via source-with-
  live-preview so they remain fully usable.

## Capabilities

### New Capabilities
- `wysiwyg-editor`: a block-based, syntax-free editing surface for Markdown — block list with
  WYSIWYG rendering, selection/insert/reorder/delete, per-type visual editors (text+toolbar,
  table grid, code, image/video, math), and an interim source editor for diagram/chart blocks.
- `markdown-serialization`: converting the document model (and individual blocks) back to
  Markdown with round-trip fidelity, enabling visual edits to persist as Markdown.

### Modified Capabilities
- None. The existing raw `markdown-editor` is unchanged and remains available; the WYSIWYG
  mode is the new `wysiwyg-editor` capability above.

## Impact

- Code: new editor types in the PencilNotes app (block list, per-type editors, mode switch);
  new serialization in `Sources/SwiftMarkdownEngine` (e.g. `Serialization/MarkdownSerializer`).
- APIs: new public `MarkdownDocument.markdown()` / block serialization; no breaking changes.
- Dependencies: none new (reuses SwiftMarkdownEngine, optional Highlightr/SwiftMath bridges).
- Docs: README/DocC note serialization and the WYSIWYG example mode.
- Tests: serializer round-trip tests in the package; editor behavior verified via the app.
