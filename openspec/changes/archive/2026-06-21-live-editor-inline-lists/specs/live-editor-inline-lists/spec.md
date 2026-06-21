## ADDED Requirements

### Requirement: Flat lists render as inline-editable text

The Live editor SHALL render flat lists (bulleted, ordered, and GFM task lists whose
every item is a single paragraph) as inline-editable text rather than read-only block
attachments. Nested or multi-block list items SHALL continue to render as tap-to-edit
blocks.

#### Scenario: A flat bulleted list is editable inline
- **WHEN** the document contains `- a`, `- b`, `- c` and the user places the cursor in an item
- **THEN** the item text is editable in place and the list marker is shown styled

#### Scenario: A list item containing multiple blocks stays a block
- **WHEN** a list item contains more than one block (e.g. a paragraph and a nested list)
- **THEN** the list renders as a tap-to-edit block attachment, unchanged

### Requirement: Enter continues and ends lists

Pressing Enter at the end of a non-empty list item SHALL insert a new item with the next
marker (ordered markers increment). Pressing Enter on an empty list item SHALL remove the
marker and end the list.

#### Scenario: Enter continues a bulleted list
- **WHEN** the cursor is at the end of `- item` and the user presses Enter
- **THEN** a new line `- ` is inserted and the cursor is placed after it

#### Scenario: Enter on an empty item ends the list
- **WHEN** the cursor is on an item whose body is empty (just the marker) and the user presses Enter
- **THEN** the marker is removed, ending the list

#### Scenario: Ordered markers increment
- **WHEN** the cursor is at the end of `1. item` and the user presses Enter
- **THEN** the new line begins with `2. `

### Requirement: Tab indents a list item

Pressing Tab at a list item SHALL increase the item's indentation.

#### Scenario: Tab indents
- **WHEN** the cursor is in a list item and the user presses Tab
- **THEN** the item's leading indentation increases by one level

### Requirement: Tapping a checkbox toggles it

Tapping a task-list checkbox SHALL toggle its state between unchecked and checked in the
underlying Markdown.

#### Scenario: Toggle a checkbox
- **WHEN** the user taps the `[ ]` of `- [ ] task`
- **THEN** the source becomes `- [x] task` and the rendered checkbox shows as checked
