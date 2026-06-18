#if os(iOS) || os(macOS)
import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformFont = UIFont
typealias PlatformColor = UIColor
typealias PlatformTextView = UITextView
#elseif canImport(AppKit)
import AppKit
typealias PlatformFont = NSFont
typealias PlatformColor = NSColor
typealias PlatformTextView = NSTextView
#endif

extension PlatformColor {
    /// Bridges a SwiftUI `Color` to the platform color type.
    static func from(_ color: Color) -> PlatformColor {
        PlatformColor(color)
    }
}

enum EditorFont {
    static func body(_ size: CGFloat = 17) -> PlatformFont { PlatformFont.systemFont(ofSize: size) }
    static func monospaced(_ size: CGFloat = 15) -> PlatformFont { PlatformFont.monospacedSystemFont(ofSize: size, weight: .regular) }
    static func bold(_ size: CGFloat = 17) -> PlatformFont { PlatformFont.boldSystemFont(ofSize: size) }
    static func heading(level: Int) -> PlatformFont {
        let size: CGFloat
        switch level {
        case 1: size = 28
        case 2: size = 24
        case 3: size = 21
        case 4: size = 19
        default: size = 17
        }
        return PlatformFont.boldSystemFont(ofSize: size)
    }
    static func italic(_ size: CGFloat = 17) -> PlatformFont {
        #if canImport(UIKit)
        let descriptor = PlatformFont.systemFont(ofSize: size).fontDescriptor.withSymbolicTraits(.traitItalic)
        return descriptor.map { PlatformFont(descriptor: $0, size: size) } ?? PlatformFont.systemFont(ofSize: size)
        #else
        return NSFontManager.shared.convert(PlatformFont.systemFont(ofSize: size), toHaveTrait: .italicFontMask)
        #endif
    }
}
#endif
