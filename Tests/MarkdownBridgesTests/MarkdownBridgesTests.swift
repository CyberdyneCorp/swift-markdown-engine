import XCTest
import SwiftMarkdownEngine
@testable import MarkdownEngineCodeBlocks
@testable import MarkdownEngineLatex

final class MarkdownBridgesTests: XCTestCase {
    // MARK: - Highlightr code bridge

    func testHighlightrProducesAttributedCode() {
        let highlighter = HighlightrSyntaxHighlighter(theme: "atom-one-dark")
        let result = highlighter.highlight("let x = 1", language: "swift")
        // The highlighted output preserves the source characters.
        XCTAssertEqual(String(result.characters), "let x = 1")
    }

    func testHighlightrAppliesColorAttributes() {
        let highlighter = HighlightrSyntaxHighlighter()
        let result = highlighter.highlight("func greet() {}", language: "swift")
        // Highlighting splits the code into multiple styled runs (colors live in the
        // AppKit/UIKit attribute scope, which SwiftUI Text honors). Plain text would
        // be a single run.
        XCTAssertGreaterThan(result.runs.count, 1)
    }

    func testHighlightrConformsToProtocol() {
        let highlighter: any SyntaxHighlighter = HighlightrSyntaxHighlighter()
        _ = highlighter.highlight("x", language: nil)
    }

    // MARK: - SwiftMath LaTeX bridge

    func testSwiftMathRendersValidLatex() {
        let renderer = SwiftMathLatexRenderer()
        let data = renderer.renderToPNG("x^2 + y^2", displayMode: true, pointSize: 20, hexColor: "#000000")
        XCTAssertNotNil(data)
        XCTAssertFalse(data!.isEmpty)
    }

    func testSwiftMathRendersFraction() {
        let renderer = SwiftMathLatexRenderer()
        XCTAssertNotNil(renderer.renderToPNG("\\frac{x^2}{y}", displayMode: true, pointSize: 18, hexColor: "#FFFFFF"))
    }

    func testSwiftMathConformsToProtocol() {
        let renderer: any LatexRenderer = SwiftMathLatexRenderer()
        _ = renderer.renderToPNG("a+b", displayMode: false, pointSize: 16, hexColor: "#1B1B1B")
    }
}
