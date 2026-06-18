import Foundation
import SwiftMarkdownEngine
import SwiftMath

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A `LatexRenderer` backed by SwiftMath's native CoreText typesetting. Renders
/// math to PNG data; returns `nil` for LaTeX it cannot parse so callers fall back
/// to the raw source.
public struct SwiftMathLatexRenderer: LatexRenderer {
    public init() {}

    public func renderToPNG(_ latex: String, displayMode: Bool, pointSize: Double, hexColor: String) -> Data? {
        let color = MTColor.fromHexString(hexColor) ?? MTColor.black
        let mathImage = MTMathImage(
            latex: latex,
            fontSize: CGFloat(pointSize),
            textColor: color,
            labelMode: displayMode ? .display : .text
        )
        let (error, image) = mathImage.asImage()
        guard error == nil, let image else { return nil }
        return Self.pngData(from: image)
    }

    private static func pngData(from image: MTImage) -> Data? {
        #if canImport(UIKit)
        return image.pngData()
        #elseif canImport(AppKit)
        guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }
}

private extension MTColor {
    /// Parses a `#RGB` or `#RRGGBB` string into a platform color.
    static func fromHexString(_ string: String) -> MTColor? {
        var hex = string.hasPrefix("#") ? String(string.dropFirst()) : string
        if hex.count == 3 { hex = hex.map { "\($0)\($0)" }.joined() }
        guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return nil }
        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >> 8) & 0xFF) / 255
        let b = CGFloat(value & 0xFF) / 255
        return MTColor(red: r, green: g, blue: b, alpha: 1)
    }
}
