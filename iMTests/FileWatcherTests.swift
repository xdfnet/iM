import XCTest

@MainActor
final class FileWatcherTests: XCTestCase {

    private var tempDirectory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("FileWatcherTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory,
                                                withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        try super.tearDownWithError()
    }

    /// Counter avoids "extra fulfillment" failures when a save emits
    /// several coalesced kernel events.
    private final class Counter: NSObject {
        @objc dynamic var count = 0
    }

    func testNotifiesOnSameInodeWrite() throws {
        let url = tempDirectory.appendingPathComponent("a.md")
        try "initial\n".write(to: url, atomically: true, encoding: .utf8)

        let counter = Counter()
        let watcher = FileWatcher(url: url) { counter.count += 1 }
        addTeardownBlock { watcher.cancel() }

        try "appended\n".write(to: url, atomically: false, encoding: .utf8)

        let fired = expectation(for: NSPredicate(format: "count >= 1"),
                                evaluatedWith: counter)
        wait(for: [fired], timeout: 3)
    }

    func testSurvivesAtomicRenameReplace() throws {
        let url = tempDirectory.appendingPathComponent("b.md")
        try "one\n".write(to: url, atomically: true, encoding: .utf8)

        let counter = Counter()
        let watcher = FileWatcher(url: url) { counter.count += 1 }
        addTeardownBlock { watcher.cancel() }

        // VS Code / TextEdit / vim style save: temp file renamed over original.
        let temp = tempDirectory.appendingPathComponent(".b.md.tmp")
        try "two-atomic\n".write(to: temp, atomically: true, encoding: .utf8)
        _ = try FileManager.default.replaceItemAt(url, withItemAt: temp)

        let replaced = expectation(for: NSPredicate(format: "count >= 1"),
                                   evaluatedWith: counter)
        wait(for: [replaced], timeout: 4)

        // A later ordinary write is still observed via the reopened descriptor.
        counter.count = 0
        try "three\n".write(to: url, atomically: false, encoding: .utf8)
        let observedAgain = expectation(for: NSPredicate(format: "count >= 1"),
                                        evaluatedWith: counter)
        wait(for: [observedAgain], timeout: 3)
    }
}
