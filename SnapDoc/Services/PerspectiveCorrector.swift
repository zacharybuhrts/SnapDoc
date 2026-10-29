import CoreImage
import CoreGraphics

enum PerspectiveCorrector {
    /// Straightens `corners` (top-left pixel origin) into a flat page image.
    static func correct(cgImage: CGImage, corners: Quadrilateral) -> CGImage? {
        let pixelSize = CGSize(width: cgImage.width, height: cgImage.height)
        let clamped = corners.clamped(to: pixelSize)
        guard clamped.isConvex() else { return nil }

        let ciCorners = clamped.toCIImageSpace(imageHeight: pixelSize.height)
        let image = CIImage(cgImage: cgImage)
        let filtered = image.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: ciCorners.topLeft),
            "inputTopRight": CIVector(cgPoint: ciCorners.topRight),
            "inputBottomRight": CIVector(cgPoint: ciCorners.bottomRight),
            "inputBottomLeft": CIVector(cgPoint: ciCorners.bottomLeft)
        ])
        let extent = filtered.extent.integral
        guard extent.width >= 2, extent.height >= 2, !extent.isInfinite, !extent.isNull else {
            return nil
        }
        return ImageEnhancer.context.createCGImage(filtered, from: extent)
    }
}
