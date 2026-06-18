# latex-math-rendering Specification

## Purpose
TBD - created by archiving change add-markdown-renderer-editor. Update Purpose after archive.
## Requirements
### Requirement: Inline and block math rendering
The system SHALL render LaTeX math nodes natively (CoreText, no WebView) through an
injectable `LatexRenderer` service: inline math flowed within prose and block math as a
centered standalone element.

#### Scenario: Render inline math within a sentence
- **WHEN** a paragraph contains an inline-math node `E=mc^2`
- **THEN** the formula SHALL render inline at the surrounding text's baseline and font size, flowing with the words

#### Scenario: Render block math
- **WHEN** the document contains a block-math node
- **THEN** the formula SHALL render as a centered, larger standalone element on its own line

### Requirement: Math feature coverage
The renderer SHALL support standard LaTeX math-mode constructs: fractions,
superscripts/subscripts, radicals, integrals and large operators, matrices, Greek
letters, and common operators and symbols.

#### Scenario: Render a fraction with a superscript
- **WHEN** the math body is `\frac{x^2}{y}`
- **THEN** the rendered output SHALL show a fraction with a superscripted numerator

### Requirement: Invalid LaTeX fallback
When the math body cannot be parsed by the renderer, the system SHALL display the raw
LaTeX source in monospaced text and SHALL NOT crash.

#### Scenario: Malformed formula
- **WHEN** a math node contains unbalanced braces
- **THEN** the view SHALL show the literal LaTeX source styled as code rather than failing

### Requirement: Theme-aware math color
Rendered math SHALL adopt the active theme's text color and adapt to light/dark mode.

#### Scenario: Dark mode math
- **WHEN** the interface is in dark mode
- **THEN** rendered formulas SHALL use the theme's dark-mode text color

### Requirement: Optional SwiftMath bridge product
The package SHALL provide an optional product that adapts SwiftMath to the
`LatexRenderer` protocol, keeping the core target free of this dependency.

#### Scenario: Core has no math dependency
- **WHEN** a consumer depends only on the core product
- **THEN** the build SHALL NOT pull in SwiftMath

#### Scenario: Bridge supplies math rendering
- **WHEN** a consumer adds the SwiftMath bridge product and injects its renderer
- **THEN** math nodes SHALL render via SwiftMath's CoreText typesetting on iOS and macOS

