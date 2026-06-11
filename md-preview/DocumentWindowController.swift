//
//  DocumentWindowController.swift
//  md-preview
//

import Cocoa

final class DocumentWindowController: NSWindowController, NSWindowDelegate {

    private var currentFileURL: URL?
    private var currentMarkdown: String?

    private var documentWindow: NSWindow {
        guard let window else {
            fatalError("DocumentWindowController accessed before its window was loaded")
        }
        return window
    }

    private var markdownDocument: MarkdownDocument? {
        document as? MarkdownDocument
    }

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "iMarkdown"
        window.animationBehavior = .default
        super.init(window: window)
        setupWindow()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupWindow() {
        documentWindow.styleMask.insert(.fullSizeContentView)
        documentWindow.delegate = self
        documentWindow.contentViewController = MainSplitViewController()
        documentWindow.setContentSize(NSSize(width: 900, height: 680))
        if let screen = NSScreen.main {
            let rect = documentWindow.frame
            let x = (screen.visibleFrame.width - rect.width) / 2 + screen.visibleFrame.origin.x
            let y = (screen.visibleFrame.height - rect.height) / 2 + screen.visibleFrame.origin.y
            documentWindow.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    func windowWillClose(_ notification: Notification) {
        currentFileURL = nil
        currentMarkdown = nil
    }

    func display(markdown: String, fileURL: URL?) {
        currentFileURL = fileURL
        currentMarkdown = markdown
        documentWindow.title = fileURL?.lastPathComponent ?? "iMarkdown"
        documentWindow.makeKeyAndOrderFront(nil)
        NSApp.activate()

        guard let fileURL else { return }
        NSDocumentController.shared.noteNewRecentDocumentURL(fileURL)
        renderCurrentDocument(text: markdown, fileURL: fileURL)
    }

    private func renderCurrentDocument(text: String, fileURL: URL) {
        (documentWindow.contentViewController as? MainSplitViewController)?
            .display(
                markdown: text,
                fileName: fileURL.lastPathComponent,
                url: fileURL,
                assetBaseURL: fileURL.deletingLastPathComponent()
            )
    }

    private func loadFile(at url: URL, silentOnFailure: Bool = false) {
        do {
            let data = try Data(contentsOf: url)
            guard let markdown = String(data: data, encoding: .utf8) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            currentMarkdown = markdown
            markdownDocument?.replaceContents(markdown: markdown, fileURL: url)
            renderCurrentDocument(text: markdown, fileURL: url)
        } catch {
            if !silentOnFailure {
                NSAlert(error: error).runModal()
            }
        }
    }

}
