import Foundation

struct ScanDraft: Equatable, Sendable {
    var name: String
    var format: ExportFormat
    var pageData: [Data]
    var thumbnailJPEG: Data
    var pdfData: Data?
}

enum DocumentStoreError: Error, Equatable, LocalizedError {
    case emptyDocument
    case invalidName
    case missingPDF
    case notFound
    case unreadable
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .emptyDocument:
            return "Add at least one page before saving."
        case .invalidName:
            return "Enter a name for this scan."
        case .missingPDF:
            return "The PDF couldn't be created."
        case .notFound:
            return "That scan is no longer on this iPhone."
        case .unreadable:
            return "A saved scan couldn't be read."
        case .writeFailed:
            return "The scan couldn't be saved."
        }
    }
}

enum ScanLayout {
    static let manifestName = "manifest.json"
    static let thumbnailName = "thumbnail.jpg"
    static let pdfName = "document.pdf"
    static let pagesDirectoryName = "pages"

    static func pageFileName(index: Int, format: ExportFormat) -> String {
        let number = String(format: "%04d", index + 1)
        return "page-\(number).\(format.pageFileExtension)"
    }

    static func shareRelativePaths(format: ExportFormat, pageCount: Int) -> [String] {
        switch format {
        case .pdf:
            return [pdfName]
        case .jpeg, .png:
            guard pageCount > 0 else { return [] }
            return (0..<pageCount).map { index in
                "\(pagesDirectoryName)/\(pageFileName(index: index, format: format))"
            }
        }
    }
}

/// Stores each scan in its own folder under Documents/Scans.
final class DocumentStore {
    let rootURL: URL
    private let fileManager: FileManager

    init(rootURL: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let rootURL {
            self.rootURL = rootURL
        } else {
            self.rootURL = Self.defaultRootURL(fileManager: fileManager)
        }
    }

