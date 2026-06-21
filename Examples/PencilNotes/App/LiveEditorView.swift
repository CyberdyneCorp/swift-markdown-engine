import SwiftUI
import SwiftMarkdownEngine
#if canImport(UIKit)
import UIKit
#endif

/// Continuous "Live" (Typora-style) editor. One scrolling UITextView where inline formatting is
/// rendered (Markdown markers are hidden, revealed only on the line the cursor is on) and block
/// elements render inline as images. A toolbar applies inline formatting and inserts blocks.
/// Markdown stays the source of truth — reconstructed from the text + each block's source.
struct LiveEditorView: View {
    @Binding var text: String
    let theme: MarkdownTheme
    let services: MarkdownServices

    @StateObject private var controller = LiveEditorController()
    @State private var editing: EditingBlock?

    struct EditingBlock: Identifiable { let id = UUID(); var index: Int; var source: String }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            LiveTextView(text: $text, theme: theme, services: services, controller: controller) { index, source in
                editing = EditingBlock(index: index, source: source)
            }
        }
        .background(theme.background)
        .sheet(item: $editing) { block in
            BlockEditSheet(source: block.source, theme: theme, services: services) { newSource in
                replaceBlock(at: block.index, with: newSource)
            }
        }
    }

    private var toolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                tbHeadingMenu
                Divider().frame(height: 18)
                tb("bold", "Bold") { controller.wrap("**", "**") }
                tb("italic", "Italic") { controller.wrap("*", "*") }
                tb("strikethrough", "Strikethrough") { controller.wrap("~~", "~~") }
                tb("chevron.left.forwardslash.chevron.right", "Code") { controller.wrap("`", "`") }
                tb("link", "Link") { controller.wrap("[", "](https://)") }
                Divider().frame(height: 18)
                tbInsertMenu
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .font(.system(size: 16, weight: .medium))
        }
    }

    private var tbHeadingMenu: some View {
        Menu {
            Button("Paragraph") { controller.setHeading(0) }
            ForEach(1...3, id: \.self) { l in Button("Heading \(l)") { controller.setHeading(l) } }
        } label: { Image(systemName: "textformat.size").foregroundStyle(theme.accent) }
    }

    private var tbInsertMenu: some View {
        Menu {
            Button("Bulleted list") { controller.insertBlock("- Item") }
            Button("Quote") { controller.insertBlock("> Quote") }
            Button("Table") { controller.insertBlock("| A | B |\n| --- | --- |\n| 1 | 2 |") }
            Button("Code") { controller.insertBlock("```swift\ncode\n```") }
            Button("Flowchart") { controller.insertBlock("```mermaid\nflowchart LR\n  A[Start] --> B[End]\n```") }
            Button("Pie chart") { controller.insertBlock("```mermaid\npie title Chart\n  \"A\" : 1\n```") }
            Button("Sequence") { controller.insertBlock("```mermaid\nsequenceDiagram\n  participant A\n  participant B\n  A->>B: Hello\n```") }
            Button("Mindmap") { controller.insertBlock("```mermaid\nmindmap\n  root((Topic))\n    Idea\n```") }
            Button("Gantt") { controller.insertBlock("```mermaid\ngantt\n  title Plan\n  section Phase\n  Task : 3d\n```") }
            Button("Math") { controller.insertBlock("$$\nE = mc^2\n$$") }
            Button("Image") { controller.insertBlock("![alt](https://picsum.photos/400/200)") }
        } label: { Label("Insert", systemImage: "plus.circle.fill").foregroundStyle(theme.accent) }
    }

    private func tb(_ system: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: system) }
            .buttonStyle(.plain).foregroundStyle(theme.accent).accessibilityLabel(label)
    }

    private func replaceBlock(at index: Int, with newSource: String) {
        var fragments = MarkdownParser().parse(text).blocks.map { $0.markdown() }
        guard fragments.indices.contains(index) else { return }
        fragments[index] = newSource
        text = fragments.joined(separator: "\n\n") + "\n"
    }
}

