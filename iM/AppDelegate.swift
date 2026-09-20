//
//  AppDelegate.swift
//  iM — QuickLook shell + read-only document viewer
//

import Cocoa

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private static let quickLookBundleID = "net.daringfireball.im.quicklook"
    private static let registeredAppVersionKey = "registeredQuickLookVersion"

    /// File-open Apple Events arrive after didFinishLaunching, so the
    /// no-file exit decision waits briefly for them.
    private var launchDecision: DispatchWorkItem?
    private var didReceiveOpenEvent = false

    /// Code-only app (no nib): the synthesized `@main` entry would call
    /// `NSApplicationMain` without ever creating a delegate, so wire it up
    /// explicitly. The local stays alive for the lifetime of `run()`.
    static func main() {
        let application = NSApplication.shared
        let delegate = Self()
        application.delegate = delegate
        application.run()
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        installMainMenu()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        registerQuickLookIfNeeded()
        scheduleLaunchExitDecision()
    }

    /// Launched with no document (the QuickLook-registration case): exit once
    /// the window-only app has done its registration. Launches with files
    /// cancel this in `application(_:open:)`.
    private func scheduleLaunchExitDecision() {
        guard !didReceiveOpenEvent else { return }
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                guard let self, !self.didReceiveOpenEvent,
                      NSDocumentController.shared.documents.isEmpty else { return }
                NSApp.terminate(nil)
            }
        }
        launchDecision = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        let fileURLs = urls.filter { url in
            var isDirectory: ObjCBool = false
            return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
                && !isDirectory.boolValue
        }
        // An empty event (plain app launch) must not cancel the no-file exit.
        guard !fileURLs.isEmpty else { return }
        didReceiveOpenEvent = true
        launchDecision?.cancel()
        launchDecision = nil

        for url in fileURLs {
            // Reopening a file that already has a window just brings it forward.
            if let document = NSDocumentController.shared.documents
                .first(where: { $0.fileURL?.path == url.path }) {
                document.windowControllers.first?.showWindow(self)
                NSApp.activate()
                continue
            }
            NSDocumentController.shared.openDocument(withContentsOf: url,
                                                     display: true) { _, _, error in
                MainActor.assumeIsolated {
                    guard let error else { return }
                    NSApp.activate()
                    NSAlert(error: error).runModal()
                    if NSDocumentController.shared.documents.isEmpty {
                        NSApp.terminate(nil)
                    }
                }
            }
        }
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { false }
    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool { false }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        flag
    }

    /// Window-only app: once every reader window closes, quit — no background
    /// process lingers after a QuickLook-only registration launch either.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    // MARK: - Main menu (code-only, no nib)

    private func installMainMenu() {
        let mainMenu = NSMenu()
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "iM"

        // App
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About \(appName)",
                        action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                        keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide \(appName)",
                        action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = appMenu.addItem(withTitle: "Hide Others",
                                         action: #selector(NSApplication.hideOtherApplications(_:)),
                                         keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: "Show All",
                        action: #selector(NSApplication.unhideAllApplications(_:)),
                        keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit \(appName)",
                        action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu

        // File — ⌘O routes to NSDocumentController, whose open panel is
        // populated automatically from the Info.plist document bindings.
        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "Open…",
                         action: #selector(NSDocumentController.openDocument(_:)),
                         keyEquivalent: "o")
        let recentMenuItem = NSMenuItem(title: "Open Recent", action: nil, keyEquivalent: "")
        recentMenuItem.submenu = NSMenu(title: "Open Recent")
        fileMenu.addItem(recentMenuItem)
        fileMenu.addItem(.separator())
        fileMenu.addItem(withTitle: "Close",
                         action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenuItem.submenu = fileMenu
        // The document controller owns and auto-fills the recent-documents menu.
        if NSDocumentController.shared.responds(to: Selector(("setRecentDocumentsMenu:"))) {
            NSDocumentController.shared.setValue(recentMenuItem.submenu,
                                                  forKey: "recentDocumentsMenu")
        }

        // Edit — just enough for text selection inside the WKWebView.
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Copy",
                         action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Select All",
                         action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu

        // View
        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)
        let viewMenu = NSMenu(title: "View")
        let fullScreen = viewMenu.addItem(withTitle: "Enter Full Screen",
                                          action: #selector(NSWindow.toggleFullScreen(_:)),
                                          keyEquivalent: "f")
        fullScreen.keyEquivalentModifierMask = [.control, .command]
        viewMenuItem.submenu = viewMenu

        // Window
        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize",
                           action: #selector(NSWindow.performMiniaturize(_:)),
                           keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom",
                           action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
        windowMenu.addItem(.separator())
        windowMenu.addItem(withTitle: "Bring All to Front",
                           action: #selector(NSApplication.arrangeInFront(_:)),
                           keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        NSApp.windowsMenu = windowMenu

        NSApp.mainMenu = mainMenu
    }

    /// 首次启动（或升级后）自动注册 QuickLook 扩展，避免手动操作。
    private func registerQuickLookIfNeeded() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let registeredVersion = UserDefaults.standard.string(forKey: Self.registeredAppVersionKey)

        guard registeredVersion != currentVersion else { return }
        guard Bundle.main.bundleURL.path.hasPrefix("/Applications/") else { return }
        guard let extPath = Bundle.main.builtInPlugInsPath?.appending("/quick-look.appex") else { return }

        // Concurrent dispatch: probe registration first (needs stdout to detect
        // the existing entry), then fire the two mutating `pluginkit` calls in
        // parallel. Skips `qlmanage -r` — that resets the system-wide QL cache
        // on every upgrade, which is unnecessary; QL discovers newly-registered
        // extensions lazily.
        let isRegistered = Self.runAndCapture("/usr/bin/pluginkit", ["-m", "-i", Self.quickLookBundleID])
            .contains(Self.quickLookBundleID)

        LSRegisterURL(Bundle.main.bundleURL as CFURL, true)

        if !isRegistered {
            let group = DispatchGroup()
            let queue = DispatchQueue(label: "net.daringfireball.imarkdown.ql-register",
                                      qos: .userInitiated)
            for args in [
                ["-a", extPath],
                ["-e", "use", "-p", "com.apple.quicklook.preview", "-i", Self.quickLookBundleID],
            ] {
                group.enter()
                queue.async {
                    _ = Self.run("/usr/bin/pluginkit", args)
                    group.leave()
                }
            }
            group.wait()
        }

        UserDefaults.standard.set(currentVersion, forKey: Self.registeredAppVersionKey)
    }

    // Nonisolated so the concurrent registration queue can call them without
    // crossing the @MainActor boundary. They don't touch any shared state.
    @discardableResult
    nonisolated private static func run(_ path: String, _ args: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        try? process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }

    nonisolated private static func runAndCapture(_ path: String, _ args: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
