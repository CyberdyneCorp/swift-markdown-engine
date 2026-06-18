## ADDED Requirements

### Requirement: Semantic theme tokens
The system SHALL expose a `MarkdownTheme` of semantic tokens covering background and
surface colors, text colors (primary/secondary/tertiary), accent colors, borders, and
typography (font family and size scale per element), with built-in light and dark values.

#### Scenario: Default theme adapts to appearance
- **WHEN** the system appearance changes between light and dark
- **THEN** rendering SHALL switch to the corresponding theme values automatically

#### Scenario: Apply a custom theme
- **WHEN** a developer supplies a custom `MarkdownTheme`
- **THEN** rendered and edited content SHALL use the custom colors and typography

### Requirement: Per-element styling
The theme SHALL allow customization of individual element appearance: heading scale,
paragraph spacing, list indentation and markers, block-quote styling, code block and
inline-code colors, table borders and zebra striping, and link color.

#### Scenario: Customize code block background
- **WHEN** the theme sets a specific code surface color
- **THEN** all rendered code blocks SHALL use that background

#### Scenario: Customize heading scale
- **WHEN** the theme defines a custom font-size scale for headings
- **THEN** rendered headings SHALL use those sizes

### Requirement: Consistent theming across subsystems
Code highlighting, math, and Mermaid rendering SHALL each derive default colors from the
active `MarkdownTheme` so the whole document looks cohesive.

#### Scenario: Diagram inherits theme colors
- **WHEN** a Mermaid diagram has no inline styling
- **THEN** it SHALL render using the active theme's surface, accent, and text colors

### Requirement: SwiftUI environment integration
The theme SHALL be injectable through the SwiftUI environment so nested `MarkdownView`
and `MarkdownEditor` instances inherit it without explicit passing.

#### Scenario: Inherit theme from environment
- **WHEN** a developer sets the Markdown theme on a parent view via the environment
- **THEN** descendant Markdown views SHALL use that theme unless overridden locally