/// Bridges the SwiftUI toolbar to the Live editor's UITextView.
final class LiveEditorController: ObservableObject {
    #if canImport(UIKit)
    weak var textView: UITextView?
    var onMutated: (() -> Void)?            // re-sync + restyle after a programmatic text edit
    var onInsertBlock: ((String) -> Void)?  // insert a block's source and rebuild

    func wrap(_ lhs: String, _ rhs: String) {
        guard let tv = textView else { return }
        let range = tv.selectedRange
        let ns = tv.textStorage.string as NSString
        guard range.location + range.length <= ns.length else { return }
        let selected = ns.substring(with: range)
        tv.textStorage.replaceCharacters(in: range, with: lhs + selected + rhs)
        tv.selectedRange = NSRange(location: range.location + (lhs as NSString).length, length: (selected as NSString).length)
        onMutated?()
    }

    func setHeading(_ level: Int) {
        guard let tv = textView else { return }
        let ns = tv.textStorage.string as NSString
        let para = ns.paragraphRange(for: tv.selectedRange)
        var line = ns.substring(with: para)
        let newline = line.hasSuffix("\n"); if newline { line.removeLast() }
        if let r = line.range(of: "^#{1,6}\\s+", options: .regularExpression) { line.removeSubrange(r) }
        let prefix = level == 0 ? "" : String(repeating: "#", count: level) + " "
        tv.textStorage.replaceCharacters(in: para, with: prefix + line + (newline ? "\n" : ""))
        onMutated?()
    }

    func insertBlock(_ source: String) { onInsertBlock?(source) }
    #else
    func wrap(_ lhs: String, _ rhs: String) {}
    func setHeading(_ level: Int) {}
    func insertBlock(_ source: String) {}
    #endif
}

#if canImport(UIKit)
private let liveBlockSourceKey = NSAttributedString.Key("liveBlockSource")
private let liveBlockIndexKey = NSAttributedString.Key("liveBlockIndex")
private let liveMarkerKey = NSAttributedString.Key("liveMarker")
private let liveMarkerFontKey = NSAttributedString.Key("liveMarkerFont")

