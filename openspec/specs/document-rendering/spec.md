# document-rendering Specification

## Purpose
TBD - created by archiving change add-markdown-renderer-editor. Update Purpose after archive.
## Requirements
### Requirement: SwiftUI Markdown view
The system SHALL provide a SwiftUI `MarkdownView` that renders a parsed document (or a
raw Markdown string) natively, without using a WebView or JavaScript runtime.

#### Scenario: Render from a string
- **WHEN** a developer creates `MarkdownView("# Title\n\nBody")`
- **THEN** the view SHALL display a heading "Title" and a paragraph "Body"

#### Scenario: Render from a parsed document
- **WHEN** a developer passes a previously parsed `MarkdownDocument` to `MarkdownView`
- **THEN** the view SHALL render without re-parsing the source

### Requirement: Block element rendering
The system SHALL render all parsed block elements: headings (1–6 with distinct
typography), paragraphs, block quotes, thematic breaks, ordered/unordered/task lists
with nesting, and tables.

#### Scenario: Render heading hierarchy
- **WHEN** the document contains headings of levels 1 through 6
- **THEN** each SHALL render with a visually distinct, decreasing typographic scale per the active theme

#### Scenario: Render a GFM table with alignment
- **WHEN** the document contains a table with left/center/right aligned columns
- **THEN** the rendered cells SHALL honor each column's alignment

#### Scenario: Render nested lists
- **WHEN** the document contains a list with two levels of nesting
- **THEN** the rendered list SHALL show correct indentation and marker style per level

### Requirement: Inline element rendering
The system SHALL render inline elements: emphasis, strong, strikethrough, inline code,
links, autolinks, images, wiki-links, footnote references, and line breaks, with correct
flowing/wrapping within prose.

#### Scenario: Render mixed inline formatting
- **WHEN** a paragraph contains `**bold** and *italic* and `code``
- **THEN** the rendered text SHALL show the corresponding bold, italic, and monospaced styling inline

#### Scenario: Activate a link
- **WHEN** the user taps or clicks a rendered link
- **THEN** the view SHALL invoke the configured link-open handler with the link's destination URL

### Requirement: Interactive task checkboxes in rendered output
When `MarkdownView` is configured as editable-checkboxes, task list items SHALL render as
toggleable controls and report changes back to the host.

#### Scenario: Toggle a rendered checkbox
- **WHEN** task checkboxes are interactive and the user toggles an item
- **THEN** the view SHALL emit a change describing the toggled item's source range and new checked state

### Requirement: Image loading
The system SHALL render images referenced by Markdown, resolving them through the
configured `EmbeddedImageProvider`, and SHALL show a placeholder while loading and on
failure.

#### Scenario: Render a remote image
- **WHEN** the document contains `![alt](https://example.com/a.png)`
- **THEN** the view SHALL request the image from the image provider and display it once resolved, using `alt` as the accessibility label

#### Scenario: Image failure placeholder
- **WHEN** an image fails to load
- **THEN** the view SHALL display a failure placeholder rather than crashing or showing empty space

### Requirement: Wide-content overflow handling
Content wider than the available width (tables, code blocks, diagrams) SHALL be made
horizontally scrollable rather than clipped or forcing the page to scroll horizontally.

#### Scenario: Wide table scrolls
- **WHEN** a table is wider than the view's width
- **THEN** the table SHALL scroll horizontally within its own container while the surrounding prose remains within the reading width

### Requirement: Accessibility
Rendered content SHALL be accessible: headings expose heading traits and levels, images
expose alt text, links are individually focusable, and Dynamic Type scaling is respected.

#### Scenario: Heading exposed to assistive tech
- **WHEN** VoiceOver focuses a rendered level-2 heading
- **THEN** it SHALL be announced as a heading at level 2

#### Scenario: Dynamic Type
- **WHEN** the user increases the system text size
- **THEN** rendered prose SHALL scale accordingly while preserving layout

### Requirement: Video block rendering
The system SHALL render a block whose sole content is a video-bearing image as a video
embed rather than as a static image or link. This applies to a block that is solely a
linked image `[![alt](thumb)](videoURL)` with a video destination, or solely an image
`![alt](clip.mp4)` whose source is a direct video file.

#### Scenario: Linked thumbnail becomes a video embed
- **WHEN** a paragraph's only content is `[![alt](thumb)](videoURL)` and `videoURL`
  classifies as a video (direct file or provider)
- **THEN** the block SHALL render as a tappable video thumbnail, not as link text

#### Scenario: Image with a video source becomes a player
- **WHEN** a paragraph's only content is an image whose source is a direct video file
- **THEN** the block SHALL render as an inline native player, not as a broken image

#### Scenario: Non-video linked image is unchanged
- **WHEN** a linked image's destination is not a video (e.g. a page link)
- **THEN** the block SHALL retain its existing rendering behavior

