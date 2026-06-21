import SwiftUI
import SwiftMarkdownEngine

// Visual editors for code, image/video, and math blocks. Each writes the block's Markdown back
// on change; the rendered block shown above the editor (by WysiwygEditorView) is the live preview.

/// Code-block editor: language picker + monospaced source.
struct CodeBlockEditor: View {
    @Binding var markdown: String
    let theme: MarkdownTheme

    private static let languages = ["", "swift", "python", "javascript", "typescript", "json",
                                    "bash", "c", "cpp", "rust", "go", "html", "css", "sql", "yaml", "markdown"]

    @State private var language: String = ""
    @State private var code: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Language", selection: $language) {
                ForEach(Self.languages, id: \.self) { Text($0.isEmpty ? "Plain" : $0).tag($0) }
            }
            .pickerStyle(.menu)
            .tint(theme.accent)

            TextEditor(text: $code)
                .font(.system(.callout, design: .monospaced))
                .frame(minHeight: 90)
                .padding(6)
                .background(theme.codeBackground, in: RoundedRectangle(cornerRadius: 6))
                .scrollContentBackground(.hidden)
        }
        .onAppear(perform: decompose)
        .onChange(of: language) { _ in recompose() }
        .onChange(of: code) { _ in recompose() }
    }

    private func decompose() {
        guard case .codeBlock(let lang, let content)? = MarkdownParser().parse(markdown).blocks.first?.kind else { return }
        language = lang ?? ""
        code = content
    }

    private func recompose() { markdown = "```\(language)\n\(code)\n```" }
}

/// Math-block editor: LaTeX source (preview is the rendered block above).
struct MathBlockEditor: View {
    @Binding var markdown: String
    let theme: MarkdownTheme

    @State private var latex: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("LaTeX").font(.caption2.weight(.semibold)).foregroundStyle(theme.textSecondary)
            TextEditor(text: $latex)
                .font(.system(.callout, design: .monospaced))
                .frame(minHeight: 60)
                .padding(6)
                .background(theme.surface, in: RoundedRectangle(cornerRadius: 6))
                .scrollContentBackground(.hidden)
        }
        .onAppear(perform: decompose)
        .onChange(of: latex) { _ in recompose() }
    }

    private func decompose() {
        guard case .mathBlock(let body)? = MarkdownParser().parse(markdown).blocks.first?.kind else { return }
        latex = body
    }

    private func recompose() { markdown = "$$\n\(latex)\n$$" }
}

/// Image/video editor: a plain image (`![alt](url)`) or a linked video thumbnail
/// (`[![alt](thumb)](videoURL)`), toggled by "Linked video".
struct ImageVideoEditor: View {
    @Binding var markdown: String
    let theme: MarkdownTheme

    @State private var alt: String = ""
    @State private var url: String = ""       // image source, or video URL when linked
    @State private var thumbnail: String = "" // thumbnail source when linked
    @State private var linked: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Linked video (tappable thumbnail)", isOn: $linked)
                .tint(theme.accent)
                .font(.system(size: 15))

            field("Alt / caption", text: $alt)
            field(linked ? "Video URL" : "Image or video URL", text: $url)
            if linked { field("Thumbnail URL", text: $thumbnail) }
        }
        .onAppear(perform: decompose)
        .onChange(of: alt) { _ in recompose() }
        .onChange(of: url) { _ in recompose() }
        .onChange(of: thumbnail) { _ in recompose() }
        .onChange(of: linked) { _ in recompose() }
    }

    private func field(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(6)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: 6))
    }

    private func decompose() {
        guard case .paragraph(let inlines)? = MarkdownParser().parse(markdown).blocks.first?.kind,
              let first = inlines.first else { return }
        switch first.kind {
        case .image(let source, _, let altText):
            linked = false; url = source; alt = altText
        case .link(let dest, _, let children):
            if case .image(let source, _, let altText)? = children.first?.kind {
                linked = true; url = dest; thumbnail = source; alt = altText
            }
        default:
            break
        }
    }

    private func recompose() {
        markdown = linked ? "[![\(alt)](\(thumbnail))](\(url))" : "![\(alt)](\(url))"
    }
}
