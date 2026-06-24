import Cocoa
import Quartz
import WebKit

class PreviewProvider: NSViewController, QLPreviewingController {

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 700))
    }

    func preparePreviewOfFile(at url: URL) async throws {
        let text = try String(contentsOf: url, encoding: .utf8)
        let ext = url.pathExtension.lowercased()

        // .lazy: keep KaTeX/Mermaid/Highlight out of the QLPreviewReply payload
        // (Mermaid alone is 3MB). DOMPurify stays inline — the bootstrap's
        // `sanitize()` fail-closed branch fires if it isn't ready by the time
        // `populateFromTemplate` runs.
        let html: String
        switch ext {
        case "md", "markdown", "mdown", "mkd", "mkdn", "mdwn", "mdtxt", "mdtext", "":
            html = PreviewHTML.makeHTML(from: text,
                                        allowsScroll: true,
                                        vendorLoading: .lazy)

        case "json":
            html = makeHTML(from: "json", text: text, maxBytes: 2 * 1024 * 1024)

        case "yaml", "yml":
            html = wrapAndRender(language: "yaml", code: text)

        case "toml":
            html = wrapAndRender(language: "toml", code: text)

        case "sh", "bash", "zsh":
            html = wrapAndRender(language: "bash", code: text)

        case "swift":
            html = wrapAndRender(language: "swift", code: text)

        case "py":
            html = wrapAndRender(language: "python", code: text)

        case "xml", "plist":
            html = wrapAndRender(language: "xml", code: text)

        case "js":
            html = wrapAndRender(language: "javascript", code: text)

        case "css":
            html = wrapAndRender(language: "css", code: text)

        default:
            html = PreviewHTML.makeHTML(from: text,
                                        allowsScroll: true,
                                        vendorLoading: .lazy)
        }

        let webView = WKWebView(frame: view.bounds)
        webView.autoresizingMask = [.width, .height]
        webView.loadHTMLString(html, baseURL: url.deletingLastPathComponent())
        view.addSubview(webView)
    }

    /// Wraps code in a markdown fenced code block and renders through
    /// the full Markdown pipeline — same visual experience as .md files.
    private func wrapAndRender(language: String, code: String) -> String {
        let wrapped = "```\(language)\n\(code)\n```"
        return PreviewHTML.makeHTML(from: wrapped,
                                    allowsScroll: true,
                                    vendorLoading: .lazy)
    }

    /// Like `wrapAndRender`, but truncates at byte limit with a markdown notice.
    private func makeHTML(from language: String, text: String, maxBytes: Int) -> String {
        if text.utf8.count > maxBytes {
            let byteLimit = maxBytes - 200
            var truncated = ""
            var byteCount = 0
            for char in text {
                let charBytes = char.utf8.count
                guard byteCount + charBytes <= byteLimit else { break }
                truncated.append(char)
                byteCount += charBytes
            }
            let wrapped = """
            ```\(language)
            \(truncated)
            ```

            > 📦 File truncated (> \(maxBytes / 1024 / 1024) MB). Full content requires a text editor.
            """
            return PreviewHTML.makeHTML(from: wrapped,
                                        allowsScroll: true,
                                        vendorLoading: .lazy)
        }
        return wrapAndRender(language: language, code: text)
    }
}
