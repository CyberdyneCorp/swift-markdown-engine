import XCTest

final class MarkdownE2EUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    /// Renders a complex document (heading, table, code, math, task list, Mermaid)
    /// and asserts the heading appears.
    func testRendersComplexDocument() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["E2E Heading"].waitForExistence(timeout: 10))
    }

    /// A toolbar formatting command wraps the typed text. Verifies the command fires
    /// even after the toolbar tap resigns the editor's first responder (iPad).
    func testEditorToolbarCommandMutatesBuffer() {
        let app = launch()
        let mirror = app.staticTexts["editorMirror"]
        XCTAssertTrue(mirror.waitForExistence(timeout: 10))

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText("hi")

        app.buttons["Strikethrough"].firstMatch.tap()
        expectation(for: NSPredicate(format: "label CONTAINS '~'"), evaluatedWith: mirror)
        waitForExpectations(timeout: 5)
    }

    /// Pressing Return on a list item continues the list with a new marker.
    func testSmartListContinuation() {
        let app = launch()
        let mirror = app.staticTexts["editorMirror"]
        XCTAssertTrue(mirror.waitForExistence(timeout: 10))

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText("- a\n")

        // Continuation inserts a second "- " marker (newlines ⏎, spaces ·).
        expectation(for: NSPredicate(format: "label CONTAINS '⏎-·'"), evaluatedWith: mirror)
        waitForExpectations(timeout: 5)
    }

    /// Typing `[[` shows wiki-link suggestions; selecting one inserts the target.
    func testWikiLinkCompletion() {
        let app = launch()
        let mirror = app.staticTexts["editorMirror"]
        XCTAssertTrue(mirror.waitForExistence(timeout: 10))

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText("[[Pa")

        let suggestion = app.buttons["Page One"]
        XCTAssertTrue(suggestion.waitForExistence(timeout: 5))
        suggestion.tap()

        expectation(for: NSPredicate(format: "label CONTAINS 'Page·One]]'"), evaluatedWith: mirror)
        waitForExpectations(timeout: 5)
    }

    /// The Toggle-checkbox toolbar command flips a task item's state.
    func testCheckboxToggleCommand() {
        let app = launch()
        let mirror = app.staticTexts["editorMirror"]
        XCTAssertTrue(mirror.waitForExistence(timeout: 10))

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText("- [ ] task")

        app.buttons["More"].firstMatch.tap()
        app.buttons["Toggle checkbox"].firstMatch.tap()
        expectation(for: NSPredicate(format: "label CONTAINS '[x]'"), evaluatedWith: mirror)
        waitForExpectations(timeout: 5)
    }

    /// The Indent toolbar command adds leading indentation to the current line.
    /// Indents the second line so the assertion targets mid-string whitespace
    /// (`⏎··b`, spaces rendered as ·); leading whitespace is trimmed from
    /// accessibility labels on iPhone.
    func testIndentCommand() {
        let app = launch()
        let mirror = app.staticTexts["editorMirror"]
        XCTAssertTrue(mirror.waitForExistence(timeout: 10))

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText("a\nb")

        app.buttons["More"].firstMatch.tap()
        app.buttons["Indent"].firstMatch.tap()
        expectation(for: NSPredicate(format: "label CONTAINS '⏎··b'"), evaluatedWith: mirror)
        waitForExpectations(timeout: 5)
    }
}
