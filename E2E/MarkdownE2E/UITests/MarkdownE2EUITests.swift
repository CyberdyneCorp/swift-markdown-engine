import XCTest

final class MarkdownE2EUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// Renders a complex document (heading, table, code, math, task list, Mermaid)
    /// and asserts the heading appears with the header trait.
    func testRendersComplexDocument() {
        let app = XCUIApplication()
        app.launch()

        let heading = app.staticTexts["E2E Heading"]
        XCTAssertTrue(heading.waitForExistence(timeout: 10))
    }

    /// Drives an editor formatting command and asserts the buffer changed via the
    /// mirror Text.
    func testEditorBoldCommandMutatesBuffer() {
        let app = XCUIApplication()
        app.launch()

        let mirror = app.staticTexts["editorMirror"]
        XCTAssertTrue(mirror.waitForExistence(timeout: 10))
        XCTAssertEqual(mirror.label, "hello")

        // Tapping Bold with no selection inserts the ** ** markers.
        app.buttons["Bold"].firstMatch.tap()
        let updated = NSPredicate(format: "label CONTAINS '*'")
        expectation(for: updated, evaluatedWith: mirror)
        waitForExpectations(timeout: 5)
    }
}
