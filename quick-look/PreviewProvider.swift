import Cocoa
import Quartz
import WebKit

class PreviewProvider: NSViewController, QLPreviewingController {

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 700))
    }

    func preparePreviewOfFile(at url: URL) async throws {
        let text = try String(contentsOf: url, encoding: .utf8)
        let html = MarkdownHTML.makeHTML(from: text, allowsScroll: true)

        let webView = WKWebView(frame: view.bounds)
        webView.autoresizingMask = [.width, .height]
        webView.loadHTMLString(html, baseURL: url.deletingLastPathComponent())
        view.addSubview(webView)
    }
}
