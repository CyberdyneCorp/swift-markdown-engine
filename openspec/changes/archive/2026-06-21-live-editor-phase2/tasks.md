## 1. Async block rendering

- [x] 1.1 Build the Live attributed string with placeholder block attachments
- [x] 1.2 Render each block image incrementally (off the build) and swap it in via textStorage.edited
- [x] 1.3 Generation guard so stale renders from a previous rebuild are dropped

## 2. Per-type block editing

- [x] 2.1 Extract a reusable `BlockEditorView(markdown:theme:)` from the WYSIWYG routing
- [x] 2.2 Use it in WysiwygEditorView (behavior preserved)
- [x] 2.3 Use it in the Live editor's tap-to-edit sheet, with a live preview above

## 3. Verification

- [x] 3.1 Build PencilNotes; engine tests green
- [x] 3.2 Run the iPad UI suite — all green
- [x] 3.3 openspec validate
