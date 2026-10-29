import Foundation

enum ExportFormat: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case pdf
    case jpeg
    case png

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pdf: return "PDF"
        case .jpeg: return "JPEG"
        case .png: return "PNG"
        }
    }

    /// Page previews stored beside a PDF are JPEGs. Image scans use their own type.
    var pageFileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg, .pdf: return "jpg"
        }
    }
}

struct ScanRoute: Hashable, Identifiable {
    let id: UUID
}

struct SavedScan: Identifiable, Codable, Equatable, Hashable, Sendable {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var format: ExportFormat
    var pageCount: Int
}
