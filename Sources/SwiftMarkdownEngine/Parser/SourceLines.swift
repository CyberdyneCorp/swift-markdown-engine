import Foundation

/// A single source line with the UTF-8 byte offsets it occupies, used to attach
/// `SourceRange`s to parsed nodes.
struct SourceLine: Sendable {
    /// Line text without its trailing newline.
    let text: String
    /// UTF-8 offset of the first byte of the line.
    let start: Int
    /// UTF-8 offset just past the line's content (before the newline, if any).
    let contentEnd: Int

    /// `text` with leading whitespace removed.
    var trimmedLeft: Substring { text.drop { $0 == " " || $0 == "\t" } }

    /// Number of leading spaces (tabs counted as one for indent detection).
    var indent: Int {
        var count = 0
        for ch in text {
            if ch == " " || ch == "\t" { count += 1 } else { break }
        }
        return count
    }

    /// Whether the line is empty or only whitespace.
    var isBlank: Bool { text.allSatisfy { $0 == " " || $0 == "\t" } }
}

enum SourceLines {
    /// Splits `source` into lines while tracking UTF-8 byte offsets. The newline is
    /// excluded from each line's content but accounted for in the running offset.
    static func split(_ source: String) -> [SourceLine] {
        var lines: [SourceLine] = []
        var offset = 0
        var lineStart = 0
        var buffer = ""

        func flush(byteLength: Int) {
            lines.append(SourceLine(text: buffer, start: lineStart, contentEnd: lineStart + byteLength))
            buffer = ""
        }

        for character in source {
            if character == "\n" {
                flush(byteLength: offset - lineStart)
                offset += 1 // the newline byte
                lineStart = offset
            } else {
                buffer.append(character)
                offset += character.utf8.count
            }
        }
        // Trailing content without a final newline.
        if lineStart < offset || !buffer.isEmpty {
            flush(byteLength: offset - lineStart)
        }
        return lines
    }
}
