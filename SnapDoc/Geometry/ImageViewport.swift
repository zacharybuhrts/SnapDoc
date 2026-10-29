import Foundation

/// Maps pixel coordinates onto an aspect-fit image inside a view.
struct ImageViewport: Equatable, Sendable {
    var imageSize: CGSize
    var viewSize: CGSize

    var fittedRect: CGRect {
        guard imageSize.width > 0, imageSize.height > 0, viewSize.width > 0, viewSize.height > 0 else {
            return .zero
        }
        let scale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        let origin = CGPoint(
            x: (viewSize.width - width) / 2,
            y: (viewSize.height - height) / 2
        )
        return CGRect(origin: origin, size: CGSize(width: width, height: height))
    }

    func viewPoint(fromImage point: CGPoint) -> CGPoint {
        let rect = fittedRect
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }
        return CGPoint(
            x: rect.minX + point.x * rect.width / imageSize.width,
            y: rect.minY + point.y * rect.height / imageSize.height
        )
    }

    func imagePoint(fromView point: CGPoint) -> CGPoint {
        let rect = fittedRect
        guard rect.width > 0, rect.height > 0 else { return .zero }
        return CGPoint(
            x: (point.x - rect.minX) * imageSize.width / rect.width,
            y: (point.y - rect.minY) * imageSize.height / rect.height
        )
    }
}
