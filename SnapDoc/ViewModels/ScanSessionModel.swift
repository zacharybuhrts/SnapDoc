import Observation
import UIKit

@MainActor
@Observable
final class ScanSessionModel {
    var pages: [EditablePage]
    var selectedPageID: UUID
    var previewImage: UIImage?
    var isRendering = false
    var name: String

    private var renderGeneration = 0

    init(pages: [EditablePage], name: String? = nil) {
        precondition(!pages.isEmpty, "A review session needs at least one page.")
        self.pages = pages
        self.selectedPageID = pages[0].id
        self.previewImage = pages[0].source
        self.name = name ?? ScanNaming.defaultTitle(for: Date())
        schedulePreview()
    }

    var selectedIndex: Int {
        pages.firstIndex { $0.id == selectedPageID } ?? 0
    }

    var selectedPage: EditablePage? {
        pages.first { $0.id == selectedPageID }
    }

    func select(id: UUID) {
        guard pages.contains(where: { $0.id == id }) else { return }
        selectedPageID = id
        schedulePreview()
    }

    func updateSelected(_ mutate: (inout EditablePage) -> Void) {
        guard let index = pages.firstIndex(where: { $0.id == selectedPageID }) else { return }
        mutate(&pages[index])
        schedulePreview()
    }

    func setMode(_ mode: EnhancementMode) {
        updateSelected { $0.mode = mode }
    }

    func setCorners(_ corners: Quadrilateral) {
        updateSelected { $0.corners = corners }
    }

    func deleteSelected() {
        guard let index = pages.firstIndex(where: { $0.id == selectedPageID }) else { return }
        pages.remove(at: index)
        guard !pages.isEmpty else {
            previewImage = nil
            isRendering = false
            return
        }
        let next = min(index, pages.count - 1)
        selectedPageID = pages[next].id
        schedulePreview()
    }

    func moveSelected(offset: Int) {
        guard let index = pages.firstIndex(where: { $0.id == selectedPageID }) else { return }
        let destination = index + offset
        guard pages.indices.contains(destination) else { return }
        let page = pages.remove(at: index)
        pages.insert(page, at: destination)
    }

    func rotateSelectedClockwise() {
        guard let index = pages.firstIndex(where: { $0.id == selectedPageID }) else { return }
        guard let rotated = ImageRotator.rotateClockwise(pages[index].source) else { return }
        let oldSize = pages[index].pixelSize
        let corners = CornerGeometry.rotatedClockwise(pages[index].corners, imageSize: oldSize)
        let detected = CornerGeometry.rotatedClockwise(pages[index].detectedCorners, imageSize: oldSize)
        pages[index].source = rotated
        pages[index].pixelSize = corners.size
        pages[index].corners = corners.quad
        pages[index].detectedCorners = detected.quad
        schedulePreview()
    }

    private func schedulePreview() {
        renderGeneration += 1
        let generation = renderGeneration
        guard let page = selectedPage else {
            previewImage = nil
            isRendering = false
            return
        }
        isRendering = true
        Task {
            let box = await Task.detached(priority: .userInitiated) {
                ImageBox(PageRenderer.previewImage(for: page))
            }.value
            guard generation == renderGeneration else { return }
            previewImage = box.image
            isRendering = false
        }
    }
}

private final class ImageBox: @unchecked Sendable {
    let image: UIImage?
    init(_ image: UIImage?) { self.image = image }
}

private struct ImageBatch: @unchecked Sendable {
    let images: [UIImage]
}

enum ScanSessionBuilder {
    static func makePages(from images: [UIImage]) -> [EditablePage] {
        images.compactMap { image in
            guard let cgImage = ImageNormalizer.uprightCGImage(from: image, maxEdge: ImageSizing.workingMaxEdge) else {
                return nil
            }
            let pixelSize = CGSize(width: cgImage.width, height: cgImage.height)
            let detected = PageRectangleDetector.detectCorners(in: cgImage) ?? Quadrilateral.fullImage(size: pixelSize)
            let clamped = detected.clamped(to: pixelSize)
            let corners = clamped.isConvex() ? clamped : Quadrilateral.fullImage(size: pixelSize)
            return EditablePage(
                source: UIImage(cgImage: cgImage, scale: 1, orientation: .up),
                pixelSize: pixelSize,
                corners: corners,
                detectedCorners: corners,
                mode: .color
            )
        }
    }

    static func makePagesOffMain(from images: [UIImage]) async -> [EditablePage] {
        let batch = ImageBatch(images: images)
        return await Task.detached(priority: .userInitiated) {
            ScanSessionBuilder.makePages(from: batch.images)
        }.value
    }
}
