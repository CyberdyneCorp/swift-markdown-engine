## MODIFIED Requirements

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

## ADDED Requirements

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
