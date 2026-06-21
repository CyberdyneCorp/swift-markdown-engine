## ADDED Requirements

### Requirement: Video block rendering
The system SHALL render a block whose sole content is a video-bearing image as a video
embed rather than as a static image or link. This applies to a block that is solely a
linked image `[![alt](thumb)](videoURL)` with a video destination, or solely an image
`![alt](clip.mp4)` whose source is a direct video file.

#### Scenario: Linked thumbnail becomes a video embed
- **WHEN** a paragraph's only content is `[![alt](thumb)](videoURL)` and `videoURL`
  classifies as a video (direct file or provider)
- **THEN** the block SHALL render as a tappable video thumbnail, not as link text

#### Scenario: Image with a video source becomes a player
- **WHEN** a paragraph's only content is an image whose source is a direct video file
- **THEN** the block SHALL render as an inline native player, not as a broken image

#### Scenario: Non-video linked image is unchanged
- **WHEN** a linked image's destination is not a video (e.g. a page link)
- **THEN** the block SHALL retain its existing rendering behavior
