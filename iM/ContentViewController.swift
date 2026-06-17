import Cocoa
import WebKit

@MainActor
final class ContentViewController: NSViewController, WKNavigationDelegate {

    private let webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(ContentViewController.disableContextMenu)
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.wantsLayer = true
        return wv
    }()

    override func loadView() {
        webView.navigationDelegate = self
        view = webView
    }

    func display(markdown: String, assetBaseURL: URL? = nil) {
        let html = MarkdownHTML.makeHTML(from: markdown, allowsScroll: true)
        webView.loadHTMLString(html, baseURL: nil)
    }

    func clearContent() {
        webView.loadHTMLString("", baseURL: nil)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    private static let disableContextMenu: WKUserScript = {
        WKUserScript(source: """
        document.addEventListener('contextmenu', event => {
            const sel = window.getSelection();
            if (sel && sel.toString().trim().length > 0) return;
            event.preventDefault();
        }, true);
        """, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }()
}
