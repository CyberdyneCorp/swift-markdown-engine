import XCTest
@testable import SwiftMarkdownEngine

final class MermaidTests: XCTestCase {
    func testDiagramTypeDetection() {
        XCTAssertEqual(MermaidDiagramType.detect(from: "flowchart LR\nA-->B"), .flowchart)
        XCTAssertEqual(MermaidDiagramType.detect(from: "graph TD\nA-->B"), .flowchart)
        XCTAssertEqual(MermaidDiagramType.detect(from: "sequenceDiagram\nA->>B: hi"), .sequence)
        XCTAssertEqual(MermaidDiagramType.detect(from: "pie\n\"A\" : 1"), .pie)
        XCTAssertEqual(MermaidDiagramType.detect(from: "erDiagram\n"), .erDiagram)
        XCTAssertEqual(MermaidDiagramType.detect(from: "mindmap\nroot"), .mindmap)
        XCTAssertEqual(MermaidDiagramType.detect(from: "%% comment\ngantt"), .gantt)
        XCTAssertEqual(MermaidDiagramType.detect(from: "somethingElse"), .unknown)
    }

    func testFlowchartParsesNodesAndEdges() {
        let chart = FlowchartParser.parse("flowchart LR\nA[Start] --> B{OK?}\nB -->|yes| C(Done)")
        XCTAssertEqual(chart.direction, .leftToRight)
        XCTAssertEqual(chart.nodes.count, 3)
        XCTAssertEqual(chart.edges.count, 2)
        XCTAssertEqual(chart.nodes.first { $0.id == "A" }?.label, "Start")
        XCTAssertEqual(chart.nodes.first { $0.id == "B" }?.shape, .diamond)
        XCTAssertEqual(chart.nodes.first { $0.id == "C" }?.shape, .rounded)
        XCTAssertEqual(chart.edges.last?.label, "yes")
        XCTAssertTrue(chart.edges.allSatisfy { $0.hasArrow })
    }

    func testFlowchartEdgeStyles() {
        let chart = FlowchartParser.parse("flowchart TD\nA -.-> B\nB ==> C")
        XCTAssertEqual(chart.edges.first?.style, .dashed)
        XCTAssertEqual(chart.edges.last?.style, .thick)
        XCTAssertEqual(chart.direction, .topToBottom)
    }

    func testFlowchartStyleDirective() {
        let chart = FlowchartParser.parse("flowchart TD\nA[Red]\nstyle A fill:#ff0000,stroke:#000")
        XCTAssertEqual(chart.nodes.first?.fill, "#ff0000")
        XCTAssertEqual(chart.nodes.first?.stroke, "#000")
    }

    func testFlowchartLayoutAssignsDistinctFrames() {
        let chart = FlowchartParser.parse("flowchart TD\nA-->B-->C")
        let layout = FlowchartLayout(chart)
        XCTAssertEqual(layout.frames.count, 3)
        // In top-to-bottom layout, C should be below A.
        XCTAssertGreaterThan(layout.frames["C"]!.minY, layout.frames["A"]!.minY)
    }

    func testPieParse() {
        let pie = PieChartParser.parse("pie title Pets\n\"Dogs\" : 60\n\"Cats\" : 40")
        XCTAssertEqual(pie.title, "Pets")
        XCTAssertEqual(pie.slices.count, 2)
        XCTAssertEqual(pie.total, 100)
        XCTAssertEqual(pie.slices.first?.label, "Dogs")
        XCTAssertEqual(pie.slices.first?.value, 60)
    }

    func testSequenceParse() {
        let seq = SequenceParser.parse("sequenceDiagram\nparticipant A\nA->>B: Hello\nB-->>A: Hi")
        XCTAssertEqual(seq.participants, ["A", "B"])
        XCTAssertEqual(seq.messages.count, 2)
        XCTAssertEqual(seq.messages.first?.text, "Hello")
        XCTAssertFalse(seq.messages.first!.dashed)
        XCTAssertTrue(seq.messages.last!.dashed)
    }

    func testMermaidColorParsing() {
        XCTAssertNotNil(MermaidColor.parse("#ff0000"))
        XCTAssertNotNil(MermaidColor.parse("#f00"))
        XCTAssertNotNil(MermaidColor.parse("red"))
        XCTAssertNil(MermaidColor.parse("notacolor"))
    }

    func testMermaidNodeBecomesDiagramFromParser() {
        // End-to-end: a mermaid fence is detected as a mermaid block.
        guard case .mermaid(let src)? = MarkdownParser().parse("```mermaid\npie\n\"A\": 1\n```").blocks.first?.kind else {
            return XCTFail("not mermaid block")
        }
        XCTAssertEqual(MermaidDiagramType.detect(from: src), .pie)
    }
}

extension MermaidTests {
    func testStateDiagramParse() {
        let chart = StateDiagramParser.parse("stateDiagram-v2\n[*] --> Still\nStill --> Moving: go\nMoving --> [*]")
        // Two [*] markers + Still + Moving = 4 nodes.
        XCTAssertEqual(chart.nodes.count, 4)
        XCTAssertEqual(chart.edges.count, 3)
        XCTAssertEqual(chart.edges.first { $0.label == "go" }?.label, "go")
    }

    func testClassDiagramParse() {
        let model = ClassDiagramParser.parse("classDiagram\nclass Animal\nAnimal : +int age\nAnimal <|-- Dog")
        XCTAssertTrue(model.classes.contains { $0.name == "Animal" })
        XCTAssertTrue(model.classes.contains { $0.name == "Dog" })
        XCTAssertEqual(model.classes.first { $0.name == "Animal" }?.members, ["+int age"])
        XCTAssertEqual(model.relations.first?.inheritance, true)
    }

    func testERDiagramParse() {
        let model = ERDiagramParser.parse("erDiagram\nCUSTOMER ||--o{ ORDER : places")
        XCTAssertEqual(model.entities.sorted(), ["CUSTOMER", "ORDER"])
        XCTAssertEqual(model.relations.first?.label, "places")
        XCTAssertEqual(model.relations.first?.left, "CUSTOMER")
        XCTAssertEqual(model.relations.first?.right, "ORDER")
    }

    func testMindmapParse() {
        let model = MindmapParser.parse("mindmap\n  root((Root))\n    A\n    B\n      B1")
        XCTAssertEqual(model.nodes.first?.label, "Root")
        // Root has two children A and B.
        XCTAssertEqual(model.nodes.first?.children.count, 2)
        // B (index 2) has one child B1.
        XCTAssertTrue(model.nodes.contains { $0.label == "B1" && $0.depth == 2 })
    }
}
