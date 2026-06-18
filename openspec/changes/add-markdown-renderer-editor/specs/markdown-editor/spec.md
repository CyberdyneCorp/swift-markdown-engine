## ADDED Requirements

### Requirement: Native Markdown editor view
The system SHALL provide a Markdown editor, built on TextKit 2 and bridged to SwiftUI,
available on iOS and macOS. The editor edits Markdown source text and applies live visual
styling without converting the text to rich text or losing the underlying Markdown.

#### Scenario: Edit Markdown source
- **WHEN** the user types `**bold**` in the editor
- **THEN** the underlying document text SHALL contain the literal characters `**bold**`

#### Scenario: Two-way binding
- **WHEN** the bound text changes programmatically
- **THEN** the editor SHALL reflect the new content, and user edits SHALL update the binding

### Requirement: Live syntax styling
The editor SHALL apply syntax-aware styling to the source as the user types — including
heading scale, emphasis/strong/strikethrough, inline code and fenced code, links,
wiki-links, and math — while keeping the raw Markdown characters editable.

#### Scenario: Style a heading line
- **WHEN** a line begins with `## `
- **THEN** the editor SHALL render that line with the level-2 heading typography while keeping the `## ` prefix present and editable

#### Scenario: Style inline code
- **WHEN** text is wrapped in backticks
- **THEN** the span SHALL be styled monospaced with the code background while the backticks remain in the text

### Requirement: Formatting commands and toolbar
The editor SHALL expose formatting commands (bold, italic, strikethrough, inline code,
heading level, link, list, task item, block quote, code block) invokable via a toolbar
and via standard keyboard shortcuts where available.

#### Scenario: Apply bold to a selection
- **WHEN** the user selects text and invokes the bold command
- **THEN** the selection SHALL be wrapped in `**…**`, and invoking bold again on the same selection SHALL remove the wrapping

#### Scenario: Toggle a list
- **WHEN** the user invokes the unordered-list command on one or more lines
- **THEN** each affected line SHALL be prefixed with `- `, and re-invoking SHALL remove the prefix

### Requirement: Interactive editing affordances
The editor SHALL support interactive task checkboxes (tappable to toggle `[ ]`/`[x]`),
smart list continuation on return, and tab/shift-tab indentation of list items.

#### Scenario: Toggle a task checkbox in the editor
- **WHEN** the user taps a rendered checkbox on a task line
- **THEN** the source SHALL toggle between `- [ ]` and `- [x]` at that line

#### Scenario: Continue a list on return
- **WHEN** the caret is at the end of a non-empty list item and the user presses return
- **THEN** the editor SHALL insert a new list marker on the next line, and pressing return on an empty item SHALL remove the marker

### Requirement: Wiki-link and image affordances
The editor SHALL recognize wiki-links (`[[…]]`) and image embeds, resolving display
through the configured `WikiLinkResolver` and `EmbeddedImageProvider`, and SHALL offer
completion for wiki-link targets when a resolver is provided.

#### Scenario: Wiki-link completion
- **WHEN** the user types `[[` and a `WikiLinkResolver` is configured
- **THEN** the editor SHALL present candidate targets from the resolver for completion

### Requirement: Spelling and grammar with suppression
On platforms where the system provides it, the editor SHALL support spelling/grammar
checking while suppressing it within code, math, and wiki-link spans.

#### Scenario: Suppress spell-check in code
- **WHEN** the caret is inside an inline code span or fenced code block
- **THEN** spelling and grammar checking SHALL NOT flag tokens within that span

### Requirement: Apple Pencil support on iPad
On iPad, the editor SHALL support Apple Pencil input. Handwriting SHALL be converted to
text and inserted at the writing location via Scribble, and standard Scribble editing
gestures SHALL be supported: scratch-out to delete, draw a vertical bar to insert space,
and select by circling or underlining. Where the hardware and OS provide them, the editor
SHALL support Pencil hover previews and a configurable action for Pencil double-tap and
squeeze.

#### Scenario: Insert text by handwriting
- **WHEN** the user writes words over the editor with Apple Pencil
- **THEN** the handwriting SHALL be converted to text and inserted into the Markdown source at the indicated location

#### Scenario: Scratch out to delete
- **WHEN** the user scratches out a word with Apple Pencil
- **THEN** that word SHALL be removed from the source

#### Scenario: Pencil hover preview
- **WHEN** Pencil hover is available and the user hovers over the editor
- **THEN** the editor SHALL preview the insertion point without committing input

#### Scenario: Configurable Pencil double-tap or squeeze
- **WHEN** the user performs a Pencil double-tap or squeeze and an action is configured
- **THEN** the editor SHALL invoke that configured action

#### Scenario: Non-Pencil input unaffected
- **WHEN** the device has no Apple Pencil or Pencil features are unavailable
- **THEN** keyboard and touch editing SHALL continue to work unchanged

### Requirement: Editor scrolling ergonomics
The editor SHALL provide bottom overscroll so the caret is not pinned to the bottom edge
while typing, and SHALL constrain body text to a readable column while allowing wide
content (tables, code) to break out.

#### Scenario: Caret stays visible while typing at the end
- **WHEN** the user types at the end of a long document
- **THEN** the caret SHALL remain comfortably above the bottom edge rather than pinned to it
