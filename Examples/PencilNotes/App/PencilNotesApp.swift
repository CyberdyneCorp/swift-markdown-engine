import SwiftUI
import SwiftMarkdownEngine
import MarkdownEditor
import MarkdownEngineCodeBlocks
import MarkdownEngineLatex

/// PencilNotes — an iPad-first example that shows off the Markdown editor with
/// Apple Pencil: Scribble to write, and a configured Pencil double-tap that
/// toggles bold (with on-screen feedback). A live preview renders alongside.
@main
struct PencilNotesApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
    }
}

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var text = Self.sample
    @State private var isDark = false
    @State private var showHint = true
    @State private var pencilFlash: String?

    private var theme: MarkdownTheme {
        var t = isDark ? MarkdownTheme.dark : MarkdownTheme.light
        t.accent = Color(.sRGB, red: 0.36, green: 0.31, blue: 0.96)  // indigo, matches the icon
        t.readingWidth = 720
        return t
    }

    var body: some View {
        ZStack {
            backdrop.ignoresSafeArea()

            VStack(spacing: 16) {
                header
                if sizeClass == .regular {
                    HStack(spacing: 16) { editorPanel; previewPanel }
                } else {
                    TabView {
                        editorPanel.tabItem { Label("Edit", systemImage: "applepencil") }
                        previewPanel.tabItem { Label("Preview", systemImage: "eye") }
                    }
                }
            }
            .padding(16)

            if let pencilFlash { pencilToast(pencilFlash) }
        }
        .preferredColorScheme(isDark ? .dark : .light)
        .animation(.spring(duration: 0.35), value: pencilFlash)
        .animation(.easeInOut, value: showHint)
    }

    // MARK: - Chrome

    private var backdrop: some View {
        LinearGradient(
            colors: isDark
                ? [Color(.sRGB, red: 0.08, green: 0.09, blue: 0.13), Color(.sRGB, red: 0.05, green: 0.06, blue: 0.09)]
                : [Color(.sRGB, red: 0.93, green: 0.94, blue: 0.99), Color(.sRGB, red: 0.88, green: 0.92, blue: 0.99)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "applepencil.and.scribble")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(theme.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text("Pencil Notes").font(.title2.bold()).foregroundStyle(theme.textPrimary)
                Text("Markdown on iPad, written by Pencil").font(.caption).foregroundStyle(theme.textSecondary)
            }
            Spacer()
            Button { isDark.toggle() } label: {
                Image(systemName: isDark ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 40, height: 40)
                    .background(theme.surface, in: Circle())
                    .foregroundStyle(theme.accent)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isDark ? "Switch to light mode" : "Switch to dark mode")
        }
    }

    // MARK: - Panels

    private var editorPanel: some View {
        panel(title: "Editor", systemImage: "square.and.pencil") {
            VStack(spacing: 0) {
                if showHint { pencilHint }
                MarkdownEditor(text: $text, theme: theme) { controller in
                    controller.toggleBold()
                    flashPencil("Bold ✦ — Pencil double-tap")
                }
            }
        }
    }

    /// Optional bridges: highlighted code (Highlightr) and rendered LaTeX (SwiftMath).
    private var services: MarkdownServices {
        MarkdownServices(
            syntaxHighlighter: HighlightrSyntaxHighlighter(theme: isDark ? "atom-one-dark" : "xcode"),
            latexRenderer: SwiftMathLatexRenderer()
        )
    }

    private var previewPanel: some View {
        panel(title: "Preview", systemImage: "doc.richtext") {
            MarkdownView(text)
                .markdownTheme(theme)
                .markdownServices(services)
                .markdownConfiguration(MarkdownConfiguration(interactiveCheckboxes: true))
        }
    }

    private var pencilHint: some View {
        HStack(spacing: 10) {
            Image(systemName: "applepencil").foregroundStyle(theme.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text("Write with Apple Pencil").font(.subheadline.weight(.semibold))
                Text("Scribble inserts text · scratch out to delete · double-tap toggles **Bold**")
                    .font(.caption).foregroundStyle(theme.textSecondary)
            }
            Spacer()
            Button { showHint = false } label: { Image(systemName: "xmark.circle.fill") }
                .buttonStyle(.plain).foregroundStyle(theme.textSecondary)
                .accessibilityLabel("Dismiss tip")
        }
        .padding(12)
        .background(theme.accent.opacity(0.10))
    }

    private func pencilToast(_ message: String) -> some View {
        VStack {
            Spacer()
            Label(message, systemImage: "applepencil.tip")
                .font(.callout.weight(.medium))
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(theme.accent.opacity(0.4)))
                .foregroundStyle(theme.textPrimary)
                .padding(.bottom, 28)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Helpers

    private func panel<Content: View>(title: String, systemImage: String,
                                      @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Label(title, systemImage: systemImage)
                .font(.headline).foregroundStyle(theme.textPrimary)
                .padding(.horizontal, 14).padding(.vertical, 10)
            Divider()
            content()
        }
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(theme.border, lineWidth: 1))
        .shadow(color: .black.opacity(isDark ? 0.4 : 0.08), radius: 12, y: 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func flashPencil(_ message: String) {
        pencilFlash = message
        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            if pencilFlash == message { pencilFlash = nil }
        }
    }

    static let sample = """
    # Field Notes

    Tap into the editor and **write with your Apple Pencil** — Scribble turns
    handwriting into text. Try a *double-tap* to toggle bold.

    ## Checklist
    - [x] Set up the easel
    - [ ] Sketch the harbor
    - [ ] Add color

    ## Quote
    > "Make visible what, without you, might perhaps never have been seen."

    ## Math
    The area of a circle is $A = \\pi r^2$.

    ## Diagram
    ```mermaid
    flowchart LR
      Idea --> Sketch --> Notes --> Share
    ```

    ```swift
    let note = "drawn with a pencil"
    ```
    """
}
