import Foundation

/// Core Image controls for one document look.
///
/// `ImageEnhancer` applies these in order: color controls, optional luminance
/// sharpen, then an optional Otsu black-and-white threshold.
struct EnhancementParameters: Equatable, Sendable {
    var saturation: Double
    var contrast: Double
    var brightness: Double
    var sharpness: Double
    var applyOtsuThreshold: Bool

    static let identity = EnhancementParameters(
        saturation: 1,
        contrast: 1,
        brightness: 0,
        sharpness: 0,
        applyOtsuThreshold: false
    )
}

/// The four looks offered while reviewing a page.
enum EnhancementMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case original
    case color
    case grayscale
    case blackAndWhite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .original:
            return "Original"
        case .color:
            return "Color"
        case .grayscale:
            return "Grayscale"
        case .blackAndWhite:
            return "Black & White"
        }
    }

    var parameters: EnhancementParameters {
        switch self {
        case .original:
            return .identity
        case .color:
            return EnhancementParameters(
                saturation: 1.18,
                contrast: 1.16,
                brightness: 0.02,
                sharpness: 0.35,
                applyOtsuThreshold: false
            )
        case .grayscale:
            return EnhancementParameters(
                saturation: 0,
                contrast: 1.22,
                brightness: 0.03,
                sharpness: 0.30,
                applyOtsuThreshold: false
            )
        case .blackAndWhite:
            return EnhancementParameters(
                saturation: 0,
                contrast: 1.40,
                brightness: 0.04,
                sharpness: 0.15,
                applyOtsuThreshold: true
            )
        }
    }
}
