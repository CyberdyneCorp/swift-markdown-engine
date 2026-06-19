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

    /// Resolver used for wiki-link completion; when nil, completion is disabled.
    var wikiResolver: (any WikiLinkResolver)?
    /// Action invoked on an Apple Pencil double-tap (defaults to toggling bold).
    var onPencilDoubleTap: (() -> Void)?
    /// Current wiki-link completion candidates (observed by the editor view).
    @Published public var wikiSuggestions: [WikiLinkTarget] = []
    private var wikiQueryRange: NSRange?

    private var currentText: String {
        #if canImport(UIKit)
        return textView?.text ?? ""
        #else
        return textView?.string ?? ""
        #endif
    }

    /// The most recent valid selection. Tapping a toolbar button can resign the text
    /// view's first responder (notably on iPad), after which `textView.selectedRange`
    /// reports `NSNotFound`; commands fall back to this stored value so they keep
    /// operating on the user's last caret/selection.
    private var lastSelection = NSRange(location: 0, length: 0)

    private var selectedRange: NSRange {
        guard let textView else { return lastSelection }
        let length = (currentText as NSString).length
        let live = textView.selectedRange
        if live.location != NSNotFound, live.location <= length, NSMaxRange(live) <= length {
            return live
        }
        return NSRange(location: min(lastSelection.location, length), length: 0)
    }

    /// Records the live selection when it is valid, so commands can use it later.
    func recordSelection() {
        guard let textView else { return }
        let length = (currentText as NSString).length
        let live = textView.selectedRange
        if live.location != NSNotFound, NSMaxRange(live) <= length {
            lastSelection = live
        }
    }

    /// Applies an edit result to the text view, restyles, and notifies the binding.
    func apply(_ result: EditResult) {
        setText(result.text, selection: result.selection)
        lastSelection = result.selection
        // Restore focus so the user can keep typing after a toolbar command.
        #if canImport(UIKit)
        textView?.becomeFirstResponder()
        #else
        if let textView { textView.window?.makeFirstResponder(textView) }
        #endif
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

    // MARK: - Affordances (spell suppression, wiki completion)

    /// Updates spell-check suppression and wiki-link suggestions for the caret.
    func refreshAffordances() {
        guard let textView else { return }
        recordSelection()
        let text = currentText
        let caret = selectedRange.location

        let suppressed = EditorScanning.isInSuppressedRange(text, location: caret)
        #if canImport(UIKit)
        let desired: UITextSpellCheckingType = suppressed ? .no : .default
        if textView.spellCheckingType != desired { textView.spellCheckingType = desired }
        #else
        textView.isContinuousSpellCheckingEnabled = !suppressed
        #endif

        if let resolver = wikiResolver, let active = EditorScanning.activeWikiQuery(text, caret: caret) {
            wikiQueryRange = active.range
            wikiSuggestions = resolver.suggestions(matching: active.query)
        } else if !wikiSuggestions.isEmpty {
            wikiSuggestions = []
            wikiQueryRange = nil
        }
    }

    /// Inserts the chosen wiki-link target, replacing the active query.
    public func completeWiki(_ target: WikiLinkTarget) {
        guard let range = wikiQueryRange else { return }
        let ns = currentText as NSString
        let replacement = target.identifier + "]]"
        let newText = ns.replacingCharacters(in: range, with: replacement)
        apply(EditResult(text: newText, selection: NSRange(location: range.location + (replacement as NSString).length, length: 0)))
        wikiSuggestions = []
        wikiQueryRange = nil
    }
}

// MARK: - Representable

struct MarkdownTextViewRepresentable {
    @Binding var text: String
    let theme: MarkdownTheme
    let controller: MarkdownEditorController
    let wikiResolver: (any WikiLinkResolver)?
    let pencilDoubleTap: ((MarkdownEditorController) -> Void)?

    @MainActor
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    @MainActor
    func configure(_ textView: PlatformTextView, coordinator: Coordinator) {
        controller.styler = MarkdownSyntaxStyler(theme: theme)
        controller.textView = textView
        controller.wikiResolver = wikiResolver
        if let pencilDoubleTap {
            controller.onPencilDoubleTap = { [weak controller] in
                if let controller { pencilDoubleTap(controller) }
            }
        }
        controller.onChange = { coordinator.parent.text = $0 }
        controller.setText(text, selection: textView.selectedRange)
    }

    @MainActor
    final class Coordinator: NSObject {
        var parent: MarkdownTextViewRepresentable
        init(_ parent: MarkdownTextViewRepresentable) { self.parent = parent }

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
        #if os(iOS)
        textView.addInteraction(UIPencilInteraction()) // Scribble is automatic; this adds double-tap.
        if let interaction = textView.interactions.compactMap({ $0 as? UIPencilInteraction }).first {
            interaction.delegate = context.coordinator
        }
        #endif
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
        parent.controller.refreshAffordances()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        parent.controller.refreshAffordances()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" { return handleReturn(textView) }
        return true
    }
}

extension MarkdownTextViewRepresentable.Coordinator: UIPencilInteractionDelegate {
    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        if let action = parent.controller.onPencilDoubleTap { action() }
        else { parent.controller.toggleBold() }
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
        parent.controller.refreshAffordances()
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        parent.controller.refreshAffordances()
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
