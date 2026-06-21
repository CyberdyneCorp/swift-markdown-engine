## Why

5 of the 11 Mermaid types have visual builders; the other 6 still require source editing. This
change completes visual coverage so every diagram type can be authored without Mermaid syntax.

## What Changes

- Add visual builders for the remaining six Mermaid types: **class**, **state**, **ER**,
  **gitGraph**, **journey**, and **timeline**.
- Route those blocks to their builders in the WYSIWYG editor and add insert-menu entries.
- No engine changes — builders serialize to Mermaid source the existing renderer handles.

## Capabilities

### Modified Capabilities
- `visual-diagram-builders`: extend with builders for class, state, ER, gitGraph, journey, and
  timeline (previously these used the source editor).

## Impact

- Code: new builder views in the PencilNotes app; routing + insert-menu updates in
  `WysiwygEditorView`. No engine or dependency changes.
- Tests: open-builder smoke tests for the six new types in the iPad UI suite.
