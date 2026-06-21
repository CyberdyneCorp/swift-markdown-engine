# continuous-live-editor Specification

## Purpose
TBD - created by archiving change add-continuous-live-editor. Update Purpose after archive.
## Requirements
### Requirement: Continuous live editing surface
The system SHALL provide a continuous "Live" editing mode: a single scrolling surface where
Markdown is edited in place, with inline formatting rendered live and block elements rendered
inline. Markdown remains the source of truth.

#### Scenario: Live mode is available
- **WHEN** the user selects the Live mode
- **THEN** the document SHALL appear as one continuous surface with formatting rendered, not as raw source or discrete cards

#### Scenario: Editing reconstructs Markdown
- **WHEN** the user edits text in the Live surface
- **THEN** the shared Markdown SHALL update to reflect the edit (visible when switching to Raw)

### Requirement: Live inline text styling with reveal-on-active-line
The system SHALL render inline formatting (headings, bold, italic, strikethrough, inline code)
live, dim the Markdown markers off the active line, and reveal the full source on the line the
cursor occupies.

#### Scenario: Markers reveal on the active line
- **WHEN** the cursor is on a line containing `**bold**`
- **THEN** that line SHALL show the `**` markers; lines without the cursor SHALL dim them

### Requirement: Inline-rendered block elements
The system SHALL render block elements (fenced code, math, Mermaid, tables, images) inline
within the continuous surface, and SHALL let the user edit a block via its existing per-type
editor.

#### Scenario: A block renders inline
- **WHEN** the document contains a fenced code block or a table
- **THEN** it SHALL appear rendered inline in the Live surface, not as Markdown source

#### Scenario: Editing a block
- **WHEN** the user taps an inline block element
- **THEN** the system SHALL open that block's editor and apply changes back to the Markdown

