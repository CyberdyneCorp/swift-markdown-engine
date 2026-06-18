# platform-support Specification

## Purpose
TBD - created by archiving change add-markdown-renderer-editor. Update Purpose after archive.
## Requirements
### Requirement: Supported platforms and minimums
The package SHALL support iOS 17+, macOS 14+, and watchOS 10+, written in Swift 6 with
strict concurrency enabled, and SHALL build as a Swift Package.

#### Scenario: Build on all platforms
- **WHEN** the package is built for iOS, macOS, and watchOS
- **THEN** the core and rendering targets SHALL compile for each platform without modification

### Requirement: Rendering on all platforms
Full Markdown rendering — including code, tables, math, and Mermaid — SHALL be available
on iOS and macOS. watchOS SHALL render a constrained subset suitable for a small screen.

#### Scenario: Render on watchOS
- **WHEN** a document is rendered on watchOS
- **THEN** headings, paragraphs, lists, block quotes, inline formatting, links, and code blocks SHALL render legibly within the watch viewport

#### Scenario: Heavy diagrams degrade on watchOS
- **WHEN** a layout-heavy Mermaid diagram is rendered on watchOS
- **THEN** the engine MAY substitute a simplified representation or the diagram source rather than attempting full layout

### Requirement: Editor platform availability
The Markdown editor SHALL be available on iOS and macOS. watchOS SHALL be render-only and
SHALL NOT expose the editor.

#### Scenario: Editor unavailable on watchOS
- **WHEN** building for watchOS
- **THEN** the editor view SHALL NOT be part of the watchOS API surface, and rendering APIs SHALL remain available

### Requirement: Platform-idiomatic interaction
The engine SHALL use platform-appropriate input and interaction: pointer/keyboard and
menu commands on macOS, touch and context menus on iOS, and compact navigation on watchOS.

#### Scenario: Link activation per platform
- **WHEN** a link is activated
- **THEN** it SHALL respond to a click on macOS and a tap on iOS, invoking the same configured handler

### Requirement: Concurrency safety
The document model and theme SHALL be `Sendable` value types safe to pass across
concurrency domains; parsing SHALL be performable off the main actor.

#### Scenario: Parse off the main actor
- **WHEN** a large document is parsed on a background task
- **THEN** parsing SHALL complete without data races and the resulting model SHALL be safely usable from the main actor

