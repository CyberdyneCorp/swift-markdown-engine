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

    /// Enters Edit mode, selects the first block, and opens its "Insert below" menu — waiting
    /// for the menu to actually appear (the "Paragraph" item) to avoid menu-animation races.
    private func openInsertBelowMenu(_ app: XCUIApplication) {
        select(mode: "Edit", in: app)
        let heading = app.staticTexts["Field Notes"]
        XCTAssertTrue(heading.waitForExistence(timeout: 10))
        heading.tap()
        let insert = app.buttons["Insert below"]
        XCTAssertTrue(insert.waitForExistence(timeout: 8), "Insert below not found")
        insert.tap()
        XCTAssertTrue(app.buttons["Paragraph"].waitForExistence(timeout: 6), "insert menu did not open")
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
        openInsertBelowMenu(app)
        app.buttons["Heading"].tap()
        XCTAssertTrue(app.staticTexts["Heading"].waitForExistence(timeout: 5),
                      "inserted heading block did not render")
    }

    // MARK: - Diagram builders (Phase 2)

    func testInsertPieChartOpensVisualBuilder() {
        let app = launch()
        openInsertBelowMenu(app)
        app.buttons["Pie chart"].tap()
        XCTAssertTrue(app.buttons["Slice"].waitForExistence(timeout: 5),
                      "pie-chart visual builder did not open")
    }

    func testInsertFlowchartOpensVisualBuilder() {
        let app = launch()
        openInsertBelowMenu(app)
        app.buttons["Flowchart"].tap()
        XCTAssertTrue(app.buttons["Node"].waitForExistence(timeout: 5),
                      "flowchart visual builder did not open")
    }

    func testInsertSequenceOpensVisualBuilder() {
        let app = launch()
        openInsertBelowMenu(app)
        app.buttons["Sequence"].tap()
        XCTAssertTrue(app.buttons["Participant"].waitForExistence(timeout: 5),
                      "sequence builder did not open")
    }

    func testInsertMindmapOpensVisualBuilder() {
        let app = launch()
        openInsertBelowMenu(app)
        app.buttons["Mindmap"].tap()
        XCTAssertTrue(app.buttons["Indent"].firstMatch.waitForExistence(timeout: 5),
                      "mindmap builder did not open")
    }

    func testInsertGanttOpensVisualBuilder() {
        let app = launch()
        openInsertBelowMenu(app)
        app.buttons["Gantt"].tap()
        XCTAssertTrue(app.buttons["Task"].waitForExistence(timeout: 5),
                      "gantt builder did not open")
    }

    private func insertAndExpectBuilder(_ app: XCUIApplication, item: String, addButton: String,
                                        file: StaticString = #filePath, line: UInt = #line) {
        openInsertBelowMenu(app)
        let menuItem = app.buttons[item]
        XCTAssertTrue(menuItem.waitForExistence(timeout: 5), "insert menu missing \(item)", file: file, line: line)
        menuItem.tap()
        XCTAssertTrue(app.buttons[addButton].waitForExistence(timeout: 5),
                      "\(item) builder did not open", file: file, line: line)
    }

    func testInsertClassDiagramOpensBuilder() { insertAndExpectBuilder(launch(), item: "Class diagram", addButton: "Class") }
    func testInsertStateDiagramOpensBuilder() { insertAndExpectBuilder(launch(), item: "State diagram", addButton: "Transition") }
    func testInsertERDiagramOpensBuilder() { insertAndExpectBuilder(launch(), item: "ER diagram", addButton: "Relationship") }
    func testInsertGitGraphOpensBuilder() { insertAndExpectBuilder(launch(), item: "Git graph", addButton: "Operation") }
    func testInsertJourneyOpensBuilder() { insertAndExpectBuilder(launch(), item: "Journey", addButton: "Step") }
    func testInsertTimelineOpensBuilder() { insertAndExpectBuilder(launch(), item: "Timeline", addButton: "Period") }

    // MARK: - Deeper coverage: the table editor

    private func openTableEditor(_ app: XCUIApplication) {
        openInsertBelowMenu(app)
        app.buttons["Table"].tap()
        XCTAssertTrue(app.buttons["Column"].waitForExistence(timeout: 5), "table editor did not open")
    }

    func testTableEditorAddsColumnAndRow() {
        let app = launch()
        openTableEditor(app)

        let initial = app.textFields.count
        app.buttons["Column"].tap()
        XCTAssertGreaterThan(app.textFields.count, initial, "adding a column did not add cells")

        let afterColumn = app.textFields.count
        app.buttons["Row"].tap()
        XCTAssertGreaterThan(app.textFields.count, afterColumn, "adding a row did not add cells")
    }

    func testTableEditorEditsACell() {
        let app = launch()
        openTableEditor(app)
        let cell = app.textFields.element(boundBy: 0)
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        cell.tap()
        cell.typeText("Z")
        XCTAssertTrue((cell.value as? String ?? "").contains("Z"), "cell edit did not register")
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
