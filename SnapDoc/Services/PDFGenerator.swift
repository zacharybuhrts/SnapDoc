import PDFKit
import UIKit

enum PDFGeneratorError: Error, Equatable, LocalizedError {
    case noPages
    case failed

    var errorDescription: String? {
        switch self {
        case .noPages:
            return "Add at least one page before creating a PDF."
        case .failed:
            return "Couldn't create the PDF."
        }
    }
}

enum PDFGenerator {
    /// Builds a multi-page PDF. Each page is the pixel size of its image.
    static func makePDF(from images: [CGImage]) throws -> Data {
        guard !images.isEmpty else { throw PDFGeneratorError.noPages }

        let document = PDFDocument()
        for (index, image) in images.enumerated() {
            let pageImage = UIImage(cgImage: image, scale: 1, orientation: .up)
            guard let page = PDFPage(image: pageImage) else {
                throw PDFGeneratorError.failed
            }
            document.insert(page, at: index)
        }

        guard let data = document.dataRepresentation(), !data.isEmpty else {
            throw PDFGeneratorError.failed
        }
        return data
    }
}
