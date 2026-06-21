## Why

The continuous Live editor shipped as Phase 1. Two rough edges remain: block previews render
synchronously at build time (a noticeable hang when a document has many diagrams), and tapping a
block opens a raw-source sheet instead of the proper visual editor.

## What Changes

- **Async/incremental block rendering**: the Live editor renders text immediately and fills in
  block-element images off the main build, with a stale-render guard. No more long hang on open.
- **Per-type block editing**: tapping a block opens its real visual editor (text / table / list /
  code / math / image / diagram builders) with a live preview — not a raw-source text box. This
  reuses the WYSIWYG editors via a shared `BlockEditorView`.

## Capabilities

### Modified Capabilities
- `continuous-live-editor`: block previews render asynchronously, and block editing uses the
  per-type visual editors.

## Impact

- Code: extract a reusable `BlockEditorView` (routing shared by the WYSIWYG editor and the Live
  sheet); make `LiveTextView` render block images incrementally. App-only; no engine changes.
- Tests: existing iPad UI suite continues to pass; Live mode smoke test still green.
