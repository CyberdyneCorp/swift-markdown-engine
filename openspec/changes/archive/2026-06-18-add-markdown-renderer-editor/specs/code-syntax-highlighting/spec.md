## ADDED Requirements

### Requirement: Syntax-highlighted code blocks
The system SHALL render fenced code blocks with language-aware syntax highlighting,
produced through an injectable `SyntaxHighlighter` service, and SHALL render unhighlighted
monospaced text when no highlighter is configured.

#### Scenario: Highlight a known language
- **WHEN** a code block has info string `swift` and a `SyntaxHighlighter` is configured
- **THEN** the rendered output SHALL apply token coloring returned by the highlighter for Swift

#### Scenario: No highlighter configured
- **WHEN** no `SyntaxHighlighter` is configured
- **THEN** code blocks SHALL render as plain monospaced text with the theme's code colors and SHALL NOT error

### Requirement: Language identification and aliases
The system SHALL map common fence language aliases to canonical languages (e.g. `py`→`python`,
`c++`→`cpp`, `sh`→`bash`, `ts`→`typescript`) before invoking the highlighter.

#### Scenario: Resolve an alias
- **WHEN** a code block has info string `py`
- **THEN** the highlighter SHALL be invoked with canonical language `python`

#### Scenario: Unknown language falls back
- **WHEN** a code block has an unrecognized info string
- **THEN** the block SHALL render as plain monospaced text without error

### Requirement: Code block presentation
Code blocks SHALL render with a distinct surface background, preserve whitespace and line
breaks exactly, and scroll horizontally when lines exceed the available width.

#### Scenario: Long line scrolls
- **WHEN** a code block contains a line wider than the view
- **THEN** the block SHALL scroll horizontally within its own container rather than wrapping or clipping

#### Scenario: Optional line numbers and copy
- **WHEN** line numbers and the copy affordance are enabled in configuration
- **THEN** the rendered block SHALL display line numbers and a control that copies the verbatim code to the pasteboard

### Requirement: Optional Highlightr bridge product
The package SHALL provide an optional product that adapts Highlightr to the
`SyntaxHighlighter` protocol, keeping the core target free of this dependency.

#### Scenario: Core has no highlighter dependency
- **WHEN** a consumer depends only on the core product
- **THEN** the build SHALL NOT pull in Highlightr or any JavaScript runtime

#### Scenario: Bridge supplies highlighting
- **WHEN** a consumer adds the Highlightr bridge product and injects its highlighter
- **THEN** code blocks SHALL be highlighted via Highlightr with a configurable code theme
