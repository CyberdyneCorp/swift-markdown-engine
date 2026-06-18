// The Markdown editor is available on iOS and macOS only; watchOS is render-only.

#if os(iOS) || os(macOS)
import SwiftUI
import SwiftMarkdownEngine

/// A native Markdown source editor built on TextKit 2 and bridged to SwiftUI. It
/// edits raw Markdown while applying live syntax styling, and exposes formatting
/// commands via a toolbar and keyboard shortcuts.
public struct MarkdownEditor: View {
    @Binding private var text: String
    private let explicitTheme: MarkdownTheme?
    private let showsToolbar: Bool

    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var controller = MarkdownEditorController()

    public init(text: Binding<String>, theme: MarkdownTheme? = nil, showsToolbar: Bool = true) {
        self._text = text
        self.explicitTheme = theme
        self.showsToolbar = showsToolbar
    }

    private var theme: MarkdownTheme {
        explicitTheme ?? (colorScheme == .dark ? .dark : .light)
    }

    public var body: some View {
        VStack(spacing: 0) {
            if showsToolbar {
                MarkdownEditorToolbar(controller: controller, theme: theme)
                Divider()
            }
            MarkdownTextViewRepresentable(text: $text, theme: theme, controller: controller)
        }
        .background(theme.background)
    }
}

/// The formatting toolbar. Buttons drive the shared controller; common commands
/// also bind to keyboard shortcuts.
struct MarkdownEditorToolbar: View {
    @ObservedObject var controller: MarkdownEditorController
    let theme: MarkdownTheme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                button("bold", "Bold", "b") { controller.toggleBold() }
                button("italic", "Italic", "i") { controller.toggleItalic() }
                button("strikethrough", "Strikethrough", nil) { controller.toggleStrikethrough() }
                button("chevron.left.forwardslash.chevron.right", "Inline code", nil) { controller.toggleInlineCode() }
                Divider().frame(height: 18)
                button("number", "Heading", nil) { controller.setHeading(2) }
                button("list.bullet", "Bullet list", nil) { controller.toggleBulletList() }
                button("checklist", "Task list", nil) { controller.toggleTaskList() }
                button("checkmark.square", "Toggle checkbox", nil) { controller.toggleCheckbox() }
                button("text.quote", "Quote", nil) { controller.toggleQuote() }
                button("link", "Link", "k") { controller.insertLink() }
                Divider().frame(height: 18)
                button("decrease.indent", "Outdent", nil) { controller.outdent() }
                button("increase.indent", "Indent", nil) { controller.indent() }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(theme.surface)
    }

    @ViewBuilder
    private func button(_ systemName: String, _ label: String, _ shortcut: Character?, action: @escaping () -> Void) -> some View {
        let view = Button(action: action) {
            Image(systemName: systemName).foregroundStyle(theme.textPrimary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)

        if let shortcut {
            view.keyboardShortcut(KeyEquivalent(shortcut), modifiers: .command)
        } else {
            view
        }
    }
}
#endif
