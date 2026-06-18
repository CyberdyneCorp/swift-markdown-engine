import XCTest
@testable import SwiftMarkdownEngine

final class ConcurrencyTests: XCTestCase {
    /// The parser must run off the main actor and return a `Sendable` document that
    /// is safe to use back on the main actor. This compiles only if `MarkdownParser`
    /// and `MarkdownDocument` are `Sendable`.
    func testParsingOffMainActor() async {
        let source = """
        # Title

        Some **bold** text and `code`.

        - [x] item
        - [ ] item

        | a | b |
        |---|---|
        | 1 | 2 |
        """
        let document = await Task.detached(priority: .userInitiated) {
            MarkdownParser().parse(source)
        }.value
        XCTAssertFalse(document.blocks.isEmpty)
    }

    /// Concurrent parses on a background pool must not race and must be deterministic.
    func testConcurrentParsesAreConsistent() async {
        let source = "## Heading\n\nText with *emphasis* and a [link](https://example.com)."
        let reference = MarkdownParser().parse(source)
        await withTaskGroup(of: MarkdownDocument.self) { group in
            for _ in 0..<16 {
                group.addTask { MarkdownParser().parse(source) }
            }
            for await document in group {
                XCTAssertEqual(document, reference)
            }
        }
    }

    /// The theme is a `Sendable` value type usable across actors.
    func testThemeIsSendableAcrossActors() async {
        let theme = MarkdownTheme.dark
        let accent = await Task.detached { theme.accent }.value
        XCTAssertEqual(accent, MarkdownTheme.dark.accent)
    }
}
