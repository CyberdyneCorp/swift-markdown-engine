import SwiftUI
import SwiftMarkdownEngine
import MarkdownEditor

/// Host app for the XCUITest E2E suite. It exposes a render screen and an editor
/// screen, plus a "mirror" Text (newlines shown as ⏎) so tests can assert the
/// editor's buffer without depending on the text view's internals.
@main
struct MarkdownE2EApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
    }
}

/// Wiki-link resolver with a fixed page set so completion flows are deterministic.
struct DemoWikiResolver: WikiLinkResolver {
    let pages = ["Page One", "Page Two", "Playbook"]

    func resolve(_ target: String) -> WikiLinkTarget? {
        pages.contains(target) ? WikiLinkTarget(identifier: target, title: target, exists: true) : nil
    }

    func suggestions(matching query: String) -> [WikiLinkTarget] {
        pages
            .filter { query.isEmpty || $0.lowercased().contains(query.lowercased()) }
            .map { WikiLinkTarget(identifier: $0, title: $0, exists: true) }
    }
}

struct RootView: View {
    @State private var editorText = ""

    static let sample = """
    # E2E Heading

    Body with **bold**, `code`, and inline math $E=mc^2$.

    | A | B |
    |---|---|
    | 1 | 2 |

    - [x] done
    - [ ] todo

    ```swift
    print("hi")
    ```

    ```mermaid
    flowchart LR
      A --> B
    ```
    """

    var body: some View {
        // Editor on top so its formatting toolbar stays above the keyboard (keeps the
        // toolbar buttons hittable for XCUITest, notably on iPad).
        VStack(spacing: 0) {
            MarkdownEditor(text: $editorText, wikiLinkResolver: DemoWikiResolver())
                .frame(height: 240)

            // Mirror of the editor buffer for test assertions. Newlines render as ⏎
            // and spaces as · so whitespace is explicit and not collapsed by the
            // accessibility layer (iPhone collapses runs of spaces; iPad does not).
            Text(editorText
                .replacingOccurrences(of: "\n", with: "⏎")
                .replacingOccurrences(of: " ", with: "·"))
                .accessibilityIdentifier("editorMirror")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)

            Divider()

            MarkdownView(Self.sample)
                .frame(maxHeight: .infinity)
        }
    }
}
