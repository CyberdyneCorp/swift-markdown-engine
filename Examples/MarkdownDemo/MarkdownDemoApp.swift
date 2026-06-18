// Example app demonstrating SwiftMarkdownEngine on iOS, macOS, and watchOS.
//
// This is sample source, not built by the Swift package. To run it: create an
// Xcode multiplatform App, add this package as a dependency (SwiftMarkdownEngine
// for all targets, MarkdownEditor for iOS/macOS), and add these files to the app
// target. See Examples/MarkdownDemo/README.md.

import SwiftUI
import SwiftMarkdownEngine

@main
struct MarkdownDemoApp: App {
    var body: some Scene {
        WindowGroup {
            #if os(watchOS)
            ReaderView()        // watchOS: render-only
            #else
            SplitDemoView()     // iOS/macOS: render + edit
            #endif
        }
    }
}

/// A read-only renderer showcase (works on every platform, including watchOS).
struct ReaderView: View {
    var body: some View {
        MarkdownView(Self.sample)
            .markdownConfiguration(MarkdownConfiguration(interactiveCheckboxes: true))
    }

    static let sample = """
    # SwiftMarkdownEngine

    A **native** Markdown renderer with `code`, tables, math, and diagrams.

    ## Task list
    - [x] Parse CommonMark + GFM
    - [ ] Ship 1.0

    ## Table
    | Feature | Status |
    |:--------|:------:|
    | Mermaid | ✅ |
    | LaTeX   | ✅ |

    ## Math
    Inline $E=mc^2$ and a block:

    $$\\int_0^1 x^2\\,dx = \\frac{1}{3}$$

    ## Diagram
    ```mermaid
    flowchart LR
      A[Start] --> B{OK?}
      B -->|yes| C[Done]
      B -->|no| A
    ```

    ```swift
    print("highlighted code")
    ```
    """
}

#if os(iOS) || os(macOS)
import MarkdownEditor

/// A live editor on the left and the rendered preview on the right.
struct SplitDemoView: View {
    @State private var text = ReaderView.sample

    var body: some View {
        HStack(spacing: 0) {
            MarkdownEditor(text: $text)
            Divider()
            MarkdownView(text)
                .markdownConfiguration(MarkdownConfiguration(interactiveCheckboxes: true))
        }
    }
}
#endif
