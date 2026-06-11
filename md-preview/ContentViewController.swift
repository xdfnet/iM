import Cocoa
import WebKit

final class ContentViewController: NSViewController, WKNavigationDelegate {

    private var webView: WKWebView!

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(disableContextMenu)
        webView = WKWebView(frame: .zero, configuration: config)
        webView.wantsLayer = true
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

    private let disableContextMenu: WKUserScript = {
        WKUserScript(source: """
        document.addEventListener('contextmenu', event => {
            const sel = window.getSelection();
            if (sel && sel.toString().trim().length > 0) return;
            event.preventDefault();
        }, true);
        """, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }()
}
