import SwiftUI
#if canImport(AVKit)
import AVKit
#endif

/// Classifies a URL string for video handling. Pure and deterministic so it can be
/// unit-tested without any view or platform dependency.
public enum VideoSource: Equatable, Sendable {
    /// A streamable video file (plays inline via AVKit).
    case directFile
    /// A known video site (YouTube/Vimeo) — opened externally, never in a WebView.
    case provider
    /// Not a video.
    case notVideo

    private static let fileExtensions = ["mp4", "mov", "m4v", "m3u8"]
    private static let providerHosts: Set<String> = ["youtube.com", "youtu.be", "vimeo.com"]

    public static func classify(_ urlString: String) -> VideoSource {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        guard let components = URLComponents(string: trimmed) else { return .notVideo }

        // Direct file: match the path's extension, ignoring any query/fragment.
        let path = components.path.lowercased()
        if fileExtensions.contains(where: { path.hasSuffix(".\($0)") }) { return .directFile }

        // Provider: match the host, ignoring `www.`/`m.` subdomains.
        if var host = components.host?.lowercased() {
            if host.hasPrefix("www.") { host.removeFirst(4) }
            if host.hasPrefix("m.") { host.removeFirst(2) }
            if providerHosts.contains(host) { return .provider }
        }
        return .notVideo
    }
}

/// Inline native player for a direct video file. Uses AVKit (a system media framework,
/// not a WebView). Where AVKit is unavailable (e.g. watchOS), falls back to a button that
/// opens the URL externally.
struct VideoPlayerView: View {
    let url: URL

    @Environment(\.openURL) private var openURL

    var body: some View {
        #if canImport(AVKit)
        AVKitPlayer(url: url)
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.vertical, 6)
            .accessibilityLabel("Video")
        #else
        VideoExternalButton(url: url, label: "Play video")
        #endif
    }
}

#if canImport(AVKit)
/// Wraps `VideoPlayer` and holds the `AVPlayer` in state so it is created once rather
/// than on every body evaluation.
private struct AVKitPlayer: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
            } else {
                Color.black
            }
        }
        .onAppear { if player == nil { player = AVPlayer(url: url) } }
        .onDisappear { player?.pause() }
    }
}
#endif

/// A tappable thumbnail with a play overlay for `[![alt](thumb)](videoURL)`. A direct-file
/// destination plays inline; a provider destination opens externally on tap.
struct VideoThumbnailView: View {
    let thumbnail: String
    let alt: String
    let destination: String
    let source: VideoSource

    @State private var playingInline = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        if playingInline, let url = URL(string: destination) {
            VideoPlayerView(url: url)
        } else {
            Button(action: activate) {
                MarkdownImageView(source: thumbnail, alt: alt)
                    .overlay {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 52))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.55))
                            .shadow(radius: 6)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(alt.isEmpty ? "Play video" : alt)
            .accessibilityAddTraits([.isButton, .startsMediaSession])
        }
    }

    private func activate() {
        switch source {
        case .directFile:
            playingInline = true
        case .provider, .notVideo:
            if let url = URL(string: destination) { openURL(url) }
        }
    }
}

/// Fallback used when inline playback is unavailable: a button that opens the video URL.
private struct VideoExternalButton: View {
    let url: URL
    let label: String
    @Environment(\.openURL) private var openURL
    @Environment(\.resolvedMarkdownTheme) private var theme

    var body: some View {
        Button { openURL(url) } label: {
            Label(label, systemImage: "play.rectangle.fill")
                .font(theme.bodyFont)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.accent)
    }
}
