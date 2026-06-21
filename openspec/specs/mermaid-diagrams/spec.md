# mermaid-diagrams Specification

## Purpose
TBD - created by archiving change add-markdown-renderer-editor. Update Purpose after archive.
## Requirements
### Requirement: Native Mermaid rendering
The system SHALL render Mermaid diagram nodes natively using SwiftUI Canvas and a layout
engine, without a WebView or JavaScript runtime.

#### Scenario: Render a flowchart
- **WHEN** a mermaid node contains a `flowchart` definition with nodes and edges
- **THEN** the view SHALL render the nodes as shapes connected by arrows, laid out without overlap

#### Scenario: No JavaScript runtime used
- **WHEN** any Mermaid diagram is rendered
- **THEN** rendering SHALL occur entirely in native code with no WebKit or JavaScript dependency

### Requirement: Supported diagram types
The system SHALL render the following Mermaid diagram types: flowchart, state diagram,
sequence diagram, class diagram, entity-relationship diagram, pie chart, gantt chart, git
graph, user journey, mindmap, and timeline.

#### Scenario: Render a sequence diagram
- **WHEN** a mermaid node defines participants and messages in `sequenceDiagram` syntax
- **THEN** the view SHALL render lifelines, ordered messages, and notes

#### Scenario: Render a pie chart
- **WHEN** a mermaid node defines a `pie` chart with labeled values
- **THEN** the view SHALL render proportional wedges and a legend with percentages

#### Scenario: Render an ER diagram
- **WHEN** a mermaid node defines entities and relationships in `erDiagram` syntax
- **THEN** the view SHALL render entity boxes connected with crow's-foot cardinality notation

### Requirement: Diagram shapes, edges, and grouping
Flowchart-family rendering SHALL support multiple node shapes (rectangle, rounded,
stadium, circle, diamond, hexagon, parallelogram, trapezoid, subroutine), edge variants
(solid, dashed, thick, with arrowheads and labels), subgraph grouping, and self-loops.

#### Scenario: Render a decision diamond with labeled edges
- **WHEN** a flowchart contains a diamond node with two labeled outgoing edges
- **THEN** the view SHALL render the diamond shape and both edges with their labels

#### Scenario: Render a subgraph
- **WHEN** a flowchart defines a `subgraph` with a title
- **THEN** the contained nodes SHALL be visually grouped within a titled bordered region

### Requirement: Diagram styling and theming
Mermaid rendering SHALL honor inline style directives (fill, stroke, and text colors in
`#RGB`, `#RRGGBB`, or CSS named-color form) and SHALL fall back to the active theme's
palette when no explicit style is given, adapting to light/dark mode.

#### Scenario: Apply an inline fill color
- **WHEN** a node declares a style with `fill:#ff0000`
- **THEN** that node SHALL render with a red fill

#### Scenario: Theme fallback
- **WHEN** a node has no explicit style
- **THEN** it SHALL render using the theme's surface, accent, and text colors for the current appearance

### Requirement: Unrecognized diagram fallback
When a Mermaid diagram type or syntax is not supported, the system SHALL fall back to
rendering the diagram source as a highlighted code block rather than failing.

#### Scenario: Unsupported diagram type
- **WHEN** a mermaid node uses a diagram type the engine does not implement
- **THEN** the view SHALL display the verbatim source as a code block labeled `mermaid`

### Requirement: Diagram sizing and overflow
Diagrams SHALL fit within the available width when possible and SHALL become scrollable
or zoomable when their intrinsic size exceeds the viewport. The presentation of an
oversized diagram SHALL be selectable via `MarkdownConfiguration.diagramSizing`
(`.scroll`, the default, or `.fitToWidth`).

#### Scenario: Oversized diagram scrolls
- **WHEN** a rendered diagram is wider than the available width and `diagramSizing` is `.scroll`
- **THEN** the diagram SHALL be horizontally scrollable within its own container

#### Scenario: Oversized diagram scales to fit
- **WHEN** a rendered diagram is wider than the available width and `diagramSizing` is `.fitToWidth`
- **THEN** the diagram SHALL be uniformly scaled down (never up) so the whole diagram is visible

