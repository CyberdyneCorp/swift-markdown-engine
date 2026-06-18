#if os(iOS) || os(macOS)
import SwiftUI
import SwiftMarkdownEngine

/// Bridges a platform text view (TextKit 2 backed) to SwiftUI, applying live syntax
/// styling and smart editing behaviors. The toolbar drives it through a shared
/// `MarkdownEditorController`.
@MainActor
public final class MarkdownEditorController: ObservableObject {
    weak var textView: PlatformTextView?
    var styler: MarkdownSyntaxStyler = MarkdownSyntaxStyler(theme: .light)
    var onChange: ((String) -> Void)?

    private var currentText: String {
        #if canImport(UIKit)
        return textView?.text ?? ""
        #else
        return textView?.string ?? ""
        #endif
    }

    private var selectedRange: NSRange {
        textView?.selectedRange ?? NSRange(location: 0, length: 0)
    }

    /// Applies an edit result to the text view, restyles, and notifies the binding.
    func apply(_ result: EditResult) {
        setText(result.text, selection: result.selection)
        onChange?(result.text)
    }

    func setText(_ text: String, selection: NSRange? = nil) {
        guard let textView else { return }
        let styled = styler.styled(text)
        #if canImport(UIKit)
        textView.attributedText = styled
        #else
        textView.textStorage?.setAttributedString(styled)
        #endif
        textView.typingAttributes = baseTypingAttributes()
        if let selection {
            let clamped = NSRange(location: min(selection.location, (text as NSString).length),
                                  length: min(selection.length, max(0, (text as NSString).length - selection.location)))
            textView.selectedRange = clamped
        }
    }

    /// Re-applies styling while preserving the caret/selection.
    func restyle() {
        let range = selectedRange
        setText(currentText, selection: range)
    }

    private func baseTypingAttributes() -> [NSAttributedString.Key: Any] {
        [.font: EditorFont.body(), .foregroundColor: PlatformColor.from(styler.theme.textPrimary)]
    }

    // MARK: - Commands

    public func toggleBold() { apply(MarkdownEditCommands.toggleInlineWrap(currentText, range: selectedRange, marker: "**")) }
    public func toggleItalic() { apply(MarkdownEditCommands.toggleInlineWrap(currentText, range: selectedRange, marker: "*")) }
    public func toggleStrikethrough() { apply(MarkdownEditCommands.toggleInlineWrap(currentText, range: selectedRange, marker: "~~")) }
    public func toggleInlineCode() { apply(MarkdownEditCommands.toggleInlineWrap(currentText, range: selectedRange, marker: "`")) }
    public func setHeading(_ level: Int) { apply(MarkdownEditCommands.setHeading(currentText, range: selectedRange, level: level)) }
    public func toggleBulletList() { apply(MarkdownEditCommands.toggleLinePrefix(currentText, range: selectedRange, prefix: "- ")) }
    public func toggleTaskList() { apply(MarkdownEditCommands.toggleLinePrefix(currentText, range: selectedRange, prefix: "- [ ] ")) }
    public func toggleQuote() { apply(MarkdownEditCommands.toggleLinePrefix(currentText, range: selectedRange, prefix: "> ")) }
    public func toggleCheckbox() { apply(MarkdownEditCommands.toggleCheckbox(currentText, location: selectedRange.location)) }
    public func indent() { apply(MarkdownEditCommands.indent(currentText, range: selectedRange)) }
    public func outdent() { apply(MarkdownEditCommands.outdent(currentText, range: selectedRange)) }
    public func insertLink() { apply(MarkdownEditCommands.insertLink(currentText, range: selectedRange)) }
}

// MARK: - Representable

struct MarkdownTextViewRepresentable {
    @Binding var text: String
    let theme: MarkdownTheme
    let controller: MarkdownEditorController

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    @MainActor
    func configure(_ textView: PlatformTextView, coordinator: Coordinator) {
        controller.styler = MarkdownSyntaxStyler(theme: theme)
        controller.textView = textView
        controller.onChange = { coordinator.parent.text = $0 }
        controller.setText(text, selection: textView.selectedRange)
    }

    @MainActor
    final class Coordinator: NSObject {
        var parent: MarkdownTextViewRepresentable
        nonisolated init(_ parent: MarkdownTextViewRepresentable) { self.parent = parent }

        func handleReturn(_ textView: PlatformTextView) -> Bool {
            let text = currentText(textView)
            switch MarkdownEditCommands.listContinuation(text, location: textView.selectedRange.location) {
            case .none:
                return true
            case .insert(let snippet):
                let ns = text as NSString
                let newText = ns.replacingCharacters(in: textView.selectedRange, with: snippet)
                parent.controller.apply(EditResult(text: newText, selection: NSRange(location: textView.selectedRange.location + (snippet as NSString).length, length: 0)))
                return false
            case .removeMarker(let lineRange):
                let ns = text as NSString
                let newText = ns.replacingCharacters(in: lineRange, with: "\n")
                parent.controller.apply(EditResult(text: newText, selection: NSRange(location: lineRange.location, length: 0)))
                return false
            }
        }

        private func currentText(_ textView: PlatformTextView) -> String {
            #if canImport(UIKit)
            return textView.text ?? ""
            #else
            return textView.string
            #endif
        }
    }
}

#if canImport(UIKit)
extension MarkdownTextViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView(usingTextLayoutManager: true) // TextKit 2
        textView.delegate = context.coordinator
        textView.backgroundColor = PlatformColor.from(theme.background)
        textView.alwaysBounceVertical = true
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 240, right: 8) // bottom overscroll
        textView.autocorrectionType = .yes
        configure(textView, coordinator: context.coordinator)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text { controller.setText(text, selection: uiView.selectedRange) }
    }
}

extension MarkdownTextViewRepresentable.Coordinator: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        parent.text = textView.text
        parent.controller.restyle()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" { return handleReturn(textView) }
        return true
    }
}
#elseif canImport(AppKit)
extension MarkdownTextViewRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        textView.backgroundColor = PlatformColor.from(theme.background)
        textView.textContainerInset = NSSize(width: 8, height: 12)
        configure(textView, coordinator: context.coordinator)
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text { controller.setText(text, selection: textView.selectedRange) }
    }
}

extension MarkdownTextViewRepresentable.Coordinator: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }
        parent.text = textView.string
        parent.controller.restyle()
    }

    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            return !handleReturn(textView)
        }
        return false
    }
}
#endif
#endif