struct LiveTextView: UIViewRepresentable {
    @Binding var text: String
    let theme: MarkdownTheme
    let services: MarkdownServices
    let controller: LiveEditorController
    let onBlockTap: (Int, String) -> Void

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView(usingTextLayoutManager: true)
        tv.delegate = context.coordinator
        tv.backgroundColor = UIColor(theme.background)
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 24, right: 12)
        tv.alwaysBounceVertical = true
        tv.autocorrectionType = .no
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.cancelsTouchesInView = false
        tap.delegate = context.coordinator   // recognize alongside the text view's own tap (keeps cursor/keyboard focus working)
        tv.addGestureRecognizer(tap)
        context.coordinator.textView = tv
        controller.textView = tv
        controller.onMutated = { [weak coord = context.coordinator] in coord?.didMutateProgrammatically() }
        controller.onInsertBlock = { [weak coord = context.coordinator] src in coord?.insertBlock(src) }
        context.coordinator.rebuild(text)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        context.coordinator.textView = tv
        controller.textView = tv
        if context.coordinator.lastRenderedSource != text { context.coordinator.rebuild(text) }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate {
        private let parent: LiveTextView
        weak var textView: UITextView?
        var lastRenderedSource: String = "\u{0}"
        private var generation = 0

        init(_ parent: LiveTextView) { self.parent = parent }

        // Let our block-tap recognizer fire alongside the text view's built-in gestures so
        // tapping still places the cursor and focuses the keyboard.
        func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }

        // MARK: Build

        @MainActor func rebuild(_ markdown: String) {
            guard let tv = textView else { return }
            generation += 1
            let gen = generation
            let styler = LiveStyler(theme: parent.theme)
            let result = NSMutableAttributedString()
            let width = max(240, tv.bounds.width - 24)
            var pending: [(attachment: NSTextAttachment, source: String)] = []
            for (i, block) in MarkdownParser().parse(markdown).blocks.enumerated() {
                if LiveStyler.isTextBlock(block) {
                    result.append(styler.styled(block.markdown()))
                } else {
                    let source = block.markdown()
                    let attachment = NSTextAttachment()
                    attachment.image = Self.placeholder(width: width, theme: parent.theme)
                    let attr = NSMutableAttributedString(attachment: attachment)
                    attr.addAttribute(liveBlockSourceKey, value: source, range: NSRange(location: 0, length: attr.length))
                    attr.addAttribute(liveBlockIndexKey, value: i, range: NSRange(location: 0, length: attr.length))
                    result.append(attr)
                    pending.append((attachment, source))
                }
                result.append(NSAttributedString(string: "\n\n",
                                                  attributes: [.font: LiveStyler.bodyFont,
                                                               .foregroundColor: UIColor(parent.theme.textPrimary)]))
            }
            let selected = tv.selectedRange
            tv.attributedText = result
            tv.selectedRange = NSRange(location: min(selected.location, result.length), length: 0)
            lastRenderedSource = markdown
            styler.collapseMarkers(in: tv, activeParagraph: tv.selectedRange)
            renderNext(pending, width: width, generation: gen, at: 0)
        }

        @MainActor private func renderNext(_ pending: [(attachment: NSTextAttachment, source: String)],
                                           width: CGFloat, generation gen: Int, at index: Int) {
            guard gen == generation, index < pending.count, let tv = textView else { return }
            let item = pending[index]
            if let image = renderBlock(item.source, width: width) {
                item.attachment.image = image
                let storage = tv.textStorage
                storage.enumerateAttribute(.attachment, in: NSRange(location: 0, length: storage.length)) { value, range, stop in
                    if (value as AnyObject) === item.attachment {
                        storage.beginEditing(); storage.edited(.editedAttributes, range: range, changeInLength: 0); storage.endEditing()
                        stop.pointee = true
                    }
                }
            }
            DispatchQueue.main.async { [weak self] in self?.renderNext(pending, width: width, generation: gen, at: index + 1) }
        }

        private static func placeholder(width: CGFloat, theme: MarkdownTheme) -> UIImage {
            let size = CGSize(width: max(1, width), height: 44)
            return UIGraphicsImageRenderer(size: size).image { _ in
                UIColor(theme.surface).setFill()
                UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 8).fill()
            }
        }

        @MainActor private func renderBlock(_ source: String, width: CGFloat) -> UIImage? {
            let view = MarkdownView(source).markdownTheme(parent.theme).markdownServices(parent.services)
                .frame(width: width, alignment: .leading).background(parent.theme.surface)
            let renderer = ImageRenderer(content: view)
            renderer.scale = UIScreen.main.scale
            return renderer.uiImage
        }

        // MARK: Editing & selection

        func textViewDidChange(_ tv: UITextView) {
            parent.text = reconstructMarkdown(tv)
            lastRenderedSource = parent.text
            restyleActiveParagraph()
        }

        func textViewDidChangeSelection(_ tv: UITextView) {
            LiveStyler(theme: parent.theme).collapseMarkers(in: tv, activeParagraph: tv.selectedRange)
        }

        func didMutateProgrammatically() {
            guard let tv = textView else { return }
            parent.text = reconstructMarkdown(tv)
            lastRenderedSource = parent.text
            restyleActiveParagraph()
        }

        func insertBlock(_ source: String) {
            guard let tv = textView else { return }
            let md = reconstructMarkdown(tv).trimmingCharacters(in: .whitespacesAndNewlines) + "\n\n" + source + "\n"
            parent.text = md
            lastRenderedSource = md
            rebuild(md)
        }

        /// Live-styles the paragraph under the cursor so freshly typed Markdown renders immediately.
        @MainActor private func restyleActiveParagraph() {
            guard let tv = textView else { return }
            let storage = tv.textStorage
            let para = (storage.string as NSString).paragraphRange(for: tv.selectedRange)
            var hasAttachment = false
            storage.enumerateAttribute(.attachment, in: para) { v, _, stop in if v != nil { hasAttachment = true; stop.pointee = true } }
            guard !hasAttachment else { return }
            let sub = (storage.string as NSString).substring(with: para)
            let styled = LiveStyler(theme: parent.theme).styled(sub)
            storage.beginEditing()
            storage.setAttributes([.font: LiveStyler.bodyFont, .foregroundColor: UIColor(parent.theme.textPrimary)], range: para)
            styled.enumerateAttributes(in: NSRange(location: 0, length: styled.length)) { attrs, r, _ in
                let target = NSRange(location: para.location + r.location, length: r.length)
                if target.location + target.length <= storage.length { storage.addAttributes(attrs, range: target) }
            }
            storage.endEditing()
            LiveStyler(theme: parent.theme).collapseMarkers(in: tv, activeParagraph: tv.selectedRange)
        }

        private func reconstructMarkdown(_ tv: UITextView) -> String {
            let storage = tv.textStorage
            var out = ""
            storage.enumerateAttribute(liveBlockSourceKey, in: NSRange(location: 0, length: storage.length)) { value, range, _ in
                if let source = value as? String { out += source }
                else { out += storage.attributedSubstring(from: range).string }
            }
            return out.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
        }

        // MARK: Tap on a block

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let tv = textView else { return }
            let point = gesture.location(in: tv)
            guard let position = tv.closestPosition(to: point) else { return }
            let index = tv.offset(from: tv.beginningOfDocument, to: position)
            let storage = tv.textStorage
            for probe in [index, max(0, index - 1)] where probe < storage.length {
                if let source = storage.attribute(liveBlockSourceKey, at: probe, effectiveRange: nil) as? String,
                   let blockIndex = storage.attribute(liveBlockIndexKey, at: probe, effectiveRange: nil) as? Int {
                    parent.onBlockTap(blockIndex, source)
                    return
                }
            }
        }
    }
}

