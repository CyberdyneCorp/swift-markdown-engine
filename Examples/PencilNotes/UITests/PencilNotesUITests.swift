import XCTest

/// End-to-end UI tests for the PencilNotes app, designed to run on an iPad (real device when
/// connected, otherwise an iPad simulator — see scripts/test-pencilnotes-ipad.sh). They drive
/// the real UI to surface crashes and regressions across the app's features: the three editing
/// modes, live preview rendering, and the WYSIWYG block editor (selection, formatting, insert).
final class PencilNotesUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @discardableResult
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    /// The segmented Raw | Preview | Edit control.
    private func modes(_ app: XCUIApplication) -> XCUIElement {
        app.segmentedControls.firstMatch
    }

    private func select(mode: String, in app: XCUIApplication) {
        let seg = modes(app)
        XCTAssertTrue(seg.waitForExistence(timeout: 10), "mode switch not found")
        let button = seg.buttons[mode]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "mode '\(mode)' not found")
        button.tap()
    }

    // MARK: - Launch & modes

    func testLaunchRendersWithoutCrashing() {
        let app = launch()
        // Launching renders the sample document (a crash smoke check). "Field Notes" is the
        // first heading and is on-screen at the top in every mode.
        XCTAssertTrue(app.staticTexts["Field Notes"].waitForExistence(timeout: 15),
                      "app did not render the sample on launch")
    }

    func testSwitchAcrossAllThreeModes() {
        let app = launch()

        select(mode: "Preview", in: app)
        XCTAssertTrue(app.staticTexts["Field Notes"].waitForExistence(timeout: 8),
                      "Preview did not render the sample heading")

        select(mode: "Raw", in: app)
        XCTAssertTrue(app.textViews.firstMatch.waitForExistence(timeout: 8),
                      "Raw editor text view did not appear")

        select(mode: "Edit", in: app)
        // Prove Edit mode by selecting a block and seeing the (Edit-only) formatting toolbar.
        let heading = app.staticTexts["Field Notes"]
        XCTAssertTrue(heading.waitForExistence(timeout: 8))
        heading.tap()
        XCTAssertTrue(app.buttons["Bold"].waitForExistence(timeout: 5),
                      "Edit mode formatting toolbar did not appear")
    }

    // MARK: - Preview rendering

    func testPreviewRendersSampleContent() {
        let app = launch()
        select(mode: "Preview", in: app)
        XCTAssertTrue(app.staticTexts["Field Notes"].waitForExistence(timeout: 8))
        // A few more anchors from the sample document.
        XCTAssertTrue(exists(app, containing: "Checklist"), "preview missing the Checklist section")
        XCTAssertTrue(exists(app, containing: "Mindmap"), "preview missing the Mindmap section")
    }

    // MARK: - WYSIWYG editor

    func testSelectingTextBlockRevealsFormattingToolbar() {
        let app = launch()
        select(mode: "Edit", in: app)
        let heading = app.staticTexts["Field Notes"]
        XCTAssertTrue(heading.waitForExistence(timeout: 8))
        heading.tap()  // select the block
        XCTAssertTrue(app.buttons["Bold"].waitForExistence(timeout: 5),
                      "formatting toolbar (Bold) did not appear after selecting a text block")
    }

    func testInsertHeadingBlock() {
        let app = launch()
        select(mode: "Edit", in: app)
        // Select the first block to reveal its on-screen "Insert below" menu (the bottom
        // "Add block" button is off-screen in the long sample's lazy stack).
        let heading = app.staticTexts["Field Notes"]
        XCTAssertTrue(heading.waitForExistence(timeout: 8))
        heading.tap()
        let insert = app.buttons["Insert below"]
        XCTAssertTrue(insert.waitForExistence(timeout: 5), "Insert below menu not found")
        insert.tap()
        let headingItem = app.buttons["Heading"]
        XCTAssertTrue(headingItem.waitForExistence(timeout: 5), "insert menu did not open")
        headingItem.tap()
        XCTAssertTrue(app.staticTexts["Heading"].waitForExistence(timeout: 5),
                      "inserted heading block did not render")
    }

    // MARK: - Chrome

    func testDarkModeToggle() {
        let app = launch()
        let toDark = app.buttons["Switch to dark mode"]
        XCTAssertTrue(toDark.waitForExistence(timeout: 8))
        toDark.tap()
        XCTAssertTrue(app.buttons["Switch to light mode"].waitForExistence(timeout: 5),
                      "dark-mode toggle did not flip")
    }

    // MARK: - Helpers

    private func exists(_ app: XCUIApplication, containing text: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        return app.staticTexts.containing(predicate).firstMatch.waitForExistence(timeout: 5)
    }
}
