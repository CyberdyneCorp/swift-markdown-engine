import XCTest
@testable import MarkdownEditor

final class MarkdownEditorTests: XCTestCase {
    // The editor target builds on iOS and macOS only; on watchOS there is no API
    // surface to test. Phase 4 adds behavior tests for commands, list continuation,
    // checkbox toggling, suppression ranges, and Scribble.
    func testEditorTargetBuilds() {
        #if os(iOS) || os(macOS)
        XCTAssertTrue(true)
        #else
        XCTAssertTrue(true)
        #endif
    }
}
