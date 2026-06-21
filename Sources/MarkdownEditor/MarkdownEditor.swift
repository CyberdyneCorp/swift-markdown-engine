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
    private let toolbarItems: [MarkdownToolbarItem]
    private let wikiResolver: (any WikiLinkResolver)?
    private let pencilDoubleTap: ((MarkdownEditorController) -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var controller = MarkdownEditorController()

    /// - Parameters:
    ///   - toolbar: The toolbar items to show. Defaults to `MarkdownToolbarItem.default`.
    ///     Combine built-in items (`.bold`, `.italic`, …) with `.custom(...)` actions, or
    ///     pass `showsToolbar: false` to hide the toolbar entirely.
    ///   - onPencilDoubleTap: Action invoked on an Apple Pencil double-tap (iPad). Receives
    ///     the editor's command surface; defaults to toggling bold.
    public init(
        text: Binding<String>,
        theme: MarkdownTheme? = nil,
        showsToolbar: Bool = true,
        toolbar: [MarkdownToolbarItem]? = nil,
        wikiLinkResolver: (any WikiLinkResolver)? = nil,
        onPencilDoubleTap: ((MarkdownEditorController) -> Void)? = nil
    ) {
        self._text = text
        self.explicitTheme = theme
        self.showsToolbar = showsToolbar
        self.toolbarItems = toolbar ?? MarkdownToolbarItem.default
        self.wikiResolver = wikiLinkResolver
        self.pencilDoubleTap = onPencilDoubleTap
    }

    private var theme: MarkdownTheme {
        explicitTheme ?? (colorScheme == .dark ? .dark : .light)
    }

    public var body: some View {
        VStack(spacing: 0) {
            if showsToolbar {
                MarkdownEditorToolbar(items: toolbarItems, controller: controller, theme: theme)
                Divider()
            }
            MarkdownTextViewRepresentable(text: $text, theme: theme, controller: controller,
                                          wikiResolver: wikiResolver, pencilDoubleTap: pencilDoubleTap)
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
    let items: [MarkdownToolbarItem]
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
            ForEach(items) { item in view(for: item) }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func view(for item: MarkdownToolbarItem) -> some View {
        switch item.kind {
        case let .command(systemImage, label, shortcut, action):
            commandButton(systemImage, label, shortcut) { action(controller) }
        case let .menu(systemImage, label, items):
            Menu {
                ForEach(items) { sub in
                    if case let .command(_, label, _, action) = sub.kind {
                        Button(label, systemImage: menuSystemImage(sub)) { action(controller) }
                    }
                }
            } label: {
                Image(systemName: systemImage).foregroundStyle(theme.textPrimary)
            }
            .accessibilityLabel(label)
        case .divider:
            Divider().frame(height: 18)
        }
    }

    private func menuSystemImage(_ item: MarkdownToolbarItem) -> String {
        if case let .command(systemImage, _, _, _) = item.kind { return systemImage }
        return ""
    }

    @ViewBuilder
    private func commandButton(_ systemName: String, _ label: String, _ shortcut: Character?,
                               action: @escaping () -> Void) -> some View {
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
