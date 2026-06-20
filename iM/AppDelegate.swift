//
//  AppDelegate.swift
//  iM
//

import Cocoa
import UniformTypeIdentifiers

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet private weak var checkForUpdatesMenuItem: NSMenuItem?

    private static let markdownFileExtensions = [
        "md", "markdown", "mdown", "mdwn", "mkd", "mkdn", "mdtxt", "mdtext"
    ]

    private static let quickLookBundleID = "net.daringfireball.im.quicklook"
    private static let registeredAppVersionKey = "registeredQuickLookVersion"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        checkForUpdatesMenuItem?.isHidden = true
        registerQuickLookIfNeeded()
    }

    /// 首次启动（或升级后）自动注册 QuickLook 扩展，避免手动操作。
    private func registerQuickLookIfNeeded() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let registeredVersion = UserDefaults.standard.string(forKey: Self.registeredAppVersionKey)

        // 已注册过同版本的扩展，跳过
        guard registeredVersion != currentVersion else { return }
        // 只在安装到 /Applications 时注册，Xcode 内调试不触发
        guard Bundle.main.bundleURL.path.hasPrefix("/Applications/") else { return }

        guard let extPath = Bundle.main.builtInPlugInsPath?.appending("/quick-look.appex") else { return }

        // 1. 先检查 QuickLook 扩展是否已注册，避免重复
        let isRegistered = runAndCapture("/usr/bin/pluginkit", ["-m", "-i", Self.quickLookBundleID])
            .contains(Self.quickLookBundleID)

        // 2. 注册主应用到 LaunchServices
        LSRegisterURL(Bundle.main.bundleURL as CFURL, true)

        // 3. 注册 QuickLook 扩展
        if !isRegistered {
            run("/usr/bin/pluginkit", ["-a", extPath])
            run("/usr/bin/pluginkit", ["-e", "use", "-p", "com.apple.quicklook.preview",
                                       "-i", Self.quickLookBundleID])
            // 刷新 QuickLook 服务器
            run("/usr/bin/qlmanage", ["-r"])
        }

        UserDefaults.standard.set(currentVersion, forKey: Self.registeredAppVersionKey)
    }

    @discardableResult
    private func run(_ path: String, _ args: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        try? process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }

    /// 执行命令并返回 stdout 输出
    private func runAndCapture(_ path: String, _ args: [String]) -> String {
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
