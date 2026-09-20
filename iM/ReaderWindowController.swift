//
//  ReaderWindowController.swift
//  iM
//

import AppKit
import WebKit

/// Read-only document window: a single WKWebView rendering the shared
/// FileContentRenderer pipeline. External file changes are pushed into the
/// page via `window.iM.update(...)` — no page reload, scroll position kept.
@MainActor
final class ReaderWindowController: NSWindowController {

    private let schemeHandler = AssetSchemeHandler()
    private let hostMessageHandler = HostMessageHandler()
    private let webView: WKWebView
    private var fileWatcher: FileWatcher?

    private var didFinishFirstLoad = false
    private var pendingRendered: PreviewHTML.RenderedHTML?
    private var renderedFlags = (math: false, mermaid: false, code: false)

    private var documentURL: URL? {
        readerDocument?.fileURL
    }

    private var readerDocument: ReaderDocument? {
        document as? ReaderDocument
    }

    init(document: ReaderDocument) {
        let config = WKWebViewConfiguration()
        let userContent = WKUserContentController()
        userContent.add(hostMessageHandler, name: "mdPreviewHost")
        config.userContentController = userContent
        config.setURLSchemeHandler(schemeHandler,
                                   forURLScheme: AssetSchemeHandler.scheme)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.wantsLayer = true            // macOS 15: black screen without it
        webView.autoresizingMask = [.width, .height]
        self.webView = webView

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "iM"
        window.isRestorable = false
        super.init(window: window)

        hostMessageHandler.owner = self
        window.delegate = self
        window.contentView = webView
        webView.navigationDelegate = self
        centerOnMainScreen(window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func centerOnMainScreen(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let frame = window.frame
        let visible = screen.visibleFrame
        window.setFrameOrigin(NSPoint(x: visible.midX - frame.width / 2,
                                      y: visible.midY - frame.height / 2))
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        guard fileWatcher == nil, let url = documentURL else { return }

        window?.title = url.lastPathComponent
        window?.representedURL = url
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
        NSApp.activate()

        fileWatcher = FileWatcher(url: url) { [weak self] in
            self?.refreshFromDisk()
        }
        loadInitial()
    }

    // MARK: - Rendering

    private func loadInitial() {
        guard let url = documentURL else { return }
        let text = readerDocument?.currentText ?? ""
        let ext = url.pathExtension.lowercased()
        schemeHandler.setBaseURL(url.deletingLastPathComponent())

        Task.detached(priority: .userInitiated) { [weak self] in
            let rendered = FileContentRenderer.render(
                text: text,
                pathExtension: ext,
                assetBaseHref: "md-asset:///"
            )
            await MainActor.run { self?.loadFullPage(rendered) }
        }
    }

    private func refreshFromDisk() {
        guard let url = documentURL else { return }
        let ext = url.pathExtension.lowercased()

        Task.detached(priority: .userInitiated) { [weak self] in
            // Read failure (file deleted mid-save) keeps the last content.
            guard let text = try? FileContentRenderer.text(of: url) else { return }
            let rendered = FileContentRenderer.render(
                text: text,
                pathExtension: ext,
                assetBaseHref: "md-asset:///"
            )
            await MainActor.run { self?.apply(rendered) }
        }
    }

    private func loadFullPage(_ rendered: PreviewHTML.RenderedHTML) {
        didFinishFirstLoad = false
        renderedFlags = (rendered.containsMath, rendered.containsMermaid, rendered.containsCode)
        webView.loadHTMLString(rendered.html, baseURL: nil)
    }

    private func apply(_ rendered: PreviewHTML.RenderedHTML) {
        guard didFinishFirstLoad else {
            pendingRendered = rendered
            return
        }
        // A freshly introduced math/mermaid/code block needs its vendor
        // <script> in <head>, which only a full page render contains.
        let gainedVendor = (!renderedFlags.math && rendered.containsMath)
            || (!renderedFlags.mermaid && rendered.containsMermaid)
            || (!renderedFlags.code && rendered.containsCode)
        if gainedVendor {
            loadFullPage(rendered)
            return
        }
        updateIncrementally(rendered)
    }

    private func updateIncrementally(_ rendered: PreviewHTML.RenderedHTML) {
        guard let array = try? JSONSerialization.data(
            withJSONObject: [rendered.articleHTML]
        ), let json = String(data: array, encoding: .utf8) else { return }

        let script = """
        (function() {
            var y = window.scrollY || 0;
            window.iM.update(\(json)[0]);
            requestAnimationFrame(function() {
                var max = document.documentElement.scrollHeight - window.innerHeight;
                window.scrollTo(0, Math.max(0, Math.min(y, max)));
            });
        })();
        """
        webView.evaluateJavaScript(script)
    }

    // MARK: - Host bridge

    fileprivate func handleHostMessage(_ body: Any) {
        guard let message = body as? [String: Any],
              let kind = message["kind"] as? String else { return }
        switch kind {
        case "copyCode":
            guard let code = message["value"] as? String else { return }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(code, forType: .string)
        case "scroll":
            guard let direction = message["value"] as? String else { return }
            scroll(direction)
        default:
            break   // height reports etc. are unused in window mode
        }
    }

    private func scroll(_ direction: String) {
        let distance: String
        switch direction {
        case "pageDown": distance = "Math.floor(window.innerHeight * 0.9)"
        case "pageUp":   distance = "-Math.floor(window.innerHeight * 0.9)"
        case "lineDown": distance = "Math.max(20, Math.round(parseFloat(getComputedStyle(document.body).lineHeight) || 24))"
        case "lineUp":   distance = "-Math.max(20, Math.round(parseFloat(getComputedStyle(document.body).lineHeight) || 24))"
        default: return
        }
        webView.evaluateJavaScript("window.scrollBy(0, \(distance));")
    }
}

// MARK: - WKNavigationDelegate

extension ReaderWindowController: WKNavigationDelegate {

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
        guard navigationAction.navigationType == .linkActivated,
              let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        if ["http", "https", "mailto"].contains(url.scheme) {
            NSWorkspace.shared.open(url)
        }
        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        didFinishFirstLoad = true
        if let pending = pendingRendered {
            pendingRendered = nil
            apply(pending)
        }
    }
}

// MARK: - NSWindowDelegate

extension ReaderWindowController: NSWindowDelegate {

    func windowWillClose(_ notification: Notification) {
        fileWatcher?.cancel()
        fileWatcher = nil
        webView.configuration.userContentController
            .removeScriptMessageHandler(forName: "mdPreviewHost")
    }
}

// MARK: - Weak message-handler proxy (avoids UCC -> controller retain cycle)

private final class HostMessageHandler: NSObject, WKScriptMessageHandler {

    weak var owner: ReaderWindowController?

    nonisolated func userContentController(_ userContentController: WKUserContentController,
                                           didReceive message: WKScriptMessage) {
        MainActor.assumeIsolated {
            owner?.handleHostMessage(message.body)
        }
    }
}
