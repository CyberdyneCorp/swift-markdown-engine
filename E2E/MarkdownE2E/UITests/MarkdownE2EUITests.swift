import XCTest

final class MarkdownE2EUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    /// Activates an element (tap on iOS, click on macOS).
    private func activate(_ element: XCUIElement) {
        #if os(macOS)
        element.click()
        #else
        element.tap()
        #endif
    }

    /// An overflow-menu item: a button on iOS, a menu item on macOS.
    private func menuItem(_ app: XCUIApplication, _ label: String) -> XCUIElement {
        #if os(macOS)
        return app.menuItems[label]
        #else
        return app.buttons[label]
        #endif
    }

    /// A predicate matching either `label` or `value` — Text content surfaces as the
    /// accessibility label on iOS but as the value on macOS.
    private func contains(_ substring: String) -> NSPredicate {
        NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", substring, substring)
    }

    /// Renders a complex document (heading, table, code, math, task list, Mermaid)
    /// and asserts the heading appears.
    func testRendersComplexDocument() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["E2E Heading"].waitForExistence(timeout: 10))
    }

    /// A toolbar formatting command wraps the typed text (Strikethrough → ~~ ~~).
    func testEditorToolbarCommandMutatesBuffer() {
        let app = launch()
        let mirror = app.staticTexts["editorMirror"]
        XCTAssertTrue(mirror.waitForExistence(timeout: 10))

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        activate(editor)
        editor.typeText("hi")

        activate(app.buttons["Strikethrough"].firstMatch)
        expectation(for: contains("~"), evaluatedWith: mirror)
        waitForExpectations(timeout: 5)
    }

    /// Pressing Return on a list item continues the list with a new marker.
    func testSmartListContinuation() {
        let app = launch()
        let mirror = app.staticTexts["editorMirror"]
        XCTAssertTrue(mirror.waitForExistence(timeout: 10))

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        activate(editor)
        editor.typeText("- a\n")

        // Continuation inserts a second "- " marker (newlines ⏎, spaces ·).
        expectation(for: contains("⏎-·"), evaluatedWith: mirror)
        waitForExpectations(timeout: 5)
    }

    /// Typing `[[` shows wiki-link suggestions; selecting one inserts the target.
    func testWikiLinkCompletion() {
        let app = launch()
        let mirror = app.staticTexts["editorMirror"]
        XCTAssertTrue(mirror.waitForExistence(timeout: 10))

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        activate(editor)
        editor.typeText("[[Pa")

        let suggestion = app.buttons["Page One"]
        XCTAssertTrue(suggestion.waitForExistence(timeout: 5))
        activate(suggestion)

        expectation(for: contains("Page·One]]"), evaluatedWith: mirror)
        waitForExpectations(timeout: 5)
    }

    /// The Toggle-checkbox command (overflow menu) flips a task item's state.
    func testCheckboxToggleCommand() throws {
        #if os(macOS)
        throw XCTSkip("SwiftUI Menu items aren't reliably drivable via XCUITest on macOS; covered on iOS/iPad and by MarkdownEditCommands unit tests.")
        #endif
        let app = launch()
        let mirror = app.staticTexts["editorMirror"]
        XCTAssertTrue(mirror.waitForExistence(timeout: 10))

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        activate(editor)
        editor.typeText("- [ ] task")

        activate(app.buttons["More"].firstMatch)
        let item = menuItem(app, "Toggle checkbox")
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        activate(item)

        expectation(for: contains("[x]"), evaluatedWith: mirror)
        waitForExpectations(timeout: 5)
    }

    /// The Indent command (overflow menu) adds indentation to the current line.
    /// Indents the second line so the assertion targets mid-string whitespace
    /// (`⏎··b`, spaces rendered as ·); leading whitespace is trimmed from
    /// accessibility labels on iPhone.
    func testIndentCommand() throws {
        #if os(macOS)
        throw XCTSkip("SwiftUI Menu items aren't reliably drivable via XCUITest on macOS; covered on iOS/iPad and by MarkdownEditCommands unit tests.")
        #endif
        let app = launch()
        let mirror = app.staticTexts["editorMirror"]
        XCTAssertTrue(mirror.waitForExistence(timeout: 10))

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        activate(editor)
        editor.typeText("a\nb")

        activate(app.buttons["More"].firstMatch)
        let item = menuItem(app, "Indent")
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        activate(item)

        expectation(for: contains("⏎··b"), evaluatedWith: mirror)
        waitForExpectations(timeout: 5)
    }
}
