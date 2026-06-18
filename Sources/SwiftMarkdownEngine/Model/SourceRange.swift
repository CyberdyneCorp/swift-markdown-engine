/// A half-open range of UTF-8 byte offsets into the original Markdown source.
///
/// Every node in the document model carries the range it was produced from, which
/// lets the editor map between source text and rendered output and supports
/// incremental updates.
public struct SourceRange: Sendable, Equatable, Hashable {
    /// Inclusive lower UTF-8 offset.
    public let lowerBound: Int
    /// Exclusive upper UTF-8 offset.
    public let upperBound: Int

    public init(lowerBound: Int, upperBound: Int) {
        precondition(lowerBound <= upperBound, "SourceRange lowerBound must not exceed upperBound")
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }

    /// Number of UTF-8 bytes the range spans.
    public var length: Int { upperBound - lowerBound }

    /// Whether the range covers no bytes.
    public var isEmpty: Bool { lowerBound == upperBound }
}
