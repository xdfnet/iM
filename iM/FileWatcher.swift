//
//  FileWatcher.swift
//  iM
//

import Foundation

/// Watches an open document for external edits on the main queue.
///
/// Handles the atomic-rename save used by VS Code, TextEdit, vim and others
/// (write temp file, rename over the original — replacing the inode): the
/// watcher reopens a descriptor against the same path and fires once the new
/// file has settled. A genuine delete leaves the window showing its last
/// content; if the file is recreated within the retry window watching resumes.
@MainActor
final class FileWatcher {

    private let url: URL
    private let onChange: () -> Void
    private var fileDescriptor: Int32 = -1
    private var source: DispatchSourceFileSystemObject?
    private var debounce: DispatchWorkItem?
    private var reattach: DispatchWorkItem?
    private var missingAttempts = 0

    private let changeDelay: TimeInterval = 0.08
    private let settleDelay: TimeInterval = 0.2
    private let missingRetryDelay: TimeInterval = 0.25
    private let maxMissingAttempts = 10

    init(url: URL, onChange: @escaping () -> Void) {
        self.url = url
        self.onChange = onChange
        open()
    }

    private func open() {
        let fd = Darwin.open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }
        fileDescriptor = fd

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .delete, .rename, .revoke],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated {
                self?.handle(source.data)
            }
        }
        source.setCancelHandler { [weak self] in
            MainActor.assumeIsolated {
                guard let self, self.fileDescriptor >= 0 else { return }
                Darwin.close(self.fileDescriptor)
                self.fileDescriptor = -1
            }
        }
        self.source = source
        source.resume()
    }

    private func handle(_ event: DispatchSource.FileSystemEvent) {
        if !event.intersection([.delete, .rename, .revoke]).isEmpty {
            scheduleReattach()
        } else {
            scheduleChange()
        }
    }

    private func scheduleChange() {
        debounce?.cancel()
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated { self?.onChange() }
        }
        debounce = work
        DispatchQueue.main.asyncAfter(deadline: .now() + changeDelay, execute: work)
    }

    private func scheduleReattach() {
        reattach?.cancel()
        debounce?.cancel()
        source?.cancel()
        source = nil
        missingAttempts = 0

        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated { self?.reattemptOrRetry() }
        }
        reattach = work
        DispatchQueue.main.asyncAfter(deadline: .now() + settleDelay, execute: work)
    }

    private func reattemptOrRetry() {
        if FileManager.default.fileExists(atPath: url.path) {
            // Atomic rename completed: a fresh inode now holds the path.
            open()
            scheduleChange()
            return
        }
        missingAttempts += 1
        guard missingAttempts < maxMissingAttempts else { return }
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated { self?.reattemptOrRetry() }
        }
        reattach = work
        DispatchQueue.main.asyncAfter(deadline: .now() + missingRetryDelay, execute: work)
    }

    func cancel() {
        debounce?.cancel()
        reattach?.cancel()
        source?.cancel()
        source = nil
    }
}
