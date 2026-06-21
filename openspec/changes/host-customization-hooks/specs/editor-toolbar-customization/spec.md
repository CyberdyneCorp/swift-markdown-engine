## ADDED Requirements

### Requirement: Host-defined editor toolbar
`MarkdownEditor` SHALL accept a host-provided list of toolbar items. When none is
provided it SHALL show the default set; `showsToolbar: false` SHALL hide the toolbar.

#### Scenario: Default toolbar
- **WHEN** `MarkdownEditor` is created without a `toolbar` argument
- **THEN** it shows the built-in default formatting items

#### Scenario: Custom toolbar items
- **WHEN** a host passes a `toolbar:` array of `MarkdownToolbarItem`s
- **THEN** the toolbar shows exactly those items in order

#### Scenario: Custom action item
- **WHEN** the host includes a `.custom` item and the user taps it
- **THEN** the host's action runs with the editor's `MarkdownEditorController`
