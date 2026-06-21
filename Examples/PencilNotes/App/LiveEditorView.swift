import SwiftUI
import SwiftMarkdownEngine
#if canImport(UIKit)
import UIKit
#endif

/// Phase-1 continuous "Live" (Typora-style) editor. One scrolling UITextView where text is
/// live-styled and editable, Markdown markers dim off the active line, and block elements
/// (code, tables, diagrams, math) render inline as images. Tapping a block opens its source in
/// a sheet. Markdown stays the source of truth — reconstructed from the text + block sources.
///
/// Honest scope: this is a first cut. In-place block editing, richer cursor behavior around
/// blocks, and perf hardening are Phase 2. Inline block previews are static renders (read-only).
struct LiveEditorView: View {
    @Binding var text: String
    let theme: MarkdownTheme
    let services: MarkdownServices

    @State private var editing: EditingBlock?

    struct EditingBlock: Identifiable { let id = UUID(); var index: Int; var source: String }

    var body: some View {
        LiveTextView(text: $text, theme: theme, services: services) { index, source in
            editing = EditingBlock(index: index, source: source)
        }
        .sheet(item: $editing) { block in
            BlockSourceSheet(source: block.source, theme: theme) { newSource in
                replaceBlock(at: block.index, with: newSource)
            }
        }
    }

    /// Replaces the nth top-level block's Markdown and writes the document back.
    private func replaceBlock(at index: Int, with newSource: String) {
        var fragments = MarkdownParser().parse(text).blocks.map { $0.markdown() }
        guard fragments.indices.contains(index) else { return }
        fragments[index] = newSource
        text = fragments.joined(separator: "\n\n") + "\n"
    }
}

/// A simple sheet to edit one block's Markdown source (Phase-1 block editing).
private struct BlockSourceSheet: View {
    @State var source: String
    let theme: MarkdownTheme
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MarkdownView(source).markdownTheme(theme).padding()
                Divider()
                TextEditor(text: $source)
                    .font(.system(.callout, design: .monospaced))
                    .padding(8)
            }
            .navigationTitle("Edit block")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { onSave(source); dismiss() } }
            }
        }
    }
}

#if canImport(UIKit)
private let liveBlockSourceKey = NSAttributedString.Key("liveBlockSource")
private let liveBlockIndexKey = NSAttributedString.Key("liveBlockIndex")