    static func defaultRootURL(fileManager: FileManager = .default) -> URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return documents.appendingPathComponent("Scans", isDirectory: true)
    }

    func loadAll() throws -> [SavedScan] {
        guard fileManager.fileExists(atPath: rootURL.path) else { return [] }
        let folders: [URL]
        do {
            folders = try fileManager.contentsOfDirectory(
                at: rootURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
        } catch {
            throw DocumentStoreError.unreadable
        }

        var scans: [SavedScan] = []
        for folder in folders {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: folder.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                continue
            }
            guard let scan = loadManifestIfPresent(in: folder),
                  UUID(uuidString: folder.lastPathComponent) == scan.id else {
                continue
            }
            scans.append(scan)
        }

        return scans.sorted { lhs, rhs in
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt > rhs.createdAt
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    func save(_ draft: ScanDraft, createdAt: Date = Date()) throws -> SavedScan {
        guard !draft.pageData.isEmpty else { throw DocumentStoreError.emptyDocument }
        guard draft.pageData.allSatisfy({ !$0.isEmpty }) else { throw DocumentStoreError.writeFailed }
        guard !draft.thumbnailJPEG.isEmpty else { throw DocumentStoreError.writeFailed }
        guard let name = ScanNaming.cleaned(draft.name) else { throw DocumentStoreError.invalidName }
        if draft.format == .pdf {
            guard let pdfData = draft.pdfData, !pdfData.isEmpty else {
                throw DocumentStoreError.missingPDF
            }
            _ = pdfData
        }

        let scan = SavedScan(
            id: UUID(),
            name: name,
            createdAt: createdAt,
            updatedAt: createdAt,
            format: draft.format,
            pageCount: draft.pageData.count
        )
        let directory = directoryURL(for: scan.id)
        let pagesURL = directory.appendingPathComponent(ScanLayout.pagesDirectoryName, isDirectory: true)

        do {
            try fileManager.createDirectory(at: pagesURL, withIntermediateDirectories: true)
            for (index, data) in draft.pageData.enumerated() {
                let fileName = ScanLayout.pageFileName(index: index, format: draft.format)
                try data.write(to: pagesURL.appendingPathComponent(fileName), options: .atomic)
            }
            try draft.thumbnailJPEG.write(
                to: directory.appendingPathComponent(ScanLayout.thumbnailName),
                options: .atomic
            )
            if draft.format == .pdf, let pdfData = draft.pdfData {
                try pdfData.write(
                    to: directory.appendingPathComponent(ScanLayout.pdfName),
                    options: .atomic
                )
            }
            try writeManifest(scan, in: directory)
            return scan
        } catch let error as DocumentStoreError {
            try? fileManager.removeItem(at: directory)
            throw error
        } catch {
            try? fileManager.removeItem(at: directory)
            throw DocumentStoreError.writeFailed
        }
    }

    func rename(id: UUID, to name: String, now: Date = Date()) throws -> SavedScan {
        guard let cleaned = ScanNaming.cleaned(name) else { throw DocumentStoreError.invalidName }
        var scan = try requireScan(id: id)
        scan.name = cleaned
        scan.updatedAt = now
        try writeManifest(scan, in: directoryURL(for: id))
        return scan
    }

    func delete(id: UUID) throws {
        let directory = directoryURL(for: id)
        guard fileManager.fileExists(atPath: directory.path) else {
            throw DocumentStoreError.notFound
        }
        do {
            try fileManager.removeItem(at: directory)
        } catch {
            throw DocumentStoreError.writeFailed
        }
    }

    func thumbnailURL(for id: UUID) -> URL {
        directoryURL(for: id).appendingPathComponent(ScanLayout.thumbnailName)
    }

    func pageURLs(for id: UUID) throws -> [URL] {
        _ = try requireScan(id: id)
        let pages = directoryURL(for: id).appendingPathComponent(ScanLayout.pagesDirectoryName, isDirectory: true)
        guard fileManager.fileExists(atPath: pages.path) else { throw DocumentStoreError.unreadable }
        let urls: [URL]
        do {
            urls = try fileManager.contentsOfDirectory(
                at: pages,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
        } catch {
            throw DocumentStoreError.unreadable
        }
        let sorted = urls.sorted {
            $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
        }
        guard !sorted.isEmpty else { throw DocumentStoreError.unreadable }
        return sorted
    }

    func shareURLs(for id: UUID) throws -> [URL] {
        let scan = try requireScan(id: id)
        let urls: [URL]
        switch scan.format {
        case .pdf:
            urls = [directoryURL(for: id).appendingPathComponent(ScanLayout.pdfName)]
        case .jpeg, .png:
            urls = try pageURLs(for: id)
        }
        guard !urls.isEmpty, urls.allSatisfy({ fileManager.fileExists(atPath: $0.path) }) else {
            throw DocumentStoreError.unreadable
        }
        return urls
    }

    func directoryURL(for id: UUID) -> URL {
        rootURL.appendingPathComponent(id.uuidString, isDirectory: true)
    }

    private func requireScan(id: UUID) throws -> SavedScan {
        let directory = directoryURL(for: id)
        guard let scan = loadManifestIfPresent(in: directory), scan.id == id else {
            throw DocumentStoreError.notFound
        }
        return scan
    }

    private func loadManifestIfPresent(in folder: URL) -> SavedScan? {
        let url = folder.appendingPathComponent(ScanLayout.manifestName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? makeDecoder().decode(SavedScan.self, from: data)
    }

    private func writeManifest(_ scan: SavedScan, in directory: URL) throws {
        let data: Data
        do {
            data = try makeEncoder().encode(scan)
        } catch {
            throw DocumentStoreError.writeFailed
        }
        do {
            try data.write(to: directory.appendingPathComponent(ScanLayout.manifestName), options: .atomic)
        } catch {
            throw DocumentStoreError.writeFailed
        }
    }

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
