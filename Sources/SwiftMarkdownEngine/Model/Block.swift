/// A block-level node (heading, paragraph, list, table, …) and the source range
/// it was parsed from.
public struct BlockNode: Sendable, Equatable {
    public let kind: BlockKind
    public let range: SourceRange?

    public init(_ kind: BlockKind, range: SourceRange? = nil) {
        self.kind = kind
        self.range = range
    }
}

/// The kind of a block node. `indirect` because container blocks nest children.
public indirect enum BlockKind: Sendable, Equatable {
    /// ATX or Setext heading, level 1–6.
    case heading(level: Int, inlines: [InlineNode])
    /// A paragraph of inline content.
    case paragraph([InlineNode])
    /// A block quote containing nested blocks.
    case blockQuote([BlockNode])
    /// A thematic break (horizontal rule).
    case thematicBreak
    /// A fenced or indented code block. `language` is the info string, if any.
    case codeBlock(language: String?, content: String)
    /// A Mermaid diagram fence; `source` is the verbatim diagram definition.
    case mermaid(source: String)
    /// Block-level LaTeX math; `body` is the raw LaTeX.
    case mathBlock(body: String)
    /// An ordered or unordered list.
    case list(MarkdownList)
    /// A GFM table.
    case table(MarkdownTable)
    /// A raw HTML block.
    case htmlBlock(String)
    /// A footnote definition: its label and the blocks that make up the note.
    case footnoteDefinition(label: String, blocks: [BlockNode])
    /// A callout/admonition block.
    case callout(kind: CalloutKind, title: String?, blocks: [BlockNode])
}

/// An ordered or unordered list.
public struct MarkdownList: Sendable, Equatable {
    public enum Marker: Sendable, Equatable {
        case bullet
        case ordered(start: Int)
    }

    public let marker: Marker
    /// Tight lists render items without inter-item spacing; loose lists add it.
    public let isTight: Bool
    public let items: [ListItem]

    public init(marker: Marker, isTight: Bool, items: [ListItem]) {
        self.marker = marker
        self.isTight = isTight
        self.items = items
    }
}

/// A single list item; `checkbox` is non-nil for GFM task items.
public struct ListItem: Sendable, Equatable {
    public enum Checkbox: Sendable, Equatable {
        case checked
        case unchecked
    }

    public let blocks: [BlockNode]
    public let checkbox: Checkbox?

    public init(blocks: [BlockNode], checkbox: Checkbox? = nil) {
        self.blocks = blocks
        self.checkbox = checkbox
    }
}

/// A GFM pipe table with per-column alignment.
public struct MarkdownTable: Sendable, Equatable {
    public enum Alignment: Sendable, Equatable {
        case none
        case left
        case center
        case right
    }

    /// Column alignments, one per column.
    public let alignments: [Alignment]
    /// Header row cells; each cell is a sequence of inlines.
    public let header: [[InlineNode]]
    /// Body rows; each row is an array of cells, each cell a sequence of inlines.
    public let rows: [[[InlineNode]]]

    public init(alignments: [Alignment], header: [[InlineNode]], rows: [[[InlineNode]]]) {
        self.alignments = alignments
        self.header = header
        self.rows = rows
    }
}

/// The kind of a callout/admonition, e.g. `> [!NOTE]`.
public enum CalloutKind: String, Sendable, Equatable, CaseIterable {
    case note
    case tip
    case important
    case warning
    case caution
    case info
    case success
    case question
    case danger
    case quote

    /// Maps a callout label (case-insensitive) to a kind, defaulting to `.note`.
    public init(label: String) {
        self = CalloutKind(rawValue: label.lowercased()) ?? .note
    }
}
