import Foundation

/// A lightweight Markdown preprocessor that strips and parses
/// YAML / TOML frontmatter from raw text.
struct Frontmatter {
    enum Format: String {
        case yaml
        case toml
    }

    struct Result {
        let raw: String?
        let format: Format?
        let body: String
    }

    static func split(_ text: String) -> Result {
        let lines = text.components(separatedBy: .newlines)

        guard let first = lines.first,
              let closer = Delimiter.closer(for: first),
              let endIndex = lines.dropFirst().firstIndex(of: closer) else {
            return Result(raw: nil, format: nil, body: text)
        }

        let format: Format = first.hasPrefix("+++") ? .toml : .yaml
        let raw = lines[1..<endIndex].joined(separator: "\n")
        let body = lines.suffix(from: endIndex + 1).joined(separator: "\n")

        return Result(raw: raw, format: format, body: body)
    }
}

// Usage
let markdown = """
---
title: Hello World
---
# Content here
"""

let result = Frontmatter.split(markdown)
print("Format:", result.format ?? "none")
print("Title:", result.raw ?? "nil")
