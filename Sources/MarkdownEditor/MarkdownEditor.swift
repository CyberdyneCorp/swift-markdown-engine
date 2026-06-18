// The Markdown editor is available on iOS and macOS only; watchOS is render-only.
// The TextKit 2 implementation and SwiftUI bridge land in Phase 4 (tasks 10.1–10.9).

#if os(iOS) || os(macOS)
import SwiftUI
import SwiftMarkdownEngine

/// Placeholder for the TextKit 2 backed Markdown editor view.
///
/// > Note: Phase 4 implements the editor (live styling, formatting commands,
/// > interactive checkboxes, Apple Pencil on iPad). This stub establishes the
/// > public API surface and platform gating.
public struct MarkdownEditor: View {
    @Binding public var text: String

    public init(text: Binding<String>) {
        self._text = text
    }

    public var body: some View {
        // TODO(Phase 4): replace with the TextKit 2 editor wrapped via
        // UIViewRepresentable / NSViewRepresentable.
        TextEditor(text: $text)
            .font(.body.monospaced())
    }
}
#endif
