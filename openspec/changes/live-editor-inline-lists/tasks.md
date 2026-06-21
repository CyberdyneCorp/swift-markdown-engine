## 1. Flat-list rendering as text

- [x] 1.1 Add `LiveStyler.isFlatList` (a `.list` whose every item is a single paragraph).
- [x] 1.2 In `isTextBlock`, return `true` for flat lists so they render as inline text.
- [x] 1.3 Add a `styleListMarkers` pass to `LiveStyler.styled` that styles each line's
      leading marker (bullet/number) and any `[ ]`/`[x]` checkbox token.

## 2. Keyboard behaviors

- [x] 2.1 Implement `textView(_:shouldChangeTextIn:replacementText:)`.
- [x] 2.2 Enter: continue the list with the next marker (increment ordered markers);
      on an empty item, remove the marker to end the list.
- [x] 2.3 Tab: indent the current list item by one level.
- [x] 2.4 After a handled edit, reconstruct the binding and restyle the active paragraph.

## 3. Checkbox toggle

- [x] 3.1 In the tap recognizer, detect a tap on a `[ ]`/`[x]` token at a list-item line
      start and toggle the character, then reconstruct + restyle.

## 4. Verification

- [x] 4.1 Build and deploy to the iPad; capture Live screenshots showing styled markers.
- [x] 4.2 Manually verify Enter-continuation, Tab indent, and checkbox toggle on device.
- [x] 4.3 Run the full PencilNotes UI test suite (no regressions) and the serializer
      round-trip tests.
- [x] 4.4 Add a UI test covering flat-list round-trip through Live reconstruction
      (checkbox toggle verified visually on device; precise tap coords too flaky for CI).
