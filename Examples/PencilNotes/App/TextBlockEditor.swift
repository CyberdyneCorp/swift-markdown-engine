import SwiftUI
import SwiftMarkdownEngine
#if canImport(UIKit)
import UIKit
#endif

/// Visual editor for a single text block (paragraph / heading / quote): a block-type menu, an
/// inline formatting toolbar (bold/italic/strikethrough/code/link), and an editable text area.
/// The user never types block syntax; inline marks are applied to the selection via the toolbar.
/// Reconstructs the block's Markdown and writes it back on every change.
struct TextBlockEditor: View {
    @Binding var markdown: String
    let theme: MarkdownTheme

    enum BlockType: Equatable {
        case paragraph, heading(Int), quote
    }

    @State private var type: BlockType = .paragraph
    @State private var content: String = ""
    @StateObject private var format = TextFormatController()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                blockTypeMenu
                Divider().frame(height: 18)
                formatButton("bold", "Bold") { format.wrap("**", "**") }
                formatButton("italic", "Italic") { format.wrap("*", "*") }
                formatButton("strikethrough", "Strikethrough") { format.wrap("~~", "~~") }
                formatButton("chevron.left.forwardslash.chevron.right", "Code") { format.wrap("`", "`") }
                formatButton("link", "Link") { format.wrap("[", "](https://)") }
                Spacer()
            }
            .font(.system(size: 15, weight: .medium))

            FormattingTextView(text: $content, controller: format, theme: theme)
                .frame(minHeight: 44)
                .padding(6)
                .background(theme.surface, in: RoundedRectangle(cornerRadius: 6))
        }
        .onAppear { decompose() }
        .onChange(of: content) { _ in recompose() }
        .onChange(of: type) { _ in recompose() }
    }

    private var blockTypeMenu: some View {
        Menu {
            Button("Paragraph") { type = .paragraph }
            ForEach(1...6, id: \.self) { level in
                Button("Heading \(level)") { type = .heading(level) }
            }
            Button("Quote") { type = .quote }
        } label: {
            Label(typeLabel, systemImage: "textformat")
                .foregroundStyle(theme.accent)
        }
    }

    private var typeLabel: String {
        switch type {
        case .paragraph: return "Paragraph"
        case .heading(let l): return "Heading \(l)"
        case .quote: return "Quote"
        }
    }

    private func formatButton(_ system: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: system) }
            .buttonStyle(.plain)
            .foregroundStyle(theme.accent)
            .accessibilityLabel(label)
    }

    // MARK: - Markdown <-> (type, content)

    private func decompose() {
        let md = markdown
        if let m = md.range(of: "^#{1,6}[ \t]+", options: .regularExpression) {
            let level = md[m].prefix { $0 == "#" }.count
            type = .heading(level)
            content = String(md[m.upperBound...])
        } else if md.hasPrefix(">") {
            type = .quote
            content = md.split(separator: "\n", omittingEmptySubsequences: false)
                .map { line -> String in
                    var s = Substring(line)
                    if s.hasPrefix("> ") { s = s.dropFirst(2) } else if s.hasPrefix(">") { s = s.dropFirst() }
                    return String(s)
                }
                .joined(separator: "\n")
        } else {
            type = .paragraph
            content = md
        }
    }

    private func recompose() {
        switch type {
        case .paragraph:
            markdown = content
        case .heading(let level):
            // headings are single-line; collapse any newlines the field may hold
            markdown = String(repeating: "#", count: level) + " " + content.replacingOccurrences(of: "\n", with: " ")
        case .quote:
            markdown = content.split(separator: "\n", omittingEmptySubsequences: false)
                .map { $0.isEmpty ? ">" : "> " + $0 }.joined(separator: "\n")
        }
    }
}

/// Bridges a SwiftUI binding to a `UITextView` so the toolbar can wrap the current selection.
final class TextFormatController: ObservableObject {
    #if canImport(UIKit)
    weak var textView: UITextView?
    var onTextChange: ((String) -> Void)?

    /// Wraps the current selection (or inserts at the caret) with `lhs`/`rhs`.
    func wrap(_ lhs: String, _ rhs: String) {
        guard let tv = textView else { return }
        let range = tv.selectedRange
        let ns = tv.text as NSString
        let selected = ns.substring(with: range)
        let replacement = lhs + selected + rhs
        tv.text = ns.replacingCharacters(in: range, with: replacement)
        // Keep the original text selected, now inside the new delimiters.
        let lhsLen = (lhs as NSString).length
        tv.selectedRange = NSRange(location: range.location + lhsLen, length: (selected as NSString).length)
        onTextChange?(tv.text)
    }
    #else
    func wrap(_ lhs: String, _ rhs: String) {}
    #endif
}

#if canImport(UIKit)
/// A `UITextView`-backed editor that reports its selection through `TextFormatController`.
struct FormattingTextView: UIViewRepresentable {
    @Binding var text: String
    let controller: TextFormatController
    let theme: MarkdownTheme

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.font = .preferredFont(forTextStyle: .body)
        tv.backgroundColor = .clear
        tv.isScrollEnabled = false
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        controller.textView = tv
        controller.onTextChange = { context.coordinator.push($0) }
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        if tv.text != text { tv.text = text }
        controller.textView = tv
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    final class Coordinator: NSObject, UITextViewDelegate {
        private let text: Binding<String>
        init(text: Binding<String>) { self.text = text }
        func textViewDidChange(_ tv: UITextView) { text.wrappedValue = tv.text }
        func push(_ s: String) { text.wrappedValue = s }
    }
}
#else
struct FormattingTextView: View {
    @Binding var text: String
    let controller: TextFormatController
    let theme: MarkdownTheme
    var body: some View { TextEditor(text: $text) }
}
#endif
