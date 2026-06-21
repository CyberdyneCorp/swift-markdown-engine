## 1. Customizable editor toolbar

- [x] 1.1 Add public `MarkdownToolbarItem` (command/menu/divider payload, built-in
      factories, `.custom`, `.default`).
- [x] 1.2 Refactor `MarkdownEditorToolbar` to render an `[MarkdownToolbarItem]`.
- [x] 1.3 Add `toolbar:` parameter to `MarkdownEditor.init` (nil ⇒ default; keep
      `showsToolbar`).

## 2. Custom block renderers

- [x] 2.1 Add public `MarkdownBlockKind` selector + `BlockKind.selector`.
- [x] 2.2 Add `markdownBlockRenderers` environment value and `.markdownBlockRenderer(_:render:)`.
- [x] 2.3 Check the registry in `BlockView.body` before the built-in switch.

## 3. Demonstrate & verify

- [x] 3.1 PencilNotes: a custom toolbar item and a custom block renderer.
- [x] 3.2 Engine unit test: `BlockKind.selector` mapping; renderer registry composes.
- [x] 3.3 Build the package + PencilNotes; run engine tests and the UI suite on device.
- [x] 3.4 Update docs/README and the relevant specs.
