## Why

A host app can already theme the renderer (`MarkdownTheme`), toggle features
(`MarkdownConfiguration`), and inject content services (`MarkdownServices`). But two
common customizations are impossible today:

- The `MarkdownEditor` toolbar is a fixed set of buttons (`showsToolbar` only toggles it
  on/off). Apps can't choose which commands appear, reorder them, or add their own.
- The renderer's per-node SwiftUI views are `internal`, so an app can't replace how a
  specific block type (e.g. a callout, code block, or heading) is drawn — only restyle
  within the built-in layouts via the theme.

This change adds two public extension points so downstream apps can tailor the editor
toolbar and override block rendering, without forking the library.

## What Changes

- **Customizable editor toolbar**: a public `MarkdownToolbarItem` model (built-in command
  items, dividers, submenus, and `.custom` items that act on `MarkdownEditorController`).
  `MarkdownEditor` gains a `toolbar:` parameter; passing `nil` keeps the current default
  set, so existing call sites are unaffected.
- **Custom block renderers**: a public `MarkdownBlockKind` selector and a
  `.markdownBlockRenderer(_:render:)` view modifier. When a renderer is registered for a
  block kind, `MarkdownView` uses the host's SwiftUI view (given the `BlockNode` and the
  resolved `MarkdownTheme`) instead of the built-in one; unregistered kinds render as
  before.

## Capabilities

### New Capabilities
- `editor-toolbar-customization`: define the MarkdownEditor toolbar's items (built-in + custom) per host.
- `custom-block-renderers`: override the SwiftUI view used to render specific block kinds in MarkdownView.

### Modified Capabilities

## Impact

- `Sources/MarkdownEditor/MarkdownEditor.swift`: new `MarkdownToolbarItem`, toolbar
  parameter, item-driven `MarkdownEditorToolbar`. Backward compatible.
- `Sources/SwiftMarkdownEngine/Rendering/Environment.swift` + `BlockView.swift`: new
  `MarkdownBlockKind`, renderer registry in the environment, `.markdownBlockRenderer`
  modifier, and a registry check in `BlockView`.
- PencilNotes example: demonstrate a custom toolbar item and a custom block renderer.
