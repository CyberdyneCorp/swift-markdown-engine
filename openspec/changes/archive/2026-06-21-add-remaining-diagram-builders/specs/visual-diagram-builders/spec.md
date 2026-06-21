## ADDED Requirements

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
