//
//  AppDelegate.swift
//  iM
//

import Cocoa
import UniformTypeIdentifiers

@main
final class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet private weak var checkForUpdatesMenuItem: NSMenuItem?

    private static let markdownFileExtensions = [
        "md", "markdown", "mdown", "mdwn", "mkd", "mkdn", "mdtxt", "mdtext"
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        checkForUpdatesMenuItem?.isHidden = true
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        flag
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where !url.isExistingDirectory {
            NSDocumentController.shared.openDocument(withContentsOf: url,
                                                     display: true) { _, _, error in
                guard let error else { return }
                NSAlert(error: error).runModal()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    @IBAction func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.message = "Choose a Markdown file"
        panel.allowedContentTypes = Self.markdownFileExtensions
            .compactMap { UTType(filenameExtension: $0) }

        guard panel.runModal() == .OK, let url = panel.url else { return }
        NSDocumentController.shared.openDocument(withContentsOf: url,
                                                 display: true) { _, _, error in
            guard let error else { return }
            NSAlert(error: error).runModal()
        }
    }

    @IBAction func checkForUpdates(_ sender: Any?) {}

    @IBAction func performFindPanelAction(_ sender: Any?) {}

    @IBAction func performTextFinderAction(_ sender: Any?) {}
}
