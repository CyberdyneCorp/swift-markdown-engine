import SwiftUI

/// Renders a Markdown image, resolving bytes through the configured
/// `EmbeddedImageProvider` when present and otherwise loading the URL directly.
/// Shows a placeholder while loading and on failure.
struct MarkdownImageView: View {
    let source: String
    let alt: String

    @Environment(\.markdownServices) private var services
    @Environment(\.resolvedMarkdownTheme) private var theme
    @State private var phase: Phase = .loading

    private enum Phase { case loading, success(Image), failure }

    var body: some View {
        content
            .accessibilityLabel(alt.isEmpty ? "image" : alt)
            .task(id: source) { await load() }
    }

    @ViewBuilder private var content: some View {
        switch phase {
        case .loading:
            placeholder(systemName: "photo")
        case .success(let image):
            image.resizable().scaledToFit()
        case .failure:
            placeholder(systemName: "exclamationmark.triangle")
        }
    }

    private func placeholder(systemName: String) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(theme.surface)
            .frame(height: 120)
            .overlay(Image(systemName: systemName).foregroundStyle(theme.textSecondary))
    }

    private func load() async {
        if let provider = services.imageProvider {
            if let data = await provider.imageData(for: source), let image = makeImage(from: data) {
                phase = .success(image); return
            }
            phase = .failure; return
        }
        guard let url = URL(string: source) else { phase = .failure; return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = makeImage(from: data) { phase = .success(image) } else { phase = .failure }
        } catch {
            phase = .failure
        }
    }
}
