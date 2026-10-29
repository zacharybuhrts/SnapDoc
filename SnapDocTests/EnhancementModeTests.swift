import XCTest
@testable import SnapDoc

final class EnhancementModeTests: XCTestCase {
    func testOriginalIsIdentity() {
        XCTAssertEqual(EnhancementMode.original.parameters, .identity)
        XCTAssertFalse(EnhancementMode.original.parameters.applyOtsuThreshold)
    }

    func testColorBoostsContrastAndSaturation() {
        let parameters = EnhancementMode.color.parameters
        XCTAssertGreaterThan(parameters.saturation, 1)
        XCTAssertGreaterThan(parameters.contrast, 1)
        XCTAssertGreaterThan(parameters.sharpness, 0)
        XCTAssertFalse(parameters.applyOtsuThreshold)
    }

    func testGrayscaleDropsColorWithoutThreshold() {
        let parameters = EnhancementMode.grayscale.parameters
        XCTAssertEqual(parameters.saturation, 0)
        XCTAssertGreaterThan(parameters.contrast, 1)
        XCTAssertFalse(parameters.applyOtsuThreshold)
    }

    func testBlackAndWhiteIsStrongerThanGrayscale() {
        let gray = EnhancementMode.grayscale.parameters
        let mono = EnhancementMode.blackAndWhite.parameters
        XCTAssertEqual(mono.saturation, 0)
        XCTAssertGreaterThan(mono.contrast, gray.contrast)
        XCTAssertTrue(mono.applyOtsuThreshold)
    }

    func testModesHaveDistinctSettings() {
        let all = EnhancementMode.allCases.map(\.parameters)
        XCTAssertEqual(Set(all.map { "\($0)" }).count, EnhancementMode.allCases.count)
    }

    func testTitlesAndRawValuesStayStable() {
        XCTAssertEqual(EnhancementMode.allCases.map(\.title), ["Original", "Color", "Grayscale", "Black & White"])
        XCTAssertEqual(EnhancementMode.blackAndWhite.rawValue, "blackAndWhite")
        XCTAssertEqual(EnhancementMode.color.rawValue, "color")
    }
}
