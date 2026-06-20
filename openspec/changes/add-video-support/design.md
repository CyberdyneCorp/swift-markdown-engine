## Context

The parser already produces the right node shapes: `[![alt](thumb)](url)` becomes
`.link(destination: url, children: [.image(source: thumb, alt:)])`, and `![alt](v.mp4)`
becomes `.image(source: "v.mp4")`. `BlockView.inlineText` already special-cases "a
paragraph that is solely an image" and routes it to `MarkdownImageView`. So video support
is primarily a **rendering** concern with a small classification helper — no model change.

Hard constraint: the core module advertises "native rendering, no WebView". AVKit is a
system media framework (not a WebView), so inline file playback is allowed in core;
provider embeds (which need a WebView) are explicitly out of scope and open externally.

## Goals / Non-Goals

Goals:
- Render `[![alt](thumb)](videoURL)` as a tappable thumbnail with a play overlay.
- Render `![alt](video.mp4)` as an inline AVKit player.
- Pure, unit-tested URL classification (directFile / provider / notVideo).
- Zero new third-party dependencies; no WebView.

Non-Goals:
- In-app YouTube/Vimeo playback (deferred to a future optional WebView bridge).
- A new Markdown directive syntax.
- Video controls/customization beyond the system player.

## Decisions

### Detect at render time, no new model node
Reuse the existing "solo image / solo linked-image" block detection in `BlockView`
instead of adding a `.video` `InlineKind`. Rationale: keeps the parser and public model
unchanged, video is inherently block-level here, and the linked-image structure already
exists. A model node would add API surface for no behavioral gain.

### Pure classifier `VideoSource`
Add `enum VideoSource { case directFile, provider, notVideo }` with
`static func classify(_ urlString: String) -> VideoSource`. File detection: lowercased
path suffix in `{mp4, mov, m4v, m3u8}`, ignoring query/fragment. Provider detection: host
(minus `www.`/`m.`) in a known set `{youtube.com, youtu.be, vimeo.com}`. This is the only
logic that needs direct unit tests; views are thin wrappers over it.

### Rendering paths in `BlockView`
- Solo image, source `directFile` → `VideoPlayerView(url:)` (inline AVKit).
- Solo image, source `provider`/`notVideo` → existing `MarkdownImageView` (unchanged).
- Solo linked image (`.link` wrapping one `.image`) where destination classifies as a
  video → `VideoThumbnailView(thumbnail:alt:destination:source:)`.
  - `directFile`: tap swaps the thumbnail for an inline `VideoPlayerView`.
  - `provider`: tap calls `@Environment(\.openURL)` with the destination.
- Solo linked image with a non-video destination → keep current behavior.

### AVKit usage, guarded
`import AVKit` under `#if canImport(AVKit)`; use SwiftUI `VideoPlayer(player:)` with an
`AVPlayer(url:)`. Where AVKit/`VideoPlayer` is unavailable, fall back to a thumbnail/
placeholder that opens the URL externally. Default aspect ratio 16:9, constrained to the
reading width.

### Parser robustness check
Confirm `parseLink` balances nested brackets so the outer label of
`[![alt](thumb)](url)` is captured as `![alt](thumb)` (not truncated at the inner `]`).
If it does not, fix the label scan and add a parser regression test. This is a
prerequisite for the linked-thumbnail path.

## Risks / Trade-offs

- Provider videos don't play in-app (open externally). Accepted to preserve the
  no-WebView guarantee; a bridge module can add inline embeds later.
- `VideoPlayer` minimum OS (iOS 14 / macOS 11) is already below the package's iOS 17 /
  macOS 14 floor — no extra gating needed beyond `canImport`.
- Autoplaying/loading many players is costly; players are created lazily (only after the
  user taps a thumbnail, or for an explicit inline video block).

## Migration Plan

Additive only — no breaking changes. Existing non-video images and links render exactly as
before. New behavior triggers solely when a block is a solo (linked) image with a video
URL.

## Open Questions

- Poster frame for a bare `![](clip.mp4)` (no thumbnail): start with the system player's
  default first-frame; revisit if a poster attribute is desired.
