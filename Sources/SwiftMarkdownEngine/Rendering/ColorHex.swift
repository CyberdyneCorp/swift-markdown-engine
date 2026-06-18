import SwiftUI

extension Color {
    /// Returns the color as a `#RRGGBB` string, falling back to a neutral value when
    /// components can't be resolved. Used to pass theme colors to a `LatexRenderer`.
    func hexString(fallback: String = "#1B1B1B") -> String {
        guard let components = cgColor?.components, components.count >= 3 else { return fallback }
        let r = Int((components[0] * 255).rounded())
        let g = Int((components[1] * 255).rounded())
        let b = Int((components[2] * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
