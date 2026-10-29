import CoreImage
import CoreGraphics

enum ImageEnhancer {
    static let context = CIContext(options: [.cacheIntermediates: false])

    /// Original is returned unchanged. Other modes render a new bitmap.
    static func render(cgImage: CGImage, mode: EnhancementMode) -> CGImage? {
        if mode == .original {
            return cgImage
        }
        let input = CIImage(cgImage: cgImage)
        let output = apply(mode.parameters, to: input)
        let extent = output.extent.integral
        guard extent.width >= 1, extent.height >= 1, !extent.isInfinite, !extent.isNull else {
            return nil
        }
        return context.createCGImage(output, from: extent)
    }

    static func apply(_ parameters: EnhancementParameters, to image: CIImage) -> CIImage {
        var result = image.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: parameters.saturation,
            kCIInputContrastKey: parameters.contrast,
            kCIInputBrightnessKey: parameters.brightness
        ])
        if parameters.sharpness > 0 {
            result = result.applyingFilter("CISharpenLuminance", parameters: [
                kCIInputSharpnessKey: parameters.sharpness
            ])
        }
        if parameters.applyOtsuThreshold {
            result = result.applyingFilter("CIColorThresholdOtsu")
        }
        return result
    }
}
