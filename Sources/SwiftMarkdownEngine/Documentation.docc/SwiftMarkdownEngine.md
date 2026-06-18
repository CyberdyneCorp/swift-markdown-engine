# ``SwiftMarkdownEngine``

A fully native Markdown renderer for iOS, macOS, and watchOS — CommonMark + GFM plus
code, tables, LaTeX math, and Mermaid diagrams, with no WebView.

## Overview

`SwiftMarkdownEngine` parses Markdown into an immutable, `Sendable` document model and
renders it natively in SwiftUI. Heavyweight integrations (syntax highlighting, LaTeX)
are injected through service protocols, so the core has zero external dependencies.

```swift
import SwiftUI
import SwiftMarkdownEngine

struct ContentView: View {
    var body: some View {
        MarkdownView("""
        # Hello
        Some **bold** text, `code`, and inline math $E=mc^2$.

        ```mermaid
        flowchart LR
          A --> B
        ```
        """)
        .markdownTheme(.dark)
    }
}
```

To edit Markdown, use `MarkdownEditor` from the **MarkdownEditor** product (iOS/macOS).

## Topics

### Rendering

- ``MarkdownView``
- ``MarkdownTheme``
- ``MarkdownConfiguration``

### Document model

- ``MarkdownDocument``
- ``MarkdownParser``
- ``BlockNode``
- ``InlineNode``
- ``SourceRange``

### Services

- ``MarkdownServices``
- ``SyntaxHighlighter``
- ``LatexRenderer``
- ``WikiLinkResolver``
- ``EmbeddedImageProvider``
- ``CodeLanguage``
