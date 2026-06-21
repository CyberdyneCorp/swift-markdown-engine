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
            Button("Numbered list") { controller.insertBlock("1. Item") }
            Button("Checklist") { controller.insertBlock("- [ ] Task") }
            Button("Quote") { controller.insertBlock("> Quote") }
            Button("Table") { controller.insertBlock("| A | B |\n| --- | --- |\n| 1 | 2 |") }
            Button("Code") { controller.insertBlock("```swift\ncode\n```") }
            Button("Math") { controller.insertBlock("$$\nE = mc^2\n$$") }
            Button("Image") { controller.insertBlock("![alt](https://picsum.photos/400/200)") }
            Button("Video") { controller.insertBlock("![clip](https://www.w3schools.com/html/mov_bbb.mp4)") }
            Divider()
            Menu("Diagram") {
                Button("Flowchart") { controller.insertBlock("```mermaid\nflowchart LR\n  A[Start] --> B[End]\n```") }
                Button("Pie chart") { controller.insertBlock("```mermaid\npie title Chart\n  \"A\" : 1\n```") }
                Button("Sequence") { controller.insertBlock("```mermaid\nsequenceDiagram\n  participant A\n  participant B\n  A->>B: Hello\n```") }
                Button("Mindmap") { controller.insertBlock("```mermaid\nmindmap\n  root((Topic))\n    Idea\n```") }
                Button("Gantt") { controller.insertBlock("```mermaid\ngantt\n  title Plan\n  section Phase\n  Task : 3d\n```") }
                Button("Class diagram") { controller.insertBlock("```mermaid\nclassDiagram\n  class Animal\n  Animal : +int age\n```") }
                Button("State diagram") { controller.insertBlock("```mermaid\nstateDiagram-v2\n  [*] --> Idle\n  Idle --> Active\n```") }
                Button("ER diagram") { controller.insertBlock("```mermaid\nerDiagram\n  CUSTOMER ||--o{ ORDER : places\n```") }
                Button("Git graph") { controller.insertBlock("```mermaid\ngitGraph\n  commit\n  branch dev\n  checkout dev\n  commit\n```") }
                Button("Journey") { controller.insertBlock("```mermaid\njourney\n  title My Day\n  section Work\n  Code: 4: Me\n```") }
                Button("Timeline") { controller.insertBlock("```mermaid\ntimeline\n  title History\n  2020 : Start\n```") }
            }
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

        init(_ parent: LiveTextView) { self.parent = parent }

        // Let our block-tap recognizer fire alongside the text view's built-in gestures so
        // tapping still places the cursor and focuses the keyboard.
        func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }

        // MARK: Build

        @MainActor func rebuild(_ markdown: String) {
            guard let tv = textView else { return }
            let styler = LiveStyler(theme: parent.theme)
            let result = NSMutableAttributedString()
            let width = max(240, tv.bounds.width - 24)
            for (i, block) in MarkdownParser().parse(markdown).blocks.enumerated() {
                if LiveStyler.isTextBlock(block) {
                    result.append(styler.styled(block.markdown()))
                } else {
                    // Block elements (lists, tables, code, math, diagrams, images, video) render
                    // as live SwiftUI views inline via a TextKit 2 attachment view provider — so
                    // async content (images/video), Canvas (Mermaid) and LaTeX render for real.
                    let source = block.markdown()
                    let attachment = BlockAttachment(source: source, theme: parent.theme,
                                                     services: parent.services, width: width,
                                                     isMedia: LiveStyler.isMedia(block))
                    attachment.measureHeight()
                    let attr = NSMutableAttributedString(attachment: attachment)
                    let r = NSRange(location: 0, length: attr.length)
                    attr.addAttribute(liveBlockSourceKey, value: source, range: r)
                    attr.addAttribute(liveBlockIndexKey, value: i, range: r)
                    result.append(attr)
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

/// A text attachment that renders a Markdown block as a live SwiftUI view inline (so images,
/// video, Mermaid Canvas and LaTeX render for real, unlike a static snapshot).
final class BlockAttachment: NSTextAttachment {
    let source: String
    let theme: MarkdownTheme
    let services: MarkdownServices
    let width: CGFloat
    let isMedia: Bool
    /// Block height, measured eagerly during rebuild (see `measuredHeight(...)`). The view
    /// provider returns this from `attachmentBounds`, so layout never depends on the
    /// provider's view lifecycle (which can query bounds before `loadView` runs).
    var height: CGFloat

    init(source: String, theme: MarkdownTheme, services: MarkdownServices, width: CGFloat, isMedia: Bool) {
        self.source = source; self.theme = theme; self.services = services
        self.width = width; self.isMedia = isMedia
        self.height = isMedia ? BlockAttachment.mediaHeight(width: width) : 24
        super.init(data: nil, ofType: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Media height floor: images/video are sized asynchronously, so reserve a 16:9-ish box up
    /// front (capped) instead of letting them collapse to one line before the asset loads.
    static func mediaHeight(width: CGFloat) -> CGFloat { min(280, width * 9.0 / 16.0) }

    /// The SwiftUI content for this block, shared by measurement and the hosted view.
    @MainActor func content() -> AnyView {
        let view = MarkdownView(source)
            .markdownTheme(theme)
            .markdownServices(services)
            .padding(.vertical, 4)
        return isMedia
            ? AnyView(view.frame(width: width, height: BlockAttachment.mediaHeight(width: width), alignment: .leading))
            : AnyView(view.frame(width: width, alignment: .leading))
    }

    /// Measures the block's intrinsic height with a throwaway hosting controller. Reliable for
    /// synchronous content (text, code, math, Mermaid Canvas); async media uses the floor above.
    @MainActor func measureHeight() {
        let measured = UIHostingController(rootView: content())
            .sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height
        let floor = isMedia ? BlockAttachment.mediaHeight(width: width) : 24
        height = max(floor, measured.isFinite ? measured : 0)
    }

    override func viewProvider(for parentView: UIView?, location: any NSTextLocation,
                               textContainer: NSTextContainer?) -> NSTextAttachmentViewProvider? {
        let provider = BlockViewProvider(textAttachment: self, parentView: parentView,
                                         textLayoutManager: textContainer?.textLayoutManager, location: location)
        provider.tracksTextAttachmentViewBounds = true   // honor the explicit frame we set in loadView
        return provider
    }
}

/// Hosts the SwiftUI `MarkdownView` for a block attachment. Read-only (user interaction off) so a
/// tap falls through to the text view's block-tap handler, which opens the per-type editor sheet.
final class BlockViewProvider: NSTextAttachmentViewProvider {
    override func loadView() {
        guard let att = textAttachment as? BlockAttachment else { return }
        MainActor.assumeIsolated {
            let controller = UIHostingController(rootView: att.content())
            controller.view.backgroundColor = .clear
            controller.view.isUserInteractionEnabled = false
            // Pin to an explicit frame anchored at the line-fragment origin so the block's
            // leading edge isn't shifted off-screen (TextKit tracks this frame).
            controller.view.frame = CGRect(x: 0, y: 0, width: att.width, height: att.height)
            view = controller.view
        }
    }

    override func attachmentBounds(for attributes: [NSAttributedString.Key: Any],
                                   location: any NSTextLocation, textContainer: NSTextContainer?,
                                   proposedLineFragment: CGRect, position: CGPoint) -> CGRect {
        guard let att = textAttachment as? BlockAttachment else { return .zero }
        return CGRect(x: 0, y: 0, width: att.width, height: att.height)
    }
}

/// Live attributed styling for text blocks: heading sizes, bold/italic/strikethrough/inline code.
/// Markdown markers are tagged so they can be collapsed (hidden) off the active line.
private struct LiveStyler {
    let theme: MarkdownTheme
    static let bodyFont = UIFont.preferredFont(forTextStyle: .body)

    static func isTextBlock(_ block: BlockNode) -> Bool {
        switch block.kind {
        case .heading: return true
        case .paragraph:
            return !isMedia(block)   // an image-only / video paragraph renders as a media block
        case .blockQuote(let blocks):
            return blocks.count == 1 && { if case .paragraph = blocks[0].kind { return true } else { return false } }()
        default: return false   // lists, tables, code, math, diagrams render as live blocks
        }
    }

    /// A paragraph whose sole content is an image or a linked image (e.g. a video thumbnail).
    static func isMedia(_ block: BlockNode) -> Bool {
        guard case .paragraph(let inlines) = block.kind, inlines.count == 1 else { return false }
        if case .image = inlines[0].kind { return true }
        if case .link(_, _, let children) = inlines[0].kind,
           children.count == 1, case .image = children[0].kind { return true }
        return false
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
