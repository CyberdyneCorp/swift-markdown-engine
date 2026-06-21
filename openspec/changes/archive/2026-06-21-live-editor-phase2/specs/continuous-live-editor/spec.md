## MODIFIED Requirements

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
