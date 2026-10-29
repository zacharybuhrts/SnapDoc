import XCTest
@testable import SnapDoc

final class DocumentStoreTests: XCTestCase {
    private var root: URL!
    private var store: DocumentStore!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("SnapDocTests-\(UUID().uuidString)", isDirectory: true)
        store = DocumentStore(rootURL: root)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    func testDefaultRootLivesInDocuments() {
        let url = DocumentStore.defaultRootURL()
        XCTAssertEqual(url.lastPathComponent, "Scans")
        XCTAssertEqual(url.deletingLastPathComponent().lastPathComponent, "Documents")
    }

    func testShareNames() {
        XCTAssertEqual(ScanLayout.shareRelativePaths(format: .pdf, pageCount: 3), ["document.pdf"])
        XCTAssertEqual(
            ScanLayout.shareRelativePaths(format: .jpeg, pageCount: 2),
            ["pages/page-0001.jpg", "pages/page-0002.jpg"]
        )
        XCTAssertEqual(
            ScanLayout.pageFileName(index: 0, format: .png),
            "page-0001.png"
        )
        XCTAssertEqual(ScanLayout.shareRelativePaths(format: .png, pageCount: 0), [])
    }

    func testSaveJPEGWritesPagesThumbnailAndManifest() throws {
        let created = Date(timeIntervalSince1970: 1_700_000_000)
        let saved = try store.save(draft(format: .jpeg, name: "  Lunch   receipt  "), createdAt: created)

        XCTAssertEqual(saved.name, "Lunch receipt")
        XCTAssertEqual(saved.pageCount, 2)
        XCTAssertEqual(saved.format, .jpeg)
        XCTAssertEqual(saved.createdAt, created)
        XCTAssertEqual(try store.loadAll(), [saved])

        let folder = store.directoryURL(for: saved.id)
        let pagesFolder = folder.appendingPathComponent("pages", isDirectory: true)
        XCTAssertEqual(try Data(contentsOf: folder.appendingPathComponent("thumbnail.jpg")), Data("thumb".utf8))
        XCTAssertEqual(try Data(contentsOf: pagesFolder.appendingPathComponent("page-0001.jpg")), Data("one".utf8))
        XCTAssertEqual(try Data(contentsOf: pagesFolder.appendingPathComponent("page-0002.jpg")), Data("two".utf8))
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("document.pdf").path))

        let pages = try store.pageURLs(for: saved.id)
        XCTAssertEqual(pages.map(\.lastPathComponent), ["page-0001.jpg", "page-0002.jpg"])
        let shared = try store.shareURLs(for: saved.id)
        XCTAssertEqual(shared.map(\.lastPathComponent), ["page-0001.jpg", "page-0002.jpg"])
    }

    func testSavePDFWritesTheDocumentAndJPEGPreviews() throws {
        let saved = try store.save(draft(format: .pdf, name: "Taxes"))
        let folder = store.directoryURL(for: saved.id)
        XCTAssertEqual(try Data(contentsOf: folder.appendingPathComponent("document.pdf")), Data("%PDF-fake".utf8))
        XCTAssertEqual(
            try Data(contentsOf: folder.appendingPathComponent("pages", isDirectory: true).appendingPathComponent("page-0001.jpg")),
            Data("one".utf8)
        )
        let shared = try store.shareURLs(for: saved.id)
        XCTAssertEqual(shared.map(\.lastPathComponent), ["document.pdf"])
    }

    func testSavePNGUsesPNGPageNames() throws {
        let saved = try store.save(draft(format: .png, name: "Diagram"))
        let pages = try store.pageURLs(for: saved.id)
        XCTAssertEqual(pages.map(\.lastPathComponent), ["page-0001.png", "page-0002.png"])
    }

    func testLoadAllSortsNewestFirstAndSkipsCorruptFolders() throws {
        let older = try store.save(draft(format: .jpeg, name: "Older"), createdAt: Date(timeIntervalSince1970: 1_700_000_000))
        let newer = try store.save(draft(format: .jpeg, name: "Newer"), createdAt: Date(timeIntervalSince1970: 1_700_086_400))

        let junk = root.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: junk, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: junk.appendingPathComponent("manifest.json"))

        let looseFile = root.appendingPathComponent("notes.txt")
        try Data("hi".utf8).write(to: looseFile)

        XCTAssertEqual(try store.loadAll().map(\.id), [newer.id, older.id])
    }

    func testSkipsManifestWhoseIDDoesNotMatchTheFolder() throws {
        let saved = try store.save(draft(format: .jpeg, name: "Kept"))
        var mismatched = saved
        mismatched.id = UUID()
        let data = try JSONEncoder.iso8601.encode(mismatched)
        try data.write(to: store.directoryURL(for: saved.id).appendingPathComponent("manifest.json"))
        XCTAssertEqual(try store.loadAll(), [])
    }

    func testRenameUpdatesNameAndUpdatedAtOnly() throws {
        let created = Date(timeIntervalSince1970: 1_700_000_000)
        let saved = try store.save(draft(format: .jpeg, name: "Draft"), createdAt: created)
        let renamed = try store.rename(id: saved.id, to: " Final ", now: Date(timeIntervalSince1970: 1_700_000_050))
        XCTAssertEqual(renamed.name, "Final")
        XCTAssertEqual(renamed.createdAt, created)
        XCTAssertEqual(renamed.updatedAt, Date(timeIntervalSince1970: 1_700_000_050))
        XCTAssertEqual(try store.loadAll().first?.name, "Final")
    }

    func testDeleteRemovesTheFolder() throws {
        let saved = try store.save(draft(format: .jpeg, name: "Gone"))
        try store.delete(id: saved.id)
        XCTAssertEqual(try store.loadAll(), [])
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.directoryURL(for: saved.id).path))
        XCTAssertThrowsError(try store.delete(id: saved.id)) { error in
            XCTAssertEqual(error as? DocumentStoreError, .notFound)
        }
    }

    func testRejectsEmptyPagesInvalidNamesAndMissingPDFs() {
        XCTAssertThrowsError(try store.save(draft(format: .jpeg, pages: [Data](), name: "Nope"))) { error in
            XCTAssertEqual(error as? DocumentStoreError, .emptyDocument)
        }
        XCTAssertThrowsError(try store.save(draft(format: .jpeg, name: "   "))) { error in
            XCTAssertEqual(error as? DocumentStoreError, .invalidName)
        }
        var missing = draft(format: .pdf, name: "Report")
        missing.pdfData = nil
        XCTAssertThrowsError(try store.save(missing)) { error in
            XCTAssertEqual(error as? DocumentStoreError, .missingPDF)
        }
        XCTAssertThrowsError(try store.rename(id: UUID(), to: "Missing")) { error in
            XCTAssertEqual(error as? DocumentStoreError, .notFound)
        }
    }

    private func draft(format: ExportFormat, pages: [Data]? = nil, name: String) -> ScanDraft {
        let pageData = pages ?? [Data("one".utf8), Data("two".utf8)]
        return ScanDraft(
            name: name,
            format: format,
            pageData: pageData,
            thumbnailJPEG: Data("thumb".utf8),
            pdfData: format == .pdf ? Data("%PDF-fake".utf8) : nil
        )
    }
}

private extension JSONEncoder {
    static let iso8601: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}
