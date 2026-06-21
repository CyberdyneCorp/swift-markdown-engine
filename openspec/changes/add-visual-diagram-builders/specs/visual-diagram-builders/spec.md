## ADDED Requirements

### Requirement: Visual flowchart builder
The system SHALL provide a form-based flowchart builder in the WYSIWYG editor: choose a
direction, add/edit/remove nodes (id, label, shape) and edges (from, to, optional label),
serialized to a `flowchart` Mermaid block — no Mermaid syntax shown to the user.

#### Scenario: Build a flowchart
- **WHEN** the user adds two nodes and an edge between them and picks a direction
- **THEN** the block SHALL render the flowchart and serialize to a `flowchart <dir>` block
  with the nodes and the edge

#### Scenario: Edit an existing flowchart
- **WHEN** a `flowchart` (or `graph`) block is selected
- **THEN** its nodes, edges, and direction SHALL populate the builder for editing

### Requirement: Visual pie-chart builder
The system SHALL provide a pie-chart builder: set a title and add/edit/remove slices (label +
numeric value), serialized to a `pie` Mermaid block.

#### Scenario: Build a pie chart
- **WHEN** the user sets a title and adds slices with values
- **THEN** the block SHALL render the pie chart and serialize to a `pie title …` block with
  `"label" : value` lines

### Requirement: Other diagram types unchanged
The system SHALL keep the Phase-1 source editor (with live preview) for all Mermaid types that
do not yet have a visual builder.

#### Scenario: Unsupported type uses source editor
- **WHEN** a `sequenceDiagram` (or other non-flowchart/non-pie) block is selected
- **THEN** the system SHALL present the source editor, not a visual builder
