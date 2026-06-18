import SwiftUI

enum MermaidColor {
    private static let named: [String: (Double, Double, Double)] = [
        "red": (1, 0, 0), "green": (0, 0.6, 0), "blue": (0, 0, 1), "black": (0, 0, 0),
        "white": (1, 1, 1), "yellow": (1, 0.84, 0), "orange": (1, 0.65, 0),
        "purple": (0.5, 0, 0.5), "gray": (0.5, 0.5, 0.5), "grey": (0.5, 0.5, 0.5),
        "lightblue": (0.68, 0.85, 0.9), "lightgreen": (0.56, 0.93, 0.56),
        "pink": (1, 0.75, 0.8), "cyan": (0, 1, 1),
    ]

    /// Parses `#rgb`, `#rrggbb`, or a CSS named color. Returns `nil` if unrecognized.
    static func parse(_ string: String) -> Color? {
        let s = string.trimmingCharacters(in: .whitespaces).lowercased()
        if s.hasPrefix("#") { return parseHex(String(s.dropFirst())) }
        if let rgb = named[s] { return Color(.sRGB, red: rgb.0, green: rgb.1, blue: rgb.2) }
        return nil
    }

    private static func parseHex(_ hex: String) -> Color? {
        var value = hex
        if value.count == 3 {
            value = value.map { "\($0)\($0)" }.joined()
        }
        guard value.count == 6, let int = UInt32(value, radix: 16) else { return nil }
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        return Color(.sRGB, red: r, green: g, blue: b)
    }
}
