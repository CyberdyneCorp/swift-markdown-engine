import XCTest
@testable import MarkdownEditor

final class MarkdownEditorTests: XCTestCase {
    func testBoldWrapAndUnwrap() {
        let wrapped = MarkdownEditCommands.toggleInlineWrap("hello", range: NSRange(location: 0, length: 5), marker: "**")
        XCTAssertEqual(wrapped.text, "**hello**")
        // Toggling again removes it (markers inside selection).
        let unwrapped = MarkdownEditCommands.toggleInlineWrap(wrapped.text, range: NSRange(location: 0, length: 9), marker: "**")
        XCTAssertEqual(unwrapped.text, "hello")
    }

    func testUnwrapWhenMarkersSurroundSelection() {
        let result = MarkdownEditCommands.toggleInlineWrap("**hello**", range: NSRange(location: 2, length: 5), marker: "**")
        XCTAssertEqual(result.text, "hello")
    }

    func testSetHeadingReplacesExisting() {
        let h2 = MarkdownEditCommands.setHeading("Title", range: NSRange(location: 0, length: 0), level: 2)
        XCTAssertEqual(h2.text, "## Title")
        let h3 = MarkdownEditCommands.setHeading(h2.text, range: NSRange(location: 0, length: 0), level: 3)
        XCTAssertEqual(h3.text, "### Title")
        let removed = MarkdownEditCommands.setHeading(h3.text, range: NSRange(location: 0, length: 0), level: 0)
        XCTAssertEqual(removed.text, "Title")
    }

    func testToggleBulletListAddAndRemove() {
        let added = MarkdownEditCommands.toggleLinePrefix("a\nb", range: NSRange(location: 0, length: 3), prefix: "- ")
        XCTAssertEqual(added.text, "- a\n- b")
        let removed = MarkdownEditCommands.toggleLinePrefix(added.text, range: NSRange(location: 0, length: added.text.utf16.count), prefix: "- ")
        XCTAssertEqual(removed.text, "a\nb")
    }

    func testToggleCheckbox() {
        let checked = MarkdownEditCommands.toggleCheckbox("- [ ] task", location: 0)
        XCTAssertEqual(checked.text, "- [x] task")
        let unchecked = MarkdownEditCommands.toggleCheckbox(checked.text, location: 0)
        XCTAssertEqual(unchecked.text, "- [ ] task")
    }

    func testListContinuationBullet() {
        let result = MarkdownEditCommands.listContinuation("- item", location: 6)
        XCTAssertEqual(result, .insert("\n- "))
    }

    func testListContinuationOrderedIncrements() {
        let result = MarkdownEditCommands.listContinuation("1. first", location: 8)
        XCTAssertEqual(result, .insert("\n2. "))
    }

    func testListContinuationEmptyItemRemovesMarker() {
        if case .removeMarker = MarkdownEditCommands.listContinuation("- ", location: 2) {
            // expected
        } else {
            XCTFail("empty item should remove marker")
        }
    }

    func testTaskListContinuation() {
        XCTAssertEqual(MarkdownEditCommands.listContinuation("- [ ] do", location: 8), .insert("\n- [ ] "))
    }

    func testIndentOutdent() {
        let indented = MarkdownEditCommands.indent("x", range: NSRange(location: 0, length: 1))
        XCTAssertEqual(indented.text, "  x")
        let out = MarkdownEditCommands.outdent(indented.text, range: NSRange(location: 0, length: 3))
        XCTAssertEqual(out.text, "x")
    }

    func testInsertLink() {
        let result = MarkdownEditCommands.insertLink("text", range: NSRange(location: 0, length: 4))
        XCTAssertEqual(result.text, "[text](url)")
    }
}
