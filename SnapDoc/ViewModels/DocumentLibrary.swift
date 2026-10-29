import Foundation
import Observation

@MainActor
@Observable
final class DocumentLibrary {
    private let store: DocumentStore
    private(set) var scans: [SavedScan] = []
    private(set) var lastError: String?

    init(store: DocumentStore = DocumentStore()) {
        self.store = store
    }

    func reload() {
        do {
            scans = try store.loadAll()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func save(_ draft: ScanDraft) throws -> SavedScan {
        let scan = try store.save(draft)
        reload()
        return scan
    }

    func rename(id: UUID, to name: String) throws {
        _ = try store.rename(id: id, to: name)
        reload()
    }

    func delete(id: UUID) throws {
        try store.delete(id: id)
        reload()
    }

    func shareURLs(for id: UUID) throws -> [URL] {
        try store.shareURLs(for: id)
    }

    func pageURLs(for id: UUID) throws -> [URL] {
        try store.pageURLs(for: id)
    }

    func thumbnailURL(for id: UUID) -> URL {
        store.thumbnailURL(for: id)
    }

    func scan(id: UUID) -> SavedScan? {
        scans.first { $0.id == id }
    }
}
