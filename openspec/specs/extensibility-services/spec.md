# extensibility-services Specification

## Purpose
TBD - created by archiving change add-markdown-renderer-editor. Update Purpose after archive.
## Requirements
### Requirement: Zero-dependency core
The core library target SHALL have no external package dependencies. All heavyweight
integrations (syntax highlighting, LaTeX) SHALL be provided through optional bridge
products built on injectable service protocols.

#### Scenario: Core builds with no dependencies
- **WHEN** a consumer depends only on the core product
- **THEN** the dependency graph SHALL contain no third-party packages and no JavaScript runtime

### Requirement: Service protocols
The system SHALL define four service protocols for injectable behavior: `SyntaxHighlighter`,
`LatexRenderer`, `WikiLinkResolver`, and `EmbeddedImageProvider`. The engine SHALL operate
with sensible defaults when a service is not supplied.

#### Scenario: Default behavior without services
- **WHEN** no services are injected
- **THEN** code renders as plain monospaced text, math renders as raw source, wiki-links render as plain text, and images resolve via a default loader

#### Scenario: Inject a custom highlighter
- **WHEN** a developer provides a custom `SyntaxHighlighter`
- **THEN** the engine SHALL route all code-block highlighting through it

### Requirement: Service container injection
The system SHALL provide a `MarkdownServices` container that bundles the configured
services and SHALL allow it to be supplied to both `MarkdownView` and `MarkdownEditor`,
including via the SwiftUI environment.

#### Scenario: Supply services to a view
- **WHEN** a developer constructs a `MarkdownServices` with a highlighter and latex renderer and passes it to `MarkdownView`
- **THEN** rendering SHALL use those services

### Requirement: Optional bridge products
The package SHALL ship optional products that implement the service protocols against
Highlightr (code) and SwiftMath (math), each depending on its third-party library so the
core remains dependency-free.

#### Scenario: Add only the code bridge
- **WHEN** a consumer adds the Highlightr bridge product but not the math bridge
- **THEN** SwiftMath SHALL NOT be added to the dependency graph

### Requirement: Configuration object
The system SHALL provide a `MarkdownConfiguration` controlling feature toggles (which
extensions are enabled), interactivity (editable checkboxes, link handling), code-block
options (line numbers, copy), and reading-width constraints.

#### Scenario: Disable an extension
- **WHEN** the configuration disables the math extension
- **THEN** `$…$` sequences SHALL render as literal text rather than formulas

#### Scenario: Toggle interactive checkboxes
- **WHEN** the configuration enables editable checkboxes in a `MarkdownView`
- **THEN** task items SHALL become toggleable controls

