## ADDED Requirements

### Requirement: Video URL classification
The system SHALL provide a pure, deterministic classifier that maps a URL string to one
of: `directFile` (a streamable video file), `provider` (a known video site such as
YouTube or Vimeo), or `notVideo`.

#### Scenario: Direct video file
- **WHEN** the URL path ends in `.mp4`, `.mov`, `.m4v`, or `.m3u8` (case-insensitive,
  ignoring any query string)
- **THEN** the classifier SHALL return `directFile`

#### Scenario: Provider URL
- **WHEN** the URL host is a known provider (e.g. `youtube.com`, `youtu.be`, `vimeo.com`,
  including `www.` and `m.` subdomains)
- **THEN** the classifier SHALL return `provider`

#### Scenario: Non-video URL
- **WHEN** the URL is neither a direct video file nor a known provider (e.g. a `.png`
  image or an article link)
- **THEN** the classifier SHALL return `notVideo`

### Requirement: Linked-thumbnail video embed
The system SHALL render a Markdown linked image whose link destination is a video URL,
i.e. `[![alt](thumbnail)](videoURL)`, as a tappable thumbnail with a visible play
indicator instead of as plain link text.

#### Scenario: Tap a provider thumbnail
- **WHEN** the user taps a thumbnail whose link destination classifies as `provider`
- **THEN** the system SHALL open the video URL externally via the platform `openURL`
  action (no in-app WebView)

#### Scenario: Tap a direct-file thumbnail
- **WHEN** the user taps a thumbnail whose link destination classifies as `directFile`
- **THEN** the system SHALL begin inline native playback of the video in place of the
  thumbnail

#### Scenario: Thumbnail image is shown
- **WHEN** a linked-thumbnail video is rendered
- **THEN** the thumbnail image SHALL be displayed (loaded like any Markdown image) with a
  play overlay, and the `alt` text SHALL be used as the accessibility label

### Requirement: Direct video file inline playback
The system SHALL render an image node whose source is a direct video file
(`![alt](clip.mp4)`) as an inline native video player using AVKit, without a WebView.

#### Scenario: Inline player for a video source
- **WHEN** a block is solely an image whose source classifies as `directFile`
- **THEN** the system SHALL render an inline `AVPlayer`-backed player sized to a sensible
  default aspect ratio

#### Scenario: No WebView is used
- **WHEN** any video is rendered or played by the core module
- **THEN** the implementation SHALL NOT instantiate a WebView/`WKWebView`; provider videos
  open externally and direct files play via AVKit

### Requirement: Graceful fallback
The system SHALL degrade gracefully when inline playback is unavailable on the current
platform or the media cannot be loaded.

#### Scenario: Inline playback unavailable
- **WHEN** the platform cannot present an inline AVKit player
- **THEN** the system SHALL fall back to a tappable thumbnail/placeholder that opens the
  video URL externally
