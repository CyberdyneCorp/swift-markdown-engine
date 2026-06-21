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
The system SHALL render block elements (fenced code, math, Mermaid, tables, images) inline
within the continuous surface, rendering their previews asynchronously so the editor stays
responsive, and SHALL let the user edit a block via its per-type visual editor.

#### Scenario: A block renders inline without blocking
- **WHEN** the document contains many block elements
- **THEN** the text SHALL appear immediately and the block previews SHALL fill in without a long
  blocking hang

#### Scenario: Editing a block with its visual editor
- **WHEN** the user taps an inline block element
- **THEN** the system SHALL open that block's per-type visual editor (e.g. a table grid or a
  diagram builder) with a live preview, and apply changes back to the Markdown

### Requirement: Live editor toolbar
The system SHALL provide a toolbar in the Live editor with a heading menu, inline formatting
(bold, italic, strikethrough, inline code, link) applied to the selection, and an Insert menu
for blocks (list, quote, table, code, diagrams, math, image).

#### Scenario: Apply formatting from the toolbar
- **WHEN** the user selects text and taps Bold
- **THEN** the selection SHALL be wrapped and rendered bold

#### Scenario: Insert a block from the toolbar
- **WHEN** the user picks a block from the Insert menu
- **THEN** that block SHALL be added to the document and rendered inline

