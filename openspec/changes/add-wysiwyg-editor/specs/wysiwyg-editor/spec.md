## ADDED Requirements

### Requirement: Block-based WYSIWYG editing surface
The system SHALL provide a block-based editing surface where the document is presented as a
stack of blocks, each rendered WYSIWYG using the SwiftMarkdownEngine renderer, with no raw
Markdown syntax shown to the user. The underlying document SHALL remain Markdown.

#### Scenario: Render the document as editable blocks
- **WHEN** a Markdown document is opened in the WYSIWYG editor
- **THEN** each block (heading, paragraph, list, quote, table, code, math, image, video,
  diagram) SHALL appear as its rendered output, not as Markdown source

#### Scenario: Edits persist as Markdown
- **WHEN** the user changes any block visually
- **THEN** the document's Markdown SHALL update to reflect the change (Markdown stays the
  source of truth)

### Requirement: Block management
The system SHALL let the user insert a new block via a `+` menu, reorder blocks, and delete a
block.

#### Scenario: Insert a block
- **WHEN** the user invokes the `+` menu and chooses a block type
- **THEN** a new block of that type SHALL be inserted at the chosen position and become editable

#### Scenario: Reorder and delete
- **WHEN** the user moves a block to a new position or deletes it
- **THEN** the block order/contents SHALL update and the Markdown SHALL reflect the new structure

### Requirement: Text block visual formatting
The system SHALL let the user edit text blocks (paragraph, heading, list item, quote, task)
inline and apply formatting through a toolbar: bold, italic, strikethrough, inline code, link,
heading level, bullet/ordered list, and task checkbox — without typing Markdown syntax.

#### Scenario: Apply bold from the toolbar
- **WHEN** the user selects text in a paragraph and taps Bold
- **THEN** the selection SHALL render bold and the Markdown SHALL wrap it in `**…**`

#### Scenario: Change block type
- **WHEN** the user converts a paragraph to a Heading 2
- **THEN** the block SHALL render as an H2 and serialize with `## `

#### Scenario: Toggle a task checkbox
- **WHEN** the user taps a task item's checkbox
- **THEN** the checkbox state SHALL toggle and serialize as `- [x]` / `- [ ]`

### Requirement: Visual table editor
The system SHALL provide a grid editor for table blocks: add/remove rows and columns, edit
cell contents, and set per-column alignment, with no Markdown pipes shown.

#### Scenario: Edit a table visually
- **WHEN** the user adds a column, edits a cell, and sets a column to right-aligned
- **THEN** the rendered table SHALL update and serialize to a GFM table with the alignment row

### Requirement: Visual code editor
The system SHALL provide a code-block editor with a language picker and a live
syntax-highlighted preview.

#### Scenario: Edit a code block
- **WHEN** the user selects a language and edits the code
- **THEN** the preview SHALL highlight for that language and serialize to a fenced block with
  the language info string

### Requirement: Image and video insertion
The system SHALL let the user insert an image or video by URL (or picker) with alt/caption,
producing the corresponding Markdown image or video embed.

#### Scenario: Insert an image
- **WHEN** the user provides an image URL and alt text
- **THEN** the block SHALL render the image and serialize to `![alt](url)`

### Requirement: Visual math editor
The system SHALL provide a LaTeX editor with a live rendered preview for math blocks.

#### Scenario: Edit a math block
- **WHEN** the user edits LaTeX in the math editor
- **THEN** the preview SHALL render the formula and serialize to a `$$…$$` block

### Requirement: Diagram and chart blocks (interim)
Until full visual builders exist, the system SHALL render diagram/chart (Mermaid) blocks and
allow editing their source with a live preview, so the blocks remain fully usable in the
WYSIWYG editor.

#### Scenario: Edit a diagram's source
- **WHEN** the user opens a Mermaid block and edits its source
- **THEN** the rendered diagram SHALL update live and serialize back into a `mermaid` fenced block
