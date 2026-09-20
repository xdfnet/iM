//
//  FileContentRenderer.swift
//  iM
//

import Foundation

/// Routes any supported file to the single Markdown render pipeline:
/// code/config files are wrapped in a fenced code block first, so the
/// Quick Look extension and the reader window always render identically.
nonisolated enum FileContentRenderer {

    /// JSON files larger than this are truncated byte-safely with a notice.
    static let jsonByteLimit = 2 * 1024 * 1024

    /// Extensions opened natively as Markdown (everything else unknown is
    /// treated as Markdown too, matching Quick Look's default branch).
    static let markdownExtensions: Set<String> = [
        "md", "markdown", "mdown", "mkd", "mkdn", "mdwn", "mdtxt", "mdtext"
    ]

    /// Extension -> highlight.js language for fenced wrapping.
    private static let languageByExtension: [String: String] = [
        "yaml": "yaml", "yml": "yaml",
        "toml": "toml",
        "sh": "bash", "bash": "bash", "zsh": "bash",
        "swift": "swift",
        "py": "python",
        "xml": "xml", "plist": "xml",
        "js": "javascript",
        "css": "css",
        "c": "c", "h": "c",
        "cpp": "cpp", "cc": "cpp", "cxx": "cpp", "hpp": "cpp",
        "html": "html", "htm": "html",
        "ini": "ini", "cfg": "ini", "conf": "ini",
        "m": "objectivec",
        "php": "php",
        "pl": "perl", "pm": "perl",
        "rb": "ruby", "rbw": "ruby",
        "ts": "typescript", "tsx": "typescript",
        "rs": "rust",
        "go": "go",
        "kt": "kotlin", "kts": "kotlin",
        "sql": "sql",
        "scss": "scss",
        "graphql": "graphql", "gql": "graphql",
        "lua": "lua",
        "r": "r",
        "diff": "diff", "patch": "diff"
    ]

    /// Every type the app declares in its Info.plist document bindings.
    static let supportedExtensions: Set<String> =
        markdownExtensions.union(languageByExtension.keys).union(["json"])

    /// Reads a user-selected file as UTF-8, handling security-scoped URLs.
    static func text(of url: URL) throws -> String {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        guard let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return text
    }

    static func render(text: String,
                       pathExtension ext: String,
                       allowsScroll: Bool = true,
                       assetBaseHref: String? = nil,
                       vendorLoading: PreviewHTML.VendorLoading = .lazy) -> PreviewHTML.RenderedHTML {
        let markdown = markdownBody(text: text, pathExtension: ext)
        return PreviewHTML.render(markdown: markdown,
                                  allowsScroll: allowsScroll,
                                  assetBaseHref: assetBaseHref,
                                  vendorLoading: vendorLoading)
    }

    /// Wraps/transforms raw file text into the Markdown fed to the pipeline.
    static func markdownBody(text: String, pathExtension ext: String) -> String {
        if ext == "json" {
            return truncatedJSONBody(text)
        }
        guard let language = languageByExtension[ext] else {
            // Markdown variants, empty extension, and unknown types:
            // render as Markdown.
            return text
        }
        return "```\(language)\n\(text)\n```"
    }

    /// Wraps JSON in a code fence, truncating byte-safely past the limit.
    /// `String.prefix()` counts characters while the limit counts UTF-8
    /// bytes, so truncation accumulates per character instead.
    static func truncatedJSONBody(_ text: String, maxBytes: Int = jsonByteLimit) -> String {
        guard text.utf8.count > maxBytes else {
            return "```json\n\(text)\n```"
        }
        let byteLimit = maxBytes - 200
        var truncated = ""
        var byteCount = 0
        for char in text {
            let charBytes = char.utf8.count
            guard byteCount + charBytes <= byteLimit else { break }
            truncated.append(char)
            byteCount += charBytes
        }
        return """
        ```json
        \(truncated)
        ```

        > 📦 File truncated (> \(maxBytes / 1024 / 1024) MB). Full content requires a text editor.
        """
    }
}
