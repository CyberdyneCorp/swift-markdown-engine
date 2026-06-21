## 1. Continuous Live editor (Phase 1)

- [x] 1.1 `LiveEditorView` UIViewRepresentable wrapping a TextKit 2 UITextView
- [x] 1.2 Build attributed string from parsed blocks: live-styled text + block attachments
- [x] 1.3 Block attachments via NSTextAttachmentViewProvider hosting SwiftUI MarkdownView (carry source)
- [x] 1.4 Reveal-on-active-line marker dimming (restyle on selection change)
- [x] 1.5 Reconstruct Markdown from storage; write to the shared binding (debounced)
- [x] 1.6 Tap a block → open its per-type editor in a sheet; apply back to Markdown
- [x] 1.7 Add the Live mode to PencilNotes (Raw | Preview | Live | Edit)

## 2. Verification

- [x] 2.1 Build PencilNotes; engine tests green
- [x] 2.2 UI smoke test: Live mode renders + text edit reconstructs Markdown
- [x] 2.3 Run the iPad UI suite — all green
- [x] 2.4 openspec validate
