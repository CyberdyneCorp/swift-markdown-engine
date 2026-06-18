import SwiftUI
import SwiftMarkdownEngine
import MarkdownEditor

/// Host app for the XCUITest E2E suite. It exposes a render screen and an editor
/// screen, plus a "mirror" Text so tests can assert the editor's buffer.
@main
struct MarkdownE2EApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
    }
}

struct RootView: View {
    @State private var editorText = "hello"

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
        VStack(spacing: 0) {
            MarkdownView(Self.sample)
                .frame(maxHeight: .infinity)

            Divider()

            MarkdownEditor(text: $editorText)
                .frame(height: 160)

            // Mirror of the editor buffer for test assertions.
            Text(editorText)
                .accessibilityIdentifier("editorMirror")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
        }
    }
}
