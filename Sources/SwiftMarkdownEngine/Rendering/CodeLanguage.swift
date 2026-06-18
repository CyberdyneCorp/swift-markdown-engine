/// Maps common fenced-code language aliases to canonical language identifiers
/// before they are handed to a `SyntaxHighlighter`.
public enum CodeLanguage {
    private static let aliases: [String: String] = [
        "py": "python", "py3": "python",
        "js": "javascript", "node": "javascript",
        "ts": "typescript",
        "rb": "ruby",
        "sh": "bash", "shell": "bash", "zsh": "bash",
        "c++": "cpp", "cxx": "cpp", "h": "cpp",
        "cs": "csharp",
        "objc": "objectivec",
        "kt": "kotlin",
        "rs": "rust",
        "yml": "yaml",
        "md": "markdown",
        "dockerfile": "docker",
        "sv": "verilog",
    ]

    /// Returns the canonical language for an info-string label, lowercased and
    /// alias-resolved. Returns `nil` for an empty/absent label.
    public static func canonical(_ label: String?) -> String? {
        guard let raw = label?.lowercased(), !raw.isEmpty else { return nil }
        return aliases[raw] ?? raw
    }
}
