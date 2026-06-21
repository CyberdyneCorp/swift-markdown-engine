# custom-block-renderers Specification

## Purpose
TBD - created by archiving change host-customization-hooks. Update Purpose after archive.
## Requirements
### Requirement: Host-overridable block rendering
`MarkdownView` SHALL let a host register a custom SwiftUI view for a given block kind via
`.markdownBlockRenderer(_:render:)`. Registered kinds SHALL use the host view; all other
kinds SHALL render with the built-in views.

#### Scenario: Override a block kind
- **WHEN** a host registers a renderer for `.callout`
- **THEN** every callout block renders with the host's view, receiving the `BlockNode` and resolved `MarkdownTheme`

#### Scenario: Unregistered kinds unaffected
- **WHEN** a host registers a renderer only for `.codeBlock`
- **THEN** headings, lists, and other kinds still render with the built-in views

#### Scenario: Composing registrations
- **WHEN** `.markdownBlockRenderer` is applied more than once for different kinds
- **THEN** all registered overrides take effect

