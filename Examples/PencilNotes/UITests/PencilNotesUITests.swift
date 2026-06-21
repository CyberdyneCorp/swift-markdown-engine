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

    // MARK: - Continuous Live editor

    func testLiveModeLaunchesAndShowsDocument() {
        let app = launch()
        select(mode: "Live", in: app)
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 15), "Live editor did not appear")
        XCTAssertTrue((editor.value as? String ?? "").contains("Field Notes"),
                      "Live editor did not show the sample content")
    }

    func testLiveToolbarPresent() {
        let app = launch()
        select(mode: "Live", in: app)
        XCTAssertTrue(app.buttons["Bold"].waitForExistence(timeout: 12), "Live toolbar Bold missing")
        XCTAssertTrue(app.buttons["Italic"].exists, "Live toolbar Italic missing")
        XCTAssertTrue(app.buttons["Strikethrough"].exists, "Live toolbar Strikethrough missing")
        XCTAssertTrue(app.buttons["Code"].exists, "Live toolbar Code missing")
        XCTAssertTrue(app.buttons["Link"].exists, "Live toolbar Link missing")
        XCTAssertTrue(app.buttons["Insert"].exists, "Live toolbar Insert missing")
    }

    func testLiveTypingReconstructsSource() {
        let app = launch()
        select(mode: "Live", in: app)
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 12))
        // Tap near the top (heading/intro text) to focus the keyboard — the center of the
        // document is a rendered block image, which isn't editable text.
        editor.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.03)).tap()
        editor.typeText("ZZZUNIQUEMARK")
        // Round-trips to the shared Markdown — visible in Raw mode.
        select(mode: "Raw", in: app)
        let raw = app.textViews.firstMatch
        XCTAssertTrue(raw.waitForExistence(timeout: 6))
        XCTAssertTrue((raw.value as? String ?? "").contains("ZZZUNIQUEMARK"),
                      "text typed in Live did not reach the source")
    }

    /// Regression: flat lists render as inline-editable text in Live mode, so they must survive
    /// source reconstruction. Typing (which reconstructs the whole document) must not corrupt or
    /// drop the checklist items.
    func testLiveListRoundTripPreservesChecklist() {
        let app = launch()
        select(mode: "Live", in: app)
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 12))
        editor.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.03)).tap()
        editor.typeText("Z")   // forces a full Markdown reconstruction
        select(mode: "Raw", in: app)
        let raw = app.textViews.firstMatch
        XCTAssertTrue(raw.waitForExistence(timeout: 6))
        let src = raw.value as? String ?? ""
        XCTAssertTrue(src.contains("- [x] Set up the easel"),
                      "checklist item lost through Live list reconstruction")
        XCTAssertTrue(src.contains("- [ ] Add color"),
                      "checklist item lost through Live list reconstruction")
    }

    /// Opens the Live editor's Insert menu and taps `label`. For diagram types it first opens the
    /// nested "Diagram" submenu.
    private func liveInsert(_ app: XCUIApplication, _ label: String, viaDiagram: Bool = false,
                            file: StaticString = #filePath, line: UInt = #line) {
        let insert = app.buttons["Insert"]
        XCTAssertTrue(insert.waitForExistence(timeout: 8), "Insert button missing", file: file, line: line)
        insert.tap()
        if viaDiagram {
            let submenu = app.buttons["Diagram"]
            XCTAssertTrue(submenu.waitForExistence(timeout: 6), "Diagram submenu missing", file: file, line: line)
            submenu.tap()
        }
        let item = app.buttons[label]
        XCTAssertTrue(item.waitForExistence(timeout: 6), "Insert menu item '\(label)' missing", file: file, line: line)
        item.tap()
    }

    /// Inserting every non-diagram block from the Live editor's Insert menu writes the expected
    /// Markdown to the shared source.
    func testLiveInsertAllBlocksReachSource() {
        let app = launch()
        select(mode: "Live", in: app)
        XCTAssertTrue(app.buttons["Insert"].waitForExistence(timeout: 12))

        // (menu label, expected Markdown snippet in the source)
        let blocks: [(String, String)] = [
            ("Bulleted list", "- Item"),
            ("Numbered list", "1. Item"),
            ("Checklist", "- [ ] Task"),
            ("Quote", "> Quote"),
            ("Table", "| A | B |"),
            ("Code block", "```swift"),
            ("Math", "E = mc^2"),
            ("Image", "![alt]"),
            ("Video", "mov_bbb.mp4"),
        ]
        for (label, _) in blocks { liveInsert(app, label) }

        select(mode: "Raw", in: app)
        let raw = app.textViews.firstMatch
        XCTAssertTrue(raw.waitForExistence(timeout: 6))
        let src = raw.value as? String ?? ""
        for (label, expected) in blocks {
            XCTAssertTrue(src.contains(expected), "Insert '\(label)' did not reach the source (expected '\(expected)')")
        }
    }

    /// Inserting every Mermaid diagram type from the Insert menu's Diagram submenu writes the
    /// expected diagram source.
    func testLiveInsertAllDiagramsReachSource() {
        let app = launch()
        select(mode: "Live", in: app)
        XCTAssertTrue(app.buttons["Insert"].waitForExistence(timeout: 12))

        // (submenu label, expected mermaid header in the source)
        let diagrams: [(String, String)] = [
            ("Flowchart", "flowchart LR"),
            ("Pie chart", "pie title Chart"),
            ("Sequence", "sequenceDiagram"),
            ("Mindmap", "mindmap"),
            ("Gantt", "gantt"),
            ("Class diagram", "classDiagram"),
            ("State diagram", "stateDiagram-v2"),
            ("ER diagram", "erDiagram"),
            ("Git graph", "gitGraph"),
            ("Journey", "journey"),
            ("Timeline", "timeline"),
        ]
        for (label, _) in diagrams { liveInsert(app, label, viaDiagram: true) }

        select(mode: "Raw", in: app)
        let raw = app.textViews.firstMatch
        XCTAssertTrue(raw.waitForExistence(timeout: 6))
        let src = raw.value as? String ?? ""
        for (label, expected) in diagrams {
            XCTAssertTrue(src.contains(expected), "Insert diagram '\(label)' did not reach the source (expected '\(expected)')")
        }
    }

    /// Inserting with the cursor near the top places the block in the middle of the document
    /// (after the current paragraph), not appended at the end.
    func testLiveInsertHappensAtCursorNotEnd() {
        let app = launch()
        select(mode: "Live", in: app)
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 12))
        // Place the cursor near the top. The first tap only focuses (caret defaults to the end);
        // a second tap positions the caret near the top but pops up the iPad edit menu, whose
        // full-screen dismiss region blocks the toolbar — so dismiss it before opening Insert.
        editor.coordinate(withNormalizedOffset: CGVector(dx: 0.20, dy: 0.05)).tap()  // focus (scrolls to end)
        Thread.sleep(forTimeInterval: 0.5)
        for _ in 0..<12 { editor.swipeDown() }                                       // scroll back to the top
        Thread.sleep(forTimeInterval: 0.5)
        editor.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.05)).tap()  // position caret in the top text
        Thread.sleep(forTimeInterval: 0.5)
        editor.typeText(" ")   // typing dismisses the edit-menu popover and keeps the caret near the top
        Thread.sleep(forTimeInterval: 0.3)
        liveInsert(app, "Table")

        select(mode: "Raw", in: app)
        let src = app.textViews.firstMatch.value as? String ?? ""
        guard let table = src.range(of: "| A | B |"), let checklist = src.range(of: "Checklist") else {
            XCTFail("source missing the inserted table or the Checklist section")
            return
        }
        XCTAssertTrue(table.lowerBound < checklist.lowerBound,
                      "table inserted near the top should appear before the Checklist section, not appended at the end")
    }

    func testLiveToolbarActionsDoNotCrash() {
        let app = launch()
        select(mode: "Live", in: app)
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 12))
        editor.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.03)).tap()
        for label in ["Bold", "Italic", "Strikethrough", "Code", "Link"] where app.buttons[label].exists {
            app.buttons[label].tap()
        }
        XCTAssertTrue(editor.exists, "Live editor disappeared after toolbar actions (possible crash)")
    }

    /// Diagnostic: navigate to Live mode and capture screenshots down the document so the
    /// rendering (e.g. cropped blocks) can be inspected. Run explicitly with -only-testing.
    func testCaptureLiveScreenshots() {
        let app = launch()
        select(mode: "Live", in: app)
        XCTAssertTrue(app.textViews.firstMatch.waitForExistence(timeout: 15))
        Thread.sleep(forTimeInterval: 4)   // let async block views (images/video/diagrams) render
        capture(app, "live-00-top")
        for i in 1...6 {
            app.swipeUp()
            Thread.sleep(forTimeInterval: 1.2)
            capture(app, String(format: "live-%02d", i))
        }
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
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
