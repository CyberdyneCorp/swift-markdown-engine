## 1. Markdown serialization (engine foundation)

- [x] 1.1 Add `Sources/SwiftMarkdownEngine/Serialization/MarkdownSerializer.swift` with `InlineNode.markdown()` (text, emphasis, strong, strikethrough, inline code, link, image, autolink, wiki-link, footnote ref, inline math, line breaks)
- [x] 1.2 Add `BlockNode.markdown()` for every block kind (heading, paragraph, list/task list with nesting, block quote, thematic break, fenced code w/ language, math block, table w/ alignment row, image, mermaid/raw passthrough, callout, footnote definition)
- [x] 1.3 Add `MarkdownDocument.markdown()` joining blocks with blank lines
- [x] 1.4 Round-trip tests: parse → serialize → parse equality for headings, emphasis mix, nested lists, task list, table w/ alignment, fenced code, math block, image, mermaid
- [x] 1.5 Single-block serialization test (a table block emits only its own Markdown)

## 2. WYSIWYG block framework (PencilNotes)

- [x] 2.1 Add an `EditableBlock` model (id + Markdown fragment) and a document split/join helper that maps the bound Markdown string ↔ ordered fragments
- [x] 2.2 Add a `WysiwygEditorView` that renders each block read-only via the existing renderer in a `LazyVStack`, with selection state
- [x] 2.3 Insert (`+`) menu, reorder, and delete; write changes back to the shared `@Binding<String>`
- [x] 2.4 Add a 3-way mode switch (Raw | Preview | Edit) in PencilNotes; Edit binds to the same text as Raw/Preview

## 3. Text block visual editing

- [x] 3.1 Inline editable text for paragraph/heading/quote with focus-to-edit (UITextView-backed; list/task editing still uses the source editor)
- [x] 3.2 Formatting toolbar: bold, italic, strikethrough, inline code, link (wrap selection in Markdown)
- [x] 3.3 Block-type controls: heading level, convert paragraph/heading/quote, bulleted/numbered/checklist list styles, and task checkbox toggle (visual list editor)
- [x] 3.4 Re-render the block on commit; verify Markdown updates correctly

## 4. Visual table editor

- [x] 4.1 Grid editor: cell text fields, add/remove row & column
- [x] 4.2 Per-column alignment control (left/center/right)
- [x] 4.3 Serialize via `BlockNode.markdown()` and re-render

## 5. Code / image-video / math editors

- [x] 5.1 Code editor: language `Picker` + editor (live highlighted preview is the rendered block above)
- [x] 5.2 Image/Video insert form (URL + alt/caption, plain image or linked video toggle) → `![alt](url)` / `[![alt](thumb)](url)`
- [x] 5.3 Math editor: LaTeX field + live preview (rendered block above) → `$$…$$`

## 6. Diagram/chart interim editor

- [x] 6.1 Dedicated diagram source editor (edit Mermaid source; rendered diagram above is the live preview); serializes back into a fenced `mermaid` block
- [x] 6.2 Document that full visual diagram/chart builders are Phase 2 (noted in README + the editor UI; deferred to a follow-up change)

## 7. Verification & docs

- [x] 7.1 Run the full package test suite (serializer round-trips) — no regressions (111 tests)
- [x] 7.2 Build PencilNotes (builds clean); manual exercise of the Edit mode is for on-device verification
- [x] 7.3 Update README/DocC: Markdown serialization API + WYSIWYG example mode
- [x] 7.4 `openspec validate add-wysiwyg-editor`
