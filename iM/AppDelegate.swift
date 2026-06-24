//
//  AppDelegate.swift
//  iM — QuickLook preview shell
//

import Cocoa

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private static let quickLookBundleID = "net.daringfireball.im.quicklook"
    private static let registeredAppVersionKey = "registeredQuickLookVersion"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        registerQuickLookIfNeeded()
        // 注册完成后退出 — 真正干活的是 QuickLook 扩展
        DispatchQueue.main.async { NSApp.terminate(nil) }
    }

    /// 首次启动（或升级后）自动注册 QuickLook 扩展，避免手动操作。
    private func registerQuickLookIfNeeded() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let registeredVersion = UserDefaults.standard.string(forKey: Self.registeredAppVersionKey)

        guard registeredVersion != currentVersion else { return }
        guard Bundle.main.bundleURL.path.hasPrefix("/Applications/") else { return }
        guard let extPath = Bundle.main.builtInPlugInsPath?.appending("/quick-look.appex") else { return }

        let isRegistered = runAndCapture("/usr/bin/pluginkit", ["-m", "-i", Self.quickLookBundleID])
            .contains(Self.quickLookBundleID)

        LSRegisterURL(Bundle.main.bundleURL as CFURL, true)

        if !isRegistered {
            run("/usr/bin/pluginkit", ["-a", extPath])
            run("/usr/bin/pluginkit", ["-e", "use", "-p", "com.apple.quicklook.preview",
                                       "-i", Self.quickLookBundleID])
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
}
