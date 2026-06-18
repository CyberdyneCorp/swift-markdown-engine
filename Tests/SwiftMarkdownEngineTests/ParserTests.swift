import XCTest
@testable import SwiftMarkdownEngine

final class ParserTests: XCTestCase {
    private let parser = MarkdownParser()

    func testEmptyInputProducesNoBlocks() {
        XCTAssertTrue(parser.parse("").blocks.isEmpty)
        XCTAssertTrue(parser.parse("   \n\n ").blocks.isEmpty)
    }

    func testParseIsDeterministic() {
        let source = "Hello **world**\n"
        XCTAssertEqual(parser.parse(source), parser.parse(source))
    }

    func testParseDoesNotCrashOnArbitraryInput() {
        // Spec: the parser SHALL never crash on arbitrary input (markdown-parsing).
        let samples = ["```swift\nunterminated fence", "[broken](", "$$\\frac{", "> [!NOTE]"]
        for sample in samples {
            _ = parser.parse(sample)
        }
    }

    func testParserPreservesSource() {
        let source = "anything at all"
        XCTAssertEqual(parser.parse(source).source, source)
    }

    /// Seed conformance driver: ensures every bundled fixture is parseable without
    /// crashing. HTML-equivalence assertions are enabled in Phase 1 (task 3.8).
    func testFixturesAreParseable() throws {
        let urls = Bundle.module.urls(forResourcesWithExtension: "json", subdirectory: "Fixtures") ?? []
        XCTAssertFalse(urls.isEmpty, "Expected at least one fixture file in Fixtures/")

        struct Example: Decodable { let markdown: String }
        for url in urls {
            let data = try Data(contentsOf: url)
            let examples = try JSONDecoder().decode([Example].self, from: data)
            for example in examples {
                _ = parser.parse(example.markdown)
            }
        }
    }
}
