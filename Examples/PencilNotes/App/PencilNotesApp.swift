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

    /// Optional bridges: highlighted code (Highlightr), rendered LaTeX (SwiftMath), and an
    /// inline YouTube/Vimeo player (WKWebView, injected here so the engine stays WebView-free).
    private var services: MarkdownServices {
        MarkdownServices(
            syntaxHighlighter: HighlightrSyntaxHighlighter(theme: isDark ? "atom-one-dark" : "xcode"),
            latexRenderer: SwiftMathLatexRenderer(),
            videoEmbedder: YouTubeEmbedder()
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
    Inline: the area of a circle is $A = \\pi r^2$.

    A 2×2 matrix:
    $$\\begin{bmatrix} a & b \\\\ c & d \\end{bmatrix}$$

    The Gaussian integral:
    $$\\int_{0}^{\\infty} e^{-x^{2}}\\,dx = \\frac{\\sqrt{\\pi}}{2}$$

    A derivative (power rule):
    $$\\frac{d}{dx}\\left( x^{n} \\right) = n\\,x^{n-1}$$

    ## Mindmap
    ```mermaid
    mindmap
      root((PencilNotes))
        Editing
          Apple Pencil
          Scribble
        Live Preview
          Mermaid
          LaTeX
          Code
        Themes
          Light
          Dark
    ```

    ## Git graph
    ```mermaid
    gitGraph
      commit
      branch feature
      checkout feature
      commit
      commit
      checkout main
      merge feature
      commit tag:"v1.0"
    ```

    ## Flowchart
    ```mermaid
    flowchart LR
      Idea --> Sketch --> Notes --> Share
    ```

    ## Sequence diagram
    ```mermaid
    sequenceDiagram
      participant User
      participant Editor
      participant Preview
      User->>Editor: Type Markdown
      Editor->>Preview: Update
      Preview-->>User: Rendered view
    ```

    ## Class diagram
    ```mermaid
    classDiagram
      class Document
      class Block
      class Inline
      Document : +String text
      Document : +render()
      Document --> Block
      Block --> Inline
    ```

    ## Gantt
    ```mermaid
    gantt
      title PencilNotes roadmap
      section Design
      Sketch : a1, 3d
      Ink : after a1, 2d
      section Build
      Editor : b1, 4d
      Preview : after b1, 3d
      Launch : milestone, 1d
    ```

    ## Use case (UML)
    Mermaid has no native use-case diagram, so it's modeled as a flowchart —
    actors as circles, use cases as stadium shapes:

    ```mermaid
    flowchart LR
      User((User))
      Pencil((Apple Pencil))
      User --> Write([Write a note])
      User --> Preview([Preview Markdown])
      User --> Theme([Toggle light or dark])
      Pencil --> Scribble([Scribble to text])
      Pencil --> Bold([Double-tap to bold])
      Preview --> Render([Render math and diagrams])
    ```

    ## Video
    Tap the thumbnail to play the YouTube video inline (this demo injects a WebView
    player; the engine core itself stays WebView-free):

    [![Watch on YouTube](https://img.youtube.com/vi/aqz-KE-bpKQ/hqdefault.jpg)](https://www.youtube.com/watch?v=aqz-KE-bpKQ)

    A direct video file plays inline with the native AVKit player:

    ![Sample clip](https://www.w3schools.com/html/mov_bbb.mp4)

    ## Image
    Images load from a URL (needs a network connection):

    ![Placeholder scenery](https://picsum.photos/seed/pencilnotes/640/320)

    ```swift
    let note = "drawn with a pencil"
    ```
    """
}
