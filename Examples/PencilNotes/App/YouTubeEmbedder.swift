import SwiftUI
import WebKit
import SwiftMarkdownEngine

/// Plays a provider video (YouTube/Vimeo) inline via a `WKWebView` iframe embed. This
/// lives in the example app — not the engine — so the core stays WebView-free; it is
/// injected through `MarkdownServices.videoEmbedder`. When absent, provider videos open
/// externally instead.
struct YouTubeEmbedder: VideoEmbedder {
    @MainActor func embedView(for url: URL) -> AnyView? {
        guard let embed = Self.embedURL(for: url) else { return nil }
        return AnyView(
            WebVideoView(url: embed)
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.vertical, 6)
        )
    }

    /// Maps a watch/share URL to an inline-playable embed URL for supported providers.
    static func embedURL(for url: URL) -> URL? {
        var host = (url.host ?? "").lowercased()
        if host.hasPrefix("www.") { host.removeFirst(4) }
        if host.hasPrefix("m.") { host.removeFirst(2) }

        switch host {
        case "youtu.be":
            return URL(string: "https://www.youtube.com/embed/\(url.lastPathComponent)?playsinline=1")
        case "youtube.com":
            if url.path.hasPrefix("/embed/") { return url }
            if let id = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "v" })?.value {
                return URL(string: "https://www.youtube.com/embed/\(id)?playsinline=1")
            }
            return nil
        case "vimeo.com":
            return URL(string: "https://player.vimeo.com/video/\(url.lastPathComponent)")
        default:
            return nil
        }
    }
}

/// Minimal SwiftUI wrapper over `WKWebView` configured for inline media playback.
private struct WebVideoView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let web = WKWebView(frame: .zero, configuration: config)
        web.scrollView.isScrollEnabled = false
        web.isOpaque = false
        web.backgroundColor = .clear
        web.load(URLRequest(url: url))
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        if web.url != url { web.load(URLRequest(url: url)) }
    }
}
