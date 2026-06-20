## 1. Parser prerequisite

- [x] 1.1 Verify `parseLink` balances nested brackets so `[![alt](thumb)](url)` yields a `.link` wrapping a single `.image`; fix the label scan if it truncates at the inner `]`
- [x] 1.2 Add a parser test asserting `[![alt](thumb)](url)` parses to `.link(destination: url, children: [.image(source: thumb, alt:)])`

## 2. Video URL classifier

- [x] 2.1 Add `VideoSource` enum (`directFile`, `provider`, `notVideo`) and `classify(_:)` in `Rendering/VideoView.swift`
- [x] 2.2 Implement file detection (`.mp4`/`.mov`/`.m4v`/`.m3u8`, case-insensitive, ignoring query/fragment) and provider detection (`youtube.com`/`youtu.be`/`vimeo.com`, stripping `www.`/`m.`)
- [x] 2.3 Add unit tests for `classify` covering direct files, providers (with subdomains/query), and non-video URLs (images, article links)

## 3. Player and thumbnail views

- [x] 3.1 Add `VideoPlayerView(url:)` using AVKit `VideoPlayer`/`AVPlayer` under `#if canImport(AVKit)`, 16:9 default, constrained to reading width
- [x] 3.2 Add `VideoThumbnailView(thumbnail:alt:destination:source:)` — thumbnail (reusing `MarkdownImageView`) + play overlay; `directFile` tap swaps to inline player, `provider` tap calls `@Environment(\.openURL)`
- [x] 3.3 Implement graceful fallback (tappable placeholder that opens externally) where AVKit/inline playback is unavailable

## 4. Wire into rendering

- [x] 4.1 In `BlockView`, route a block that is solely an image with a `directFile` source to `VideoPlayerView`
- [x] 4.2 In `BlockView`, detect a block that is solely a `.link` wrapping one `.image` with a video destination and route to `VideoThumbnailView`; leave non-video linked images unchanged
- [x] 4.3 Confirm existing image/link rendering is unaffected for non-video URLs

## 5. Tests and verification

- [x] 5.1 Add rendering-level tests for the detection helpers (solo image-video, solo linked-image-video, non-video passthrough)
- [x] 5.2 Run the full test suite; ensure no regressions
- [x] 5.3 Build the PencilNotes app and add a video example (linked YouTube thumbnail + a direct `.mp4`) to the sample document

## 6. Documentation

- [x] 6.1 Update README to list video support and the no-WebView / provider-opens-externally behavior
- [x] 6.2 Update DocC (`Documentation.docc/SwiftMarkdownEngine.md`) accordingly
- [x] 6.3 Validate the change with `openspec validate add-video-support`
