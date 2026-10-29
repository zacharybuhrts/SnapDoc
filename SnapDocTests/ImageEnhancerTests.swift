import XCTest
@testable import SnapDoc

final class ImageEnhancerTests: XCTestCase {
    func testSamplerReadsTopLeftOfConstructedImage() throws {
        let image = TestImages.rgba(width: 2, height: 2) { x, y in
            if y == 0 && x == 0 { return (10, 20, 30, 255) }
            return (200, 210, 220, 255)
        }
        let pixel = try XCTUnwrap(TestImages.sample(image, x: 0, y: 0))
        XCTAssertEqual(pixel.0, 10)
        XCTAssertEqual(pixel.1, 20)
        XCTAssertEqual(pixel.2, 30)
    }

    func testOriginalRenderKeepsPixelsAndSize() throws {
        let image = TestImages.solid(width: 12, height: 8, red: 220, green: 10, blue: 10)
        let output = try XCTUnwrap(ImageEnhancer.render(cgImage: image, mode: .original))
        XCTAssertEqual(output.width, 12)
        XCTAssertEqual(output.height, 8)
        let pixel = try XCTUnwrap(TestImages.sample(output, x: 3, y: 3))
        XCTAssertEqual(pixel.0, 220)
        XCTAssertEqual(pixel.1, 10)
        XCTAssertEqual(pixel.2, 10)
    }

    func testEveryModePreservesDimensions() {
        let image = TestImages.solid(width: 16, height: 10, red: 180, green: 40, blue: 40)
        for mode in EnhancementMode.allCases {
            let output = ImageEnhancer.render(cgImage: image, mode: mode)
            XCTAssertEqual(output?.width, 16, "\(mode)")
            XCTAssertEqual(output?.height, 10, "\(mode)")
        }
    }

    func testGrayscaleCollapsesChannels() throws {
        let image = TestImages.solid(width: 8, height: 8, red: 200, green: 30, blue: 30)
        let output = try XCTUnwrap(ImageEnhancer.render(cgImage: image, mode: .grayscale))
        let pixel = try XCTUnwrap(TestImages.sample(output, x: 4, y: 4))
        XCTAssertEqual(pixel.0, pixel.1, accuracy: 5)
        XCTAssertEqual(pixel.1, pixel.2, accuracy: 5)
    }

    func testBlackAndWhiteIsNeutral() throws {
        let image = TestImages.solid(width: 8, height: 8, red: 200, green: 30, blue: 30)
        let output = try XCTUnwrap(ImageEnhancer.render(cgImage: image, mode: .blackAndWhite))
        let pixel = try XCTUnwrap(TestImages.sample(output, x: 4, y: 4))
        XCTAssertEqual(pixel.0, pixel.1, accuracy: 5)
        XCTAssertEqual(pixel.1, pixel.2, accuracy: 5)
    }

    func testColorKeepsARedPageRed() throws {
        let image = TestImages.solid(width: 8, height: 8, red: 210, green: 40, blue: 40)
        let output = try XCTUnwrap(ImageEnhancer.render(cgImage: image, mode: .color))
        let pixel = try XCTUnwrap(TestImages.sample(output, x: 4, y: 4))
        XCTAssertGreaterThan(Int(pixel.0), Int(pixel.1) + 20)
        XCTAssertGreaterThan(Int(pixel.0), Int(pixel.2) + 20)
    }
}

private func XCTAssertEqual(_ lhs: UInt8, _ rhs: UInt8, accuracy: UInt8, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertLessThanOrEqual(abs(Int(lhs) - Int(rhs)), Int(accuracy), file: file, line: line)
}
