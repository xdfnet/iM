import Cocoa
import Quartz
import WebKit

class PreviewProvider: NSViewController, QLPreviewingController {

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 700))
    }

    func preparePreviewOfFile(at url: URL) async throws {
        let text = try FileContentRenderer.text(of: url)

        // .lazy: keep KaTeX/Mermaid/Highlight out of the QLPreviewReply payload
        // (Mermaid alone is 3MB). DOMPurify stays inline — the bootstrap's
        // `sanitize()` fail-closed branch fires if it isn't ready by the time
        // `populateFromTemplate` runs.
        let rendered = FileContentRenderer.render(
            text: text,
            pathExtension: url.pathExtension.lowercased(),
            vendorLoading: .lazy
        )

        let webView = WKWebView(frame: view.bounds)
        webView.autoresizingMask = [.width, .height]
        webView.loadHTMLString(rendered.html, baseURL: url.deletingLastPathComponent())
        view.addSubview(webView)
    }
}
