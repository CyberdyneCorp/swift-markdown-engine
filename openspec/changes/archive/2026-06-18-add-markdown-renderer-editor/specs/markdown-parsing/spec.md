## ADDED Requirements

### Requirement: CommonMark block parsing
The system SHALL parse all CommonMark block-level constructs into a typed, immutable
document model: ATX and Setext headings (levels 1–6), paragraphs, thematic breaks,
indented and fenced code blocks, block quotes, ordered and unordered lists (including
nested and loose/tight variants), and HTML blocks.

#### Scenario: Parse a fenced code block with language
- **WHEN** the input contains a fenced code block opened with ```` ```swift ````
- **THEN** the model SHALL contain a code-block node whose `language` is `"swift"` and whose `content` is the verbatim text between the fences

#### Scenario: Parse nested lists
- **WHEN** the input contains an unordered list with a nested ordered sublist
- **THEN** the model SHALL represent the sublist as a child list node of the correct parent list item, preserving ordinal start values

#### Scenario: Tight versus loose list
- **WHEN** list items are separated by blank lines
- **THEN** the parsed list node SHALL be marked `loose`, and otherwise `tight`

### Requirement: CommonMark inline parsing
The system SHALL parse CommonMark inline constructs: emphasis, strong emphasis, inline
code spans, links (inline and reference), images, autolinks, hard and soft line breaks,
backslash escapes, and HTML inline.

#### Scenario: Parse emphasis and strong
- **WHEN** the input contains `*italic*` and `**bold**`
- **THEN** the model SHALL contain an emphasis node and a strong node with the correct inner text

#### Scenario: Resolve reference links
- **WHEN** the input contains `[text][ref]` and a matching link reference definition `[ref]: https://example.com`
- **THEN** the resulting link node SHALL have destination `https://example.com`

#### Scenario: Backslash escape
- **WHEN** the input contains `\*not emphasis\*`
- **THEN** the model SHALL contain literal text `*not emphasis*` with no emphasis node

### Requirement: GitHub Flavored Markdown extensions
The system SHALL parse GFM extensions: tables (with per-column alignment), task list
items, strikethrough, and extended autolinks (bare URLs and email addresses).

#### Scenario: Parse a GFM table with alignment
- **WHEN** the input contains a pipe table whose delimiter row is `|:---|:---:|---:|`
- **THEN** the table node SHALL record column alignments as left, center, and right respectively

#### Scenario: Parse a task list item
- **WHEN** a list item begins with `- [x]`
- **THEN** the item node SHALL be a task item with `checked == true`

#### Scenario: Parse strikethrough
- **WHEN** the input contains `~~deleted~~`
- **THEN** the model SHALL contain a strikethrough node wrapping `deleted`

### Requirement: Math extension parsing
The system SHALL recognize LaTeX math spans and blocks and emit dedicated math nodes
rather than literal text. Inline math is delimited by `$…$` or `\(…\)`; block math is
delimited by `$$…$$` or `\[…\]`.

#### Scenario: Parse inline math
- **WHEN** the input contains `the value $E=mc^2$ holds`
- **THEN** the model SHALL contain an inline-math node with body `E=mc^2` surrounded by text nodes

#### Scenario: Parse block math
- **WHEN** the input contains a line `$$\int_0^1 x\,dx$$`
- **THEN** the model SHALL contain a block-math node with the enclosed LaTeX as its body

#### Scenario: Avoid currency false positives
- **WHEN** the input contains `it costs $5 and $7`
- **THEN** the parser SHALL NOT emit a math node and SHALL keep the text literal

### Requirement: Mermaid extension parsing
The system SHALL treat a fenced code block whose info string is `mermaid` as a Mermaid
diagram node carrying the verbatim diagram source.

#### Scenario: Recognize a mermaid fence
- **WHEN** the input contains a fenced block opened with ```` ```mermaid ````
- **THEN** the model SHALL contain a mermaid node, not a generic code-block node, with the diagram source preserved verbatim

### Requirement: Additional document extensions
The system SHALL parse YAML frontmatter, footnotes (definitions and references),
callout/admonition blocks, and wiki-style links.

#### Scenario: Parse YAML frontmatter
- **WHEN** the document begins with a `---` fenced YAML block
- **THEN** the frontmatter SHALL be exposed as structured key/value metadata and excluded from the rendered body

#### Scenario: Parse a footnote
- **WHEN** the input contains a reference `text[^1]` and a definition `[^1]: note`
- **THEN** the model SHALL link the reference to the footnote definition node

#### Scenario: Parse a wiki-link
- **WHEN** the input contains `[[Page Name|alias]]`
- **THEN** the model SHALL contain a wiki-link node with target `Page Name` and display text `alias`

#### Scenario: Parse a callout
- **WHEN** a block quote begins with `> [!NOTE]`
- **THEN** the model SHALL contain a callout node of kind `note` containing the remaining quoted content

### Requirement: Immutable document model and round-tripping
The parser SHALL produce an immutable value-type document model that is safe to share
across concurrency domains, and SHALL preserve source ranges for each node to support
editing and incremental updates.

#### Scenario: Source ranges preserved
- **WHEN** a document is parsed
- **THEN** every node SHALL expose the UTF-8 source offset range it was produced from

#### Scenario: Deterministic parse
- **WHEN** the same input is parsed twice
- **THEN** the two resulting document models SHALL be equal

### Requirement: Malformed input resilience
The parser SHALL never crash or throw on arbitrary input and SHALL degrade gracefully,
emitting literal text for constructs it cannot fully resolve.

#### Scenario: Unterminated fence
- **WHEN** the input contains a code fence that is never closed
- **THEN** the parser SHALL treat the remainder of the document as the code block content without crashing
