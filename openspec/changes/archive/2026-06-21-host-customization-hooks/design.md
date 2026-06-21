## Context

`MarkdownEditor` (iOS/macOS) renders a fixed `MarkdownEditorToolbar` whose buttons call
`MarkdownEditorController` commands. `MarkdownView` renders each block via a `switch` in
the internal `BlockView`, styled by the environment `MarkdownTheme`. Customization today
is limited to theme/config/services and a `showsToolbar` flag.

## Goals / Non-Goals

**Goals:**
- Let a host define the editor toolbar's items, mixing built-ins with custom actions.
- Let a host replace the view for a given block kind, receiving the node + theme.
- Keep both additive and backward compatible (no breaking changes to existing call sites).

**Non-Goals:**
- Inline-node renderer overrides (bold/link/inline-math) — block-level only for now.
- Restyling the editor's *typing* syntax highlighting (separate concern).
- A general plugin/registration system beyond these two hooks.

## Decisions

- **Toolbar model**: `MarkdownToolbarItem` is a value type with an internal enum payload:
  `.command(systemImage, label, shortcut, action: (MarkdownEditorController) -> Void)`,
  `.menu(systemImage, label, items)`, and `.divider`. Built-ins are static factories
  (`.bold`, `.italic`, …, `.heading(level:)`, `.link`, `.taskList`, …) and `.default`
  reproduces today's toolbar. `.custom(...)` takes a host action. `MarkdownEditor.init`
  adds `toolbar: [MarkdownToolbarItem]? = nil` (nil ⇒ `.default`); `showsToolbar:false`
  still hides it. The toolbar view iterates items.
- **Block renderer registry**: a public `MarkdownBlockKind` enum (heading, paragraph,
  blockQuote, thematicBreak, codeBlock, mermaid, mathBlock, list, table, htmlBlock,
  footnoteDefinition, callout) with a `BlockKind.selector` mapping. An environment value
  `markdownBlockRenderers: [MarkdownBlockKind: (BlockNode, MarkdownTheme) -> AnyView]`
  accumulates via `.markdownBlockRenderer(_:render:)` (uses `transformEnvironment`, so
  multiple calls compose). `BlockView.body` checks the registry for `block.kind.selector`
  first and uses the host view if present, else the built-in switch.

## Risks / Trade-offs

- A custom block renderer fully replaces the built-in view for that kind (no partial
  override / no call-through to the default). Documented; the host can re-create what it
  needs from the `BlockNode`.
- `AnyView` erasure for renderer closures has a small perf cost, paid only for overridden
  kinds.
- Toolbar action closures are not `Sendable` (they capture host state) and run on the main
  actor — acceptable for UI callbacks.
