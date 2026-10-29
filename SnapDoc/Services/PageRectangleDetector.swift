import CoreGraphics
import Vision

enum PageRectangleDetector {
    /// Finds the most likely document rectangle. Returns nil when Vision is unsure.
    static func detectCorners(in cgImage: CGImage) -> Quadrilateral? {
        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = 0.2
        request.maximumAspectRatio = 1
        request.minimumSize = 0.12
        request.maximumObservations = 1
        request.minimumConfidence = 0.45
        request.quadratureTolerance = 35

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        guard let observation = request.results?.first as? VNRectangleObservation else {
            return nil
        }
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        let quad = CornerGeometry.quadrilateral(
            fromVisionTopLeft: observation.topLeft,
            topRight: observation.topRight,
            bottomRight: observation.bottomRight,
            bottomLeft: observation.bottomLeft,
            imageSize: size
        )
        let clamped = quad.clamped(to: size)
        return clamped.isConvex() ? clamped : nil
    }
}
