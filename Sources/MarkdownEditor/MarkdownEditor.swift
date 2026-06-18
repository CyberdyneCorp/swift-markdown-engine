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
    private let wikiResolver: (any WikiLinkResolver)?

    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var controller = MarkdownEditorController()

    public init(
        text: Binding<String>,
        theme: MarkdownTheme? = nil,
        showsToolbar: Bool = true,
        wikiLinkResolver: (any WikiLinkResolver)? = nil
    ) {
        self._text = text
        self.explicitTheme = theme
        self.showsToolbar = showsToolbar
        self.wikiResolver = wikiLinkResolver
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
            MarkdownTextViewRepresentable(text: $text, theme: theme, controller: controller, wikiResolver: wikiResolver)
                .frame(maxWidth: theme.readingWidth ?? .infinity) // reading column
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topLeading) { wikiSuggestionsOverlay }
        }
        .background(theme.background)
    }

    @ViewBuilder private var wikiSuggestionsOverlay: some View {
        if !controller.wikiSuggestions.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(controller.wikiSuggestions.prefix(6), id: \.identifier) { target in
                    Button {
                        controller.completeWiki(target)
                    } label: {
                        HStack {
                            Text(target.title).foregroundStyle(theme.textPrimary)
                            if !target.exists { Text("new").font(.caption2).foregroundStyle(theme.textSecondary) }
                            Spacer()
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
            .frame(maxWidth: 260, alignment: .leading)
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.border))
            .padding(8)
        }
    }
}

/// The formatting toolbar. Buttons drive the shared controller; common commands
/// also bind to keyboard shortcuts.
struct MarkdownEditorToolbar: View {
    @ObservedObject var controller: MarkdownEditorController
    let theme: MarkdownTheme

    var body: some View {
        // Use the full row when it fits (e.g. iPad / wide windows) and only fall back
        // to a horizontal ScrollView when space is tight (narrow iPhones). A plain row
        // keeps the buttons reliably tappable; buttons inside a ScrollView can have
        // their taps swallowed by the scroll gesture on iPad.
        ViewThatFits(in: .horizontal) {
            buttonRow
            ScrollView(.horizontal, showsIndicators: false) { buttonRow }
        }
        .background(theme.surface)
    }

    private var buttonRow: some View {
        HStack(spacing: 14) {
            button("bold", "Bold", "b") { controller.toggleBold() }
            button("italic", "Italic", "i") { controller.toggleItalic() }
            button("strikethrough", "Strikethrough", nil) { controller.toggleStrikethrough() }
            button("chevron.left.forwardslash.chevron.right", "Inline code", nil) { controller.toggleInlineCode() }
            Divider().frame(height: 18)
            button("number", "Heading", nil) { controller.setHeading(2) }
            button("list.bullet", "Bullet list", nil) { controller.toggleBulletList() }
            button("link", "Link", "k") { controller.insertLink() }
            Divider().frame(height: 18)
            overflowMenu
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    /// Less-common commands live in an overflow menu so the toolbar fits inline
    /// (and every command stays reliably reachable).
    private var overflowMenu: some View {
        Menu {
            Button("Task list", systemImage: "checklist") { controller.toggleTaskList() }
            Button("Toggle checkbox", systemImage: "checkmark.square") { controller.toggleCheckbox() }
            Button("Quote", systemImage: "text.quote") { controller.toggleQuote() }
            Button("Outdent", systemImage: "decrease.indent") { controller.outdent() }
            Button("Indent", systemImage: "increase.indent") { controller.indent() }
        } label: {
            Image(systemName: "ellipsis.circle").foregroundStyle(theme.textPrimary)
        }
        .accessibilityLabel("More")
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
