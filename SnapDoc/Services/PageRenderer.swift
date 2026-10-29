import UIKit

enum ExportError: LocalizedError, Equatable {
    case renderFailed
    case encodeFailed

    var errorDescription: String? {
        switch self {
        case .renderFailed:
            return "Couldn't render one of the pages."
        case .encodeFailed:
            return "Couldn't encode one of the pages."
        }
    }
}

enum PageRenderer {
    static func exportImage(for page: EditablePage) -> CGImage? {
        guard let cgImage = page.source.cgImage else { return nil }
        return render(
            cgImage: cgImage,
            pixelSize: page.pixelSize,
            corners: page.corners,
            mode: page.mode
        )
    }

    static func previewImage(for page: EditablePage) -> UIImage? {
        guard let rendered = exportImage(for: page) else { return page.source }
        return UIImage(cgImage: rendered, scale: 1, orientation: .up)
    }

    static func render(
        cgImage: CGImage,
        pixelSize: CGSize,
        corners: Quadrilateral,
        mode: EnhancementMode
    ) -> CGImage? {
        let corrected: CGImage
        if corners.isApproximatelyFullImage(size: pixelSize) {
            corrected = cgImage
        } else if let warped = PerspectiveCorrector.correct(cgImage: cgImage, corners: corners) {
            corrected = warped
        } else {
            corrected = cgImage
        }
        if mode == .original {
            return corrected
        }
        return ImageEnhancer.render(cgImage: corrected, mode: mode) ?? corrected
    }
}

enum ScanExporter {
    static func draft(name: String, format: ExportFormat, pages: [EditablePage]) throws -> ScanDraft {
        guard !pages.isEmpty else { throw DocumentStoreError.emptyDocument }
        var rendered: [CGImage] = []
        rendered.reserveCapacity(pages.count)
        for page in pages {
            guard let image = PageRenderer.exportImage(for: page) else {
                throw ExportError.renderFailed
            }
            rendered.append(image)
        }
        let pageData = try rendered.map { try PageEncoder.pageData(from: $0, format: format) }
        guard let first = rendered.first else { throw ExportError.renderFailed }
        let thumbnail = try PageEncoder.thumbnailJPEG(from: first)
        let pdfData = try format == .pdf ? PDFGenerator.makePDF(from: rendered) : nil
        return ScanDraft(
            name: name,
            format: format,
            pageData: pageData,
            thumbnailJPEG: thumbnail,
            pdfData: pdfData
        )
    }
}

enum PageEncoder {
    static let jpegQuality: CGFloat = 0.92
    static let thumbnailQuality: CGFloat = 0.82

    static func pageData(from image: CGImage, format: ExportFormat) throws -> Data {
        let uiImage = UIImage(cgImage: image)
        switch format {
        case .png:
            guard let data = uiImage.pngData(), !data.isEmpty else {
                throw ExportError.encodeFailed
            }
            return data
        case .jpeg, .pdf:
            guard let data = uiImage.jpegData(compressionQuality: jpegQuality), !data.isEmpty else {
                throw ExportError.encodeFailed
            }
            return data
        }
    }

    static func thumbnailJPEG(from image: CGImage) throws -> Data {
        let fitted = ImageSizing.fittedSize(
            pixelWidth: image.width,
            pixelHeight: image.height,
            maxEdge: ImageSizing.thumbnailMaxEdge
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: fitted, format: format)
        let thumbnail = renderer.image { _ in
            UIImage(cgImage: image).draw(in: CGRect(origin: .zero, size: fitted))
        }
        guard let data = thumbnail.jpegData(compressionQuality: thumbnailQuality), !data.isEmpty else {
            throw ExportError.encodeFailed
        }
        return data
    }
}
