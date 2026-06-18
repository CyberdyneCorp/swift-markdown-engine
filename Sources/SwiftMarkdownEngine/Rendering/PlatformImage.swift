import SwiftUI

#if canImport(UIKit)
import UIKit
func makeImage(from data: Data) -> Image? {
    UIImage(data: data).map { Image(uiImage: $0) }
}
#elseif canImport(AppKit)
import AppKit
func makeImage(from data: Data) -> Image? {
    NSImage(data: data).map { Image(nsImage: $0) }
}
#else
func makeImage(from data: Data) -> Image? { nil }
#endif
