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

        // The lazy renderer points vendor <script src> at
        // `md-asset:///__vendor/...`; register the handler so WKWebView can
        // load KaTeX/Mermaid/Highlight out of the extension's own Resources.
        // Without it Space-preview shows the raw formulas/diagrams.
        let schemeHandler = AssetSchemeHandler()
        schemeHandler.setBaseURL(url.deletingLastPathComponent())
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(schemeHandler, forURLScheme: AssetSchemeHandler.scheme)

        let webView = WKWebView(frame: view.bounds, configuration: config)
        webView.wantsLayer = true            // macOS 15: black screen without it
        webView.autoresizingMask = [.width, .height]
        webView.loadHTMLString(rendered.html, baseURL: url.deletingLastPathComponent())
        view.addSubview(webView)
    }
}
