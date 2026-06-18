import Foundation

/// The Mermaid diagram types the engine recognizes. Types without a native renderer
/// fall back to showing the source.
enum MermaidDiagramType: Equatable {
    case flowchart
    case sequence
    case pie
    case classDiagram
    case stateDiagram
    case erDiagram
    case gantt
    case gitGraph
    case journey
    case mindmap
    case timeline
    case unknown

    /// Detects the diagram type from the first non-empty, non-comment line.
    static func detect(from source: String) -> MermaidDiagramType {
        guard let header = source
            .split(separator: "\n")
            .map({ $0.trimmingCharacters(in: .whitespaces) })
            .first(where: { !$0.isEmpty && !$0.hasPrefix("%%") })?
            .lowercased()
        else { return .unknown }

        if header.hasPrefix("flowchart") || header.hasPrefix("graph") { return .flowchart }
        if header.hasPrefix("sequencediagram") { return .sequence }
        if header.hasPrefix("pie") { return .pie }
        if header.hasPrefix("classdiagram") { return .classDiagram }
        if header.hasPrefix("statediagram") { return .stateDiagram }
        if header.hasPrefix("erdiagram") { return .erDiagram }
        if header.hasPrefix("gantt") { return .gantt }
        if header.hasPrefix("gitgraph") { return .gitGraph }
        if header.hasPrefix("journey") { return .journey }
        if header.hasPrefix("mindmap") { return .mindmap }
        if header.hasPrefix("timeline") { return .timeline }
        return .unknown
    }
}

/// Shared line-scanning helpers for Mermaid parsers.
enum MermaidLines {
    /// Returns content lines, dropping blanks, comments, and the header line.
    static func body(_ source: String, dropHeader: Bool = true) -> [String] {
        var lines = source
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("%%") }
        if dropHeader, !lines.isEmpty { lines.removeFirst() }
        return lines
    }
}
