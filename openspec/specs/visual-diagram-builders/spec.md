# visual-diagram-builders Specification

## Purpose
TBD - created by archiving change add-visual-diagram-builders. Update Purpose after archive.
## Requirements
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

### Requirement: Additional diagram builders (sequence, mindmap, gantt)
The system SHALL provide form-based visual builders for sequence diagrams (participants +
messages), mindmaps (indented nodes), and gantt charts (title + sectioned tasks with
durations), each serialized to the corresponding Mermaid block.

#### Scenario: Build a sequence diagram
- **WHEN** the user adds participants and a message between two of them
- **THEN** the block SHALL render the sequence diagram and serialize to a `sequenceDiagram`
  block with `participant` lines and a `A->>B: text` message

#### Scenario: Build a mindmap
- **WHEN** the user adds nodes and indents one under another
- **THEN** the block SHALL serialize to a `mindmap` block whose indentation reflects the hierarchy

#### Scenario: Build a gantt chart
- **WHEN** the user sets a title and adds tasks with sections and durations
- **THEN** the block SHALL serialize to a `gantt` block with `title`, `section`, and task lines

### Requirement: Remaining diagram types unchanged
The system SHALL keep the Phase-1 source editor (with live preview) for Mermaid types without a
visual builder yet (class, state, ER, gitGraph, journey, timeline).

#### Scenario: Unsupported type uses source editor
- **WHEN** a `classDiagram` block is selected
- **THEN** the system SHALL present the source editor, not a visual builder

### Requirement: Builders for class, state, ER, gitGraph, journey, timeline
The system SHALL provide form-based visual builders for the remaining Mermaid diagram types —
class diagrams, state diagrams, entity-relationship diagrams, git graphs, user journeys, and
timelines — each serialized to its Mermaid block, completing visual coverage of all supported
diagram types.

#### Scenario: Build a class diagram
- **WHEN** the user adds classes, members, and a relationship
- **THEN** the block SHALL serialize to a `classDiagram` block and render

#### Scenario: Build a git graph
- **WHEN** the user adds commit/branch/checkout/merge operations in order
- **THEN** the block SHALL serialize to a `gitGraph` block and render

#### Scenario: Every diagram type has a visual builder
- **WHEN** any of class, state, ER, gitGraph, journey, or timeline block is selected
- **THEN** the system SHALL present a visual builder rather than the source editor

