# Device & E2E testing

This document describes how SwiftMarkdownEngine is tested across simulators (in CI)
and physical devices (manually / via a device farm), including the Apple Pencil
verification steps that cannot be automated in standard CI.

## Test layers

| Layer | What it covers | Where it runs |
|-------|----------------|---------------|
| Unit (`swift test`) | Parser, model, renderer logic, Mermaid parsers, editor commands, scanning, concurrency | macOS CI + locally |
| Cross-platform build | Core + editor compile for iOS, macOS, watchOS | macOS CI (`xcodebuild build`) |
| E2E (XCUITest) | Render a rich document and drive editor flows in a host app | iOS/iPad/Mac simulators in CI |
| On-device | Apple Pencil interactions on a physical iPad | Manual / device farm |

The unit and cross-platform layers run today in `.github/workflows/ci.yml`. The
XCUITest host app (tasks 13.1–13.3) requires an Xcode app project and is tracked
separately; this document defines the flows it must cover and the device matrix.

## Simulator E2E matrix (CI)

Run with `xcodebuild test` once the host app exists:

| Device | OS | Purpose |
|--------|----|---------|
| iPhone (latest) | iOS 17+ | Phone rendering + editing |
| iPad (latest) | iPadOS 17+ | Split layout, Scribble (simulated) |
| Mac (My Mac) | macOS 14+ | Pointer/keyboard editing |

### E2E flows to assert

1. **Render** a document containing headings, GFM tables, a fenced code block, inline
   and block math, a task list, and a Mermaid flowchart; assert key elements are
   present and a heading exposes the `.isHeader`/heading-level trait.
2. **Edit**: select text → tap Bold → assert the buffer contains `**…**`.
3. **Smart lists**: type `- a`, press Return → assert a new `- ` marker appears;
   press Return on the empty item → assert the marker is removed.
4. **Checkbox**: place the caret on a task line → tap the checkbox toolbar button →
   assert `- [ ]` ↔ `- [x]` toggles.
5. **Wiki completion**: type `[[` with a resolver configured → assert the suggestion
   overlay appears and selecting one inserts `target]]`.

## On-device Apple Pencil plan (physical iPad)

These require a physical iPad with Apple Pencil and cannot be synthesized by XCUITest;
run them manually or on a device farm that supports stylus input. Record pass/fail per
build in the release checklist.

| # | Interaction | Steps | Expected |
|---|-------------|-------|----------|
| 1 | Scribble insertion | Handwrite words over the editor | Text is inserted at the write location |
| 2 | Scratch-out delete | Scribble a word, then scratch it out | The word is removed |
| 3 | Insert space | Draw a vertical bar between words | A space is inserted |
| 4 | Select by circling | Circle a word | The word becomes selected |
| 5 | Pencil double-tap | Double-tap the Pencil while editing | The configured action fires (defaults to Bold) |
| 6 | Hover preview | Hover the Pencil near the text (Pencil Pro / M2 iPad) | Caret position previews without committing input |
| 7 | Squeeze | Squeeze the Pencil (Pencil Pro) | The configured squeeze action fires |

Items 1–5 are supported today (Scribble via `UITextView`, double-tap via
`UIPencilInteraction`). Items 6–7 depend on hover/squeeze hardware APIs and are
pending.

## Device-farm note

`xcodebuild test` on a self-hosted runner with a tethered iPad can execute items 1–5
through Scribble's accessibility path; items 6–7 remain manual. Log any coverage gaps
in the PR so "device tested" is never overstated.
