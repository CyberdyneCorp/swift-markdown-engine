## Why

Markdown authors commonly embed videos using the linked-thumbnail pattern
`[![alt](thumbnail)](videoURL)` (e.g. a YouTube preview) or by pointing an image at a
video file `![alt](clip.mp4)`. Today the engine renders the first as plain link text and
the second as a broken image, so video content is unusable in the rendered output.

## What Changes

- Recognize two video-bearing Markdown patterns and render them as media instead of text:
  - `[![alt](thumb)](videoURL)` → a tappable thumbnail with a play overlay.
  - `![alt](video.mp4)` where the source is a direct video file → an inline native player.
- Play **direct video files** (`.mp4`, `.mov`, `.m4v`, `.m3u8`) **inline via AVKit**
  (`AVPlayer`/`VideoPlayer`). No WebView is introduced — the core stays WebView-free.
- **Provider URLs** (YouTube, Vimeo, and other non-file links) **open externally** via the
  SwiftUI `openURL` action when the thumbnail is tapped.
- Add a pure, testable URL classifier that maps a URL to `directFile`, `provider`, or
  `notVideo`, used by both the parser-adjacent detection and the renderer.
- Update README and DocC to document video support and that provider videos open
  externally (no in-app WebView).

Not in scope: in-app embedded YouTube/Vimeo playback (would require a WebView; deferred to
a future optional bridge module).

## Capabilities

### New Capabilities
- `video-embeds`: detecting video-bearing Markdown (linked thumbnails and direct video
  files), classifying video URLs (direct file vs provider), inline native playback of
  direct files, and external open for provider videos — all without a WebView.

### Modified Capabilities
- `document-rendering`: a block that is solely a video image or a linked-image video SHALL
  render as the video embed (player or tappable thumbnail) rather than as an image/link.

## Impact

- Code: new `Rendering/VideoView.swift` (classifier + player/thumbnail views); changes in
  `Rendering/BlockView.swift` (route solo image / linked-image blocks to video), reuse of
  `MarkdownImageView` for thumbnails.
- Dependencies: AVKit (system framework, guarded with `#if canImport(AVKit)`) — no new
  third-party packages, no WebView.
- Platforms: iOS/macOS via `VideoPlayer`; graceful fallback (tappable thumbnail that opens
  externally) where inline playback is unavailable.
- Docs: README + DocC note the new capability and the no-WebView/external-open behavior.