struct LiveTextView: UIViewRepresentable {
    @Binding var text: String
    let theme: MarkdownTheme
    let services: MarkdownServices
    let onBlockTap: (Int, String) -> Void

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView(usingTextLayoutManager: true)
        tv.delegate = context.coordinator
        tv.backgroundColor = UIColor(theme.background)
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 24, right: 12)
        tv.alwaysBounceVertical = true
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.cancelsTouchesInView = false
        tv.addGestureRecognizer(tap)
        context.coordinator.textView = tv
        context.coordinator.rebuild(text)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        context.coordinator.textView = tv
        // Rebuild only when the source changed externally (e.g. another mode edited it).
        if context.coordinator.lastRenderedSource != text { context.coordinator.rebuild(text) }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        private let parent: LiveTextView
        weak var textView: UITextView?
        var lastRenderedSource: String = "\u{0}"   // sentinel so first updateUIView doesn't rebuild over makeUIView
        private var blockRanges: [(range: NSRange, index: Int, source: String)] = []

        init(_ parent: LiveTextView) { self.parent = parent }

        // MARK: Build

        @MainActor func rebuild(_ markdown: String) {
            guard let tv = textView else { return }
            let styler = LiveStyler(theme: parent.theme)
            let result = NSMutableAttributedString()
            blockRanges = []
            let width = max(240, tv.bounds.width - 24)
            for (i, block) in MarkdownParser().parse(markdown).blocks.enumerated() {
                if LiveStyler.isTextBlock(block) {
                    result.append(styler.styled(block.markdown()))
                } else {
                    let source = block.markdown()
                    let attachment = NSTextAttachment()
                    attachment.image = renderBlock(source, width: width) ?? UIImage()
                    let attr = NSMutableAttributedString(attachment: attachment)
                    let r = NSRange(location: 0, length: attr.length)
                    attr.addAttribute(liveBlockSourceKey, value: source, range: r)
                    attr.addAttribute(liveBlockIndexKey, value: i, range: r)
                    blockRanges.append((NSRange(location: result.length, length: attr.length), i, source))
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
            styler.applyMarkerReveal(in: tv, activeParagraph: tv.selectedRange)
        }

        @MainActor private func renderBlock(_ source: String, width: CGFloat) -> UIImage? {
            let view = MarkdownView(source)
                .markdownTheme(parent.theme)
                .markdownServices(parent.services)
                .frame(width: width, alignment: .leading)
                .background(parent.theme.surface)
            let renderer = ImageRenderer(content: view)
            renderer.scale = UIScreen.main.scale
            return renderer.uiImage
        }

        // MARK: Editing & selection

        func textViewDidChange(_ tv: UITextView) {
            // Reconstruct Markdown from text runs + block sources; write back (the binding is
            // the source of truth). We do not rebuild here, to keep typing smooth.
            let md = reconstructMarkdown(tv)
            lastRenderedSource = md
            parent.text = md
        }

        func textViewDidChangeSelection(_ tv: UITextView) {
            LiveStyler(theme: parent.theme).applyMarkerReveal(in: tv, activeParagraph: tv.selectedRange)
        }

        private func reconstructMarkdown(_ tv: UITextView) -> String {
            let storage = tv.textStorage
            var out = ""
            storage.enumerateAttribute(liveBlockSourceKey, in: NSRange(location: 0, length: storage.length)) { value, range, _ in
                if let source = value as? String {
                    out += source
                } else {
                    out += (storage.attributedSubstring(from: range)).string
                }
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

/// Live attributed-string styling for text blocks: heading sizes, bold/italic/strikethrough/
/// inline code, with Markdown markers dimmed (revealed on the active line).
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
    private var dim: UIColor { UIColor(theme.textSecondary).withAlphaComponent(0.5) }
    private var accent: UIColor { UIColor(theme.accent) }

    /// Styles a text block's Markdown source for inline display, tagging marker ranges so they
    /// can be dimmed/revealed by `applyMarkerReveal`.
    func styled(_ source: String) -> NSAttributedString {
        let result = NSMutableAttributedString(string: source, attributes: [.font: Self.bodyFont, .foregroundColor: primary])
        let ns = source as NSString

        // Headings: size the whole line, mark the leading "#.. " as a marker.
        regex("(?m)^(#{1,6})\\s+(.*)$").enumerateMatches(in: source, range: NSRange(location: 0, length: ns.length)) { m, _, _ in
            guard let m, let hashes = range(m, 1), let line = range(m, 0) else { return }
            let level = (ns.substring(with: hashes)).count
            let size: CGFloat = [28, 24, 21, 19, 17, 16][min(level - 1, 5)]
            result.addAttribute(.font, value: UIFont.systemFont(ofSize: size, weight: .bold), range: line)
            tagMarker(result, NSRange(location: hashes.location, length: hashes.length + 1))
        }
        styleInline(result, "(\\*\\*|__)(.+?)\\1", trait: .traitBold)
        styleInline(result, "(?<![\\*_])(\\*|_)(?![\\*_])(.+?)\\1", trait: .traitItalic)
        styleStrikethrough(result, "(~~)(.+?)(~~)")
        styleCode(result, "(`)([^`]+?)(`)")
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

    private func styleStrikethrough(_ s: NSMutableAttributedString, _ pattern: String) {
        regex(pattern).enumerateMatches(in: s.string, range: NSRange(location: 0, length: (s.string as NSString).length)) { m, _, _ in
            guard let m, let inner = range(m, 2), let full = range(m, 0) else { return }
            s.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: inner)
            tagMarker(s, NSRange(location: full.location, length: 2))
            tagMarker(s, NSRange(location: full.location + full.length - 2, length: 2))
        }
    }

    private func styleCode(_ s: NSMutableAttributedString, _ pattern: String) {
        regex(pattern).enumerateMatches(in: s.string, range: NSRange(location: 0, length: (s.string as NSString).length)) { m, _, _ in
            guard let m, let inner = range(m, 2), let full = range(m, 0) else { return }
            s.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: Self.bodyFont.pointSize, weight: .regular), range: inner)
            s.addAttribute(.foregroundColor, value: accent, range: inner)
            tagMarker(s, NSRange(location: full.location, length: 1))
            tagMarker(s, NSRange(location: full.location + full.length - 1, length: 1))
        }
    }

    private func tagMarker(_ s: NSMutableAttributedString, _ r: NSRange) {
        guard r.location >= 0, r.location + r.length <= s.length else { return }
        s.addAttribute(.init("liveMarker"), value: true, range: r)
        s.addAttribute(.foregroundColor, value: dim, range: r)
    }

    /// Dims all tagged markers, then reveals (full color) those on the paragraph holding the cursor.
    func applyMarkerReveal(in tv: UITextView, activeParagraph selection: NSRange) {
        let storage = tv.textStorage
        let full = NSRange(location: 0, length: storage.length)
        let activeLine = (storage.string as NSString).paragraphRange(for: NSRange(location: min(selection.location, max(0, storage.length - 1)), length: 0))
        storage.enumerateAttribute(.init("liveMarker"), in: full) { value, range, _ in
            guard value != nil else { return }
            let reveal = NSIntersectionRange(range, activeLine).length > 0
            storage.addAttribute(.foregroundColor, value: reveal ? primary : dim, range: range)
        }
    }

    private func regex(_ p: String) -> NSRegularExpression { (try? NSRegularExpression(pattern: p)) ?? NSRegularExpression() }
    private func range(_ m: NSTextCheckingResult, _ i: Int) -> NSRange? {
        let r = m.range(at: i); return r.location == NSNotFound ? nil : r
    }
}
#else
struct LiveTextView: View {
    @Binding var text: String
    let theme: MarkdownTheme
    let services: MarkdownServices
    let onBlockTap: (Int, String) -> Void
    var body: some View { TextEditor(text: $text) }
}
#endif
