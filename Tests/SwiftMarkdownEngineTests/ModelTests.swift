import XCTest
@testable import SwiftMarkdownEngine

final class ModelTests: XCTestCase {
    func testSourceRangeLengthAndEmptiness() {
        let range = SourceRange(lowerBound: 3, upperBound: 8)
        XCTAssertEqual(range.length, 5)
        XCTAssertFalse(range.isEmpty)

        let empty = SourceRange(lowerBound: 4, upperBound: 4)
        XCTAssertTrue(empty.isEmpty)
        XCTAssertEqual(empty.length, 0)
    }

    func testDocumentEquatability() {
        let a = MarkdownDocument(blocks: [BlockNode(.paragraph([InlineNode(.text("x"))]))], source: "x")
        let b = MarkdownDocument(blocks: [BlockNode(.paragraph([InlineNode(.text("x"))]))], source: "x")
        XCTAssertEqual(a, b)

        let c = MarkdownDocument(blocks: [BlockNode(.paragraph([InlineNode(.text("y"))]))], source: "y")
        XCTAssertNotEqual(a, c)
    }

    func testCalloutKindMapping() {
        XCTAssertEqual(CalloutKind(label: "NOTE"), .note)
        XCTAssertEqual(CalloutKind(label: "warning"), .warning)
        XCTAssertEqual(CalloutKind(label: "unknown-label"), .note)
    }

    func testListAndTableModelConstruct() {
        let item = ListItem(blocks: [BlockNode(.paragraph([InlineNode(.text("a"))]))], checkbox: .checked)
        let list = MarkdownList(marker: .ordered(start: 1), isTight: true, items: [item])
        XCTAssertEqual(list.items.first?.checkbox, .checked)

        let table = MarkdownTable(
            alignments: [.left, .center, .right],
            header: [[InlineNode(.text("h"))]],
            rows: [[[InlineNode(.text("c"))]]]
        )
        XCTAssertEqual(table.alignments.count, 3)
        XCTAssertEqual(table.rows.count, 1)
    }
}
