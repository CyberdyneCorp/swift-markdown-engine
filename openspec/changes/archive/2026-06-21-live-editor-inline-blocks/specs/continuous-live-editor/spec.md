## MODIFIED Requirements

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
