import SwiftUI

// `scale` matters for images drawn at the device's screen scale and then round-tripped
// through PNG data (which discards the scale). The math renderer does exactly this: it
// rasterizes at 2×/3×, so the bytes must be decoded at that same scale or the formula
// displays 2–3× too large. Bitmaps already at their natural resolution (e.g. downloaded
// photos shown `.resizable()`) keep the default scale of 1.
#if canImport(UIKit)
import UIKit
func makeImage(from data: Data, scale: CGFloat = 1) -> Image? {
    UIImage(data: data, scale: scale).map { Image(uiImage: $0) }
}
#elseif canImport(AppKit)
import AppKit
func makeImage(from data: Data, scale: CGFloat = 1) -> Image? {
    guard scale != 1, let rep = NSBitmapImageRep(data: data) else {
        return NSImage(data: data).map { Image(nsImage: $0) }
    }
    let image = NSImage(size: NSSize(width: CGFloat(rep.pixelsWide) / scale,
                                     height: CGFloat(rep.pixelsHigh) / scale))
    image.addRepresentation(rep)
    return Image(nsImage: image)
}
#else
func makeImage(from data: Data, scale: CGFloat = 1) -> Image? { nil }
#endif
