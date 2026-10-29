import UIKit

enum ImageNormalizer {
    /// Draws `image` upright onto an opaque bitmap, shrinking the long edge when needed.
    static func uprightCGImage(from image: UIImage, maxEdge: CGFloat) -> CGImage? {
        let pixelWidth = Int((image.size.width * image.scale).rounded())
        let pixelHeight = Int((image.size.height * image.scale).rounded())
        guard pixelWidth > 0, pixelHeight > 0 else { return nil }

        let fitted = ImageSizing.fittedSize(
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            maxEdge: maxEdge
        )
        guard fitted.width >= 1, fitted.height >= 1 else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard
        let renderer = UIGraphicsImageRenderer(size: fitted, format: format)
        let rendered = renderer.image { context in
            context.cgContext.interpolationQuality = .high
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: fitted))
            image.draw(in: CGRect(origin: .zero, size: fitted))
        }
        return rendered.cgImage
    }
}

enum ImageRotator {
    /// Rotates pixels 90 degrees clockwise. The caller updates corners separately.
    static func rotateClockwise(_ image: UIImage) -> UIImage? {
        let sourceSize = image.size
        guard sourceSize.width >= 1, sourceSize.height >= 1 else { return nil }
        let newSize = CGSize(width: sourceSize.height, height: sourceSize.width)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        // Positive rotation in UIKit's y-down context turns the image clockwise.
        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.translateBy(x: newSize.width / 2, y: newSize.height / 2)
            cgContext.rotate(by: .pi / 2)
            image.draw(
                in: CGRect(
                    x: -sourceSize.width / 2,
                    y: -sourceSize.height / 2,
                    width: sourceSize.width,
                    height: sourceSize.height
                )
            )
        }
    }
}
