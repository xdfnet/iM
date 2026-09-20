//
//  ReaderDocument.swift
//  iM
//

import Cocoa
import Synchronization

/// Read-only NSDocument: opens every declared file type as text and never
/// writes back. The window controller owns all rendering; the document only
/// supplies the initial text snapshot and standard open/recent semantics.
@MainActor
final class ReaderDocument: NSDocument {

    private nonisolated let textStorage = Mutex("")

    var currentText: String {
        textStorage.withLock { $0 }
    }

    override init() {
        super.init()
        hasUndoManager = false
    }

    override nonisolated class var autosavesInPlace: Bool {
        false
    }

    override var isDocumentEdited: Bool {
        false
    }

    override func makeWindowControllers() {
        addWindowController(ReaderWindowController(document: self))
    }

    override nonisolated func read(from url: URL, ofType typeName: String) throws {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        try read(from: Data(contentsOf: url), ofType: typeName)
    }

    override nonisolated func read(from data: Data, ofType typeName: String) throws {
        guard let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        textStorage.withLock { $0 = text }
    }

    override func data(ofType typeName: String) throws -> Data {
        throw CocoaError(.fileWriteNoPermission)
    }

    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        switch item.action {
        case #selector(save(_:)),
             #selector(saveAs(_:)),
             #selector(saveTo(_:)),
             #selector(revertToSaved(_:)):
            return false
        default:
            return super.validateUserInterfaceItem(item)
        }
    }
}
