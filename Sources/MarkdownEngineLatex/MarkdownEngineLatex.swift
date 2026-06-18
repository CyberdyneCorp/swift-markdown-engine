import Foundation
import SwiftMarkdownEngine

// Optional bridge product adapting a LaTeX backend to the core `LatexRenderer`
// protocol. The real SwiftMath-backed implementation is wired in Phase 3
// (task 8.3); until then this provides a dependency-free stub so the product
// builds and can be adopted.

/// A `LatexRenderer` stub that cannot rasterize math yet and signals failure so
/// callers fall back to rendering the raw LaTeX source.
///
/// > Note: Phase 3 replaces the body with a SwiftMath-backed implementation and
/// > adds the SwiftMath package dependency to this target only.
public struct UnavailableLatexRenderer: LatexRenderer {
    public init() {}

    public func renderToPNG(_ latex: String, displayMode: Bool, pointSize: Double, hexColor: String) -> Data? {
        nil
    }
}
