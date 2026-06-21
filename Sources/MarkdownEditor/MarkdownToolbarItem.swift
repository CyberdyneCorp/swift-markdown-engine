#if os(iOS) || os(macOS)
import SwiftUI

/// One item in a `MarkdownEditor` toolbar. Use the built-in items (`.bold`, `.italic`, …),
/// group less-common ones in a `.menu`, separate groups with `.divider`, and add app-specific
/// actions with `.custom`. Pass an array to `MarkdownEditor(text:toolbar:)`.
public struct MarkdownToolbarItem: Identifiable, Sendable {
    public let id: String

    enum Kind: Sendable {
        case command(systemImage: String, label: String, shortcut: Character?, action: @Sendable @MainActor (MarkdownEditorController) -> Void)
        case menu(systemImage: String, label: String, items: [MarkdownToolbarItem])
        case divider
    }
    let kind: Kind

    private init(id: String, kind: Kind) {
        self.id = id
        self.kind = kind
    }

    /// A formatting command. `action` receives the editor's controller.
    public static func command(id: String, systemImage: String, label: String,
                               shortcut: Character? = nil,
                               action: @escaping @Sendable @MainActor (MarkdownEditorController) -> Void) -> MarkdownToolbarItem {
        MarkdownToolbarItem(id: id, kind: .command(systemImage: systemImage, label: label, shortcut: shortcut, action: action))
    }

    /// An app-specific toolbar button. Identical to `command` but named for host clarity.
    public static func custom(id: String, systemImage: String, label: String,
                              shortcut: Character? = nil,
                              action: @escaping @Sendable @MainActor (MarkdownEditorController) -> Void) -> MarkdownToolbarItem {
        .command(id: id, systemImage: systemImage, label: label, shortcut: shortcut, action: action)
    }

    /// A submenu (e.g. for less-common commands), shown as an overflow/ellipsis button.
    public static func menu(id: String = "menu", systemImage: String = "ellipsis.circle",
                            label: String = "More", _ items: [MarkdownToolbarItem]) -> MarkdownToolbarItem {
        MarkdownToolbarItem(id: id, kind: .menu(systemImage: systemImage, label: label, items: items))
    }

    /// A visual separator between groups of items.
    public static let divider = MarkdownToolbarItem(id: "divider", kind: .divider)

    // MARK: Built-in commands

    public static let bold = command(id: "bold", systemImage: "bold", label: "Bold", shortcut: "b") { $0.toggleBold() }
    public static let italic = command(id: "italic", systemImage: "italic", label: "Italic", shortcut: "i") { $0.toggleItalic() }
    public static let strikethrough = command(id: "strikethrough", systemImage: "strikethrough", label: "Strikethrough") { $0.toggleStrikethrough() }
    public static let inlineCode = command(id: "inlineCode", systemImage: "chevron.left.forwardslash.chevron.right", label: "Inline code") { $0.toggleInlineCode() }
    public static let link = command(id: "link", systemImage: "link", label: "Link", shortcut: "k") { $0.insertLink() }
    public static let bulletList = command(id: "bulletList", systemImage: "list.bullet", label: "Bullet list") { $0.toggleBulletList() }
    public static let taskList = command(id: "taskList", systemImage: "checklist", label: "Task list") { $0.toggleTaskList() }
    public static let toggleCheckbox = command(id: "toggleCheckbox", systemImage: "checkmark.square", label: "Toggle checkbox") { $0.toggleCheckbox() }
    public static let quote = command(id: "quote", systemImage: "text.quote", label: "Quote") { $0.toggleQuote() }
    public static let indent = command(id: "indent", systemImage: "increase.indent", label: "Indent") { $0.indent() }
    public static let outdent = command(id: "outdent", systemImage: "decrease.indent", label: "Outdent") { $0.outdent() }

    /// A heading command for the given level (1–6).
    public static func heading(level: Int = 2) -> MarkdownToolbarItem {
        command(id: "heading\(level)", systemImage: "number", label: "Heading \(level)") { $0.setHeading(level) }
    }

    /// The default toolbar — the set shipped before toolbars were customizable.
    public static let `default`: [MarkdownToolbarItem] = [
        .bold, .italic, .strikethrough, .inlineCode,
        .divider,
        .heading(), .bulletList, .link,
        .divider,
        .menu([.taskList, .toggleCheckbox, .quote, .outdent, .indent]),
    ]
}
#endif
