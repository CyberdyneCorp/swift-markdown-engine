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
live and HIDE the Markdown markers, collapsing them to zero width off the active line and
revealing the full source only on the line the cursor occupies. Typing Markdown SHALL restyle
the current paragraph immediately.

#### Scenario: Markers are hidden, revealed on the active line
- **WHEN** a line contains `**bold**` and the cursor is elsewhere
- **THEN** the line SHALL show "bold" rendered bold with the `**` markers hidden; placing the
  cursor on that line SHALL reveal the `**` markers for editing

#### Scenario: Typing renders live
- **WHEN** the user types `## ` at the start of a line
- **THEN** the line SHALL immediately render as a heading

### Requirement: Inline-rendered block elements
The system SHALL render block elements (lists/checklists, fenced code, math, Mermaid, tables,
images, video) inline within the continuous surface as live SwiftUI views (not static
snapshots), so async and Canvas/LaTeX content renders, and SHALL let the user edit a block via
its per-type visual editor.

#### Scenario: Rich blocks render inline for real
- **WHEN** the document contains a checklist, a LaTeX block, a Mermaid diagram, an image, and a
  video
- **THEN** each SHALL appear rendered inline in the Live surface (checkboxes, formula, diagram,
  image, video), not as Markdown source or a blank box

#### Scenario: Editing a block
- **WHEN** the user taps an inline block element
- **THEN** the system SHALL open that block's per-type visual editor and apply changes back to the Markdown

### Requirement: Live editor toolbar
The system SHALL provide a toolbar in the Live editor with a heading menu, inline formatting
(bold, italic, strikethrough, inline code, link), and a complete Insert menu: bulleted/numbered/
checklist, quote, table, code, math, image, video, and all Mermaid diagram types.

#### Scenario: Insert any block type
- **WHEN** the user opens the Insert menu
- **THEN** it SHALL offer lists/checklist, quote, table, code, math, image, video, and a Diagram
  submenu covering every supported diagram type