/// Live attributed styling for text blocks: heading sizes, bold/italic/strikethrough/inline code.
/// Markdown markers are tagged so they can be collapsed (hidden) off the active line.
private struct LiveStyler {
    let theme: MarkdownTheme
    static let bodyFont = UIFont.preferredFont(forTextStyle: .body)

    static func isTextBlock(_ block: BlockNode) -> Bool {
        switch block.kind {
        case .heading, .paragraph: return true
        case .blockQuote(let blocks):
            return blocks.count == 1 && { if case .paragraph = blocks[0].kind { return true } else { return false } }()
        case .list: return true
        default: return false
        }
    }

    private var primary: UIColor { UIColor(theme.textPrimary) }
    private var accent: UIColor { UIColor(theme.accent) }

    func styled(_ source: String) -> NSAttributedString {
        let result = NSMutableAttributedString(string: source, attributes: [.font: Self.bodyFont, .foregroundColor: primary])
        let ns = source as NSString
        regex("(?m)^(#{1,6})\\s+(.*)$").enumerateMatches(in: source, range: NSRange(location: 0, length: ns.length)) { m, _, _ in
            guard let m, let hashes = range(m, 1), let line = range(m, 0) else { return }
            let level = (ns.substring(with: hashes)).count
            let size: CGFloat = [28, 24, 21, 19, 17, 16][min(level - 1, 5)]
            result.addAttribute(.font, value: UIFont.systemFont(ofSize: size, weight: .bold), range: line)
            tagMarker(result, NSRange(location: hashes.location, length: hashes.length + 1))
        }
        styleInline(result, "(\\*\\*|__)(.+?)\\1", trait: .traitBold)
        styleInline(result, "(?<![\\*_])(\\*|_)(?![\\*_])(.+?)\\1", trait: .traitItalic)
        stylePaired(result, "(~~)(.+?)(~~)") { s, inner in s.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: inner) }
        stylePaired(result, "(`)([^`]+?)(`)") { s, inner in
            s.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: Self.bodyFont.pointSize, weight: .regular), range: inner)
            s.addAttribute(.foregroundColor, value: accent, range: inner)
        }
        return result
    }

    private func styleInline(_ s: NSMutableAttributedString, _ pattern: String, trait: UIFontDescriptor.SymbolicTraits) {
        regex(pattern).enumerateMatches(in: s.string, range: NSRange(location: 0, length: (s.string as NSString).length)) { m, _, _ in
            guard let m, let full = range(m, 0), let inner = range(m, 2), let markLen = range(m, 1)?.length else { return }
            let base = (s.attribute(.font, at: inner.location, effectiveRange: nil) as? UIFont) ?? Self.bodyFont
            if let desc = base.fontDescriptor.withSymbolicTraits(base.fontDescriptor.symbolicTraits.union(trait)) {
                s.addAttribute(.font, value: UIFont(descriptor: desc, size: base.pointSize), range: inner)
            }
            tagMarker(s, NSRange(location: full.location, length: markLen))
            tagMarker(s, NSRange(location: full.location + full.length - markLen, length: markLen))
        }
    }

    private func stylePaired(_ s: NSMutableAttributedString, _ pattern: String, _ apply: (NSMutableAttributedString, NSRange) -> Void) {
        regex(pattern).enumerateMatches(in: s.string, range: NSRange(location: 0, length: (s.string as NSString).length)) { m, _, _ in
            guard let m, let inner = range(m, 2), let mark = range(m, 1)?.length, let full = range(m, 0) else { return }
            apply(s, inner)
            tagMarker(s, NSRange(location: full.location, length: mark))
            tagMarker(s, NSRange(location: full.location + full.length - mark, length: mark))
        }
    }

    private func tagMarker(_ s: NSMutableAttributedString, _ r: NSRange) {
        guard r.location >= 0, r.location + r.length <= s.length else { return }
        let base = (s.attribute(.font, at: r.location, effectiveRange: nil) as? UIFont) ?? Self.bodyFont
        s.addAttribute(liveMarkerKey, value: true, range: r)
        s.addAttribute(liveMarkerFontKey, value: base, range: r)
    }

    /// Hides (collapses) all tagged markers, then reveals those on the paragraph holding the cursor.
    func collapseMarkers(in tv: UITextView, activeParagraph selection: NSRange) {
        let storage = tv.textStorage
        let full = NSRange(location: 0, length: storage.length)
        let loc = min(selection.location, max(0, storage.length - 1))
        let active = storage.length == 0 ? NSRange(location: 0, length: 0) : (storage.string as NSString).paragraphRange(for: NSRange(location: loc, length: 0))
        storage.beginEditing()
        storage.enumerateAttribute(liveMarkerKey, in: full) { value, range, _ in
            guard value != nil else { return }
            let base = (storage.attribute(liveMarkerFontKey, at: range.location, effectiveRange: nil) as? UIFont) ?? Self.bodyFont
            if NSIntersectionRange(range, active).length > 0 {
                storage.addAttribute(.font, value: base, range: range)
                storage.addAttribute(.foregroundColor, value: UIColor(theme.textSecondary), range: range)
            } else {
                storage.addAttribute(.font, value: base.withSize(0.01), range: range)   // collapse to ~zero width
                storage.addAttribute(.foregroundColor, value: UIColor.clear, range: range)
            }
        }
        storage.endEditing()
    }

    private func regex(_ p: String) -> NSRegularExpression { (try? NSRegularExpression(pattern: p)) ?? NSRegularExpression() }
    private func range(_ m: NSTextCheckingResult, _ i: Int) -> NSRange? { let r = m.range(at: i); return r.location == NSNotFound ? nil : r }
}
#else
struct LiveTextView: View {
    @Binding var text: String
    let theme: MarkdownTheme
    let services: MarkdownServices
    let controller: LiveEditorController
    let onBlockTap: (Int, String) -> Void
    var body: some View { TextEditor(text: $text) }
}
#endif

/// Edits one block with its per-type visual editor, with a live preview above.
private struct BlockEditSheet: View {
    @State var source: String
    let theme: MarkdownTheme
    let services: MarkdownServices
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    MarkdownView(source).markdownTheme(theme).markdownServices(services)
                    Divider()
                    BlockEditorView(markdown: $source, theme: theme)
                }
                .padding()
            }
            .background(theme.background)
            .navigationTitle("Edit block")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { onSave(source); dismiss() } }
            }
        }
    }
}
