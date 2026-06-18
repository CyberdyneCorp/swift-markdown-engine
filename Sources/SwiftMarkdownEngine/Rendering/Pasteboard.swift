#if os(iOS) || os(visionOS)
import UIKit
func copyToPasteboard(_ string: String) {
    UIPasteboard.general.string = string
}
#elseif os(macOS)
import AppKit
func copyToPasteboard(_ string: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(string, forType: .string)
}
#else
func copyToPasteboard(_ string: String) {}
#endif
