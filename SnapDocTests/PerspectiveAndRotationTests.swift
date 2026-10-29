import UIKit
import XCTest
@testable import SnapDoc

final class PerspectiveAndRotationTests: XCTestCase {
    func testInsetQuadProducesAPageOfAboutThatSize() throws {
        let image = TestImages.solid(width: 48, height: 36, red: 240, green: 240, blue: 240)
        let corners = Quadrilateral(
            topLeft: CGPoint(x: 6, y: 6),
            topRight: CGPoint(x: 42, y: 6),
            bottomRight: CGPoint(x: 42, y: 30),
            bottomLeft: CGPoint(x: 6, y: 30)
        )
        let output = try XCTUnwrap(PerspectiveCorrector.correct(cgImage: image, corners: corners))
        XCTAssertEqual(output.width, 36, accuracy: 6)
        XCTAssertEqual(output.height, 24, accuracy: 6)
    }

    func testFullFrameOriginalPreviewKeepsTheWorkingImage() throws {
        let image = TestImages.solid(width: 16, height: 12, red: 20, green: 30, blue: 40)
        let size = CGSize(width: 16, height: 12)
        let output = try XCTUnwrap(
            PageRenderer.render(
                cgImage: image,
                pixelSize: size,
                corners: Quadrilateral.fullImage(size: size),
                mode: .original
            )
        )
        XCTAssertEqual(output.width, 16)
        XCTAssertEqual(output.height, 12)
        let pixel = try XCTUnwrap(TestImages.sample(output, x: 1, y: 1))
        XCTAssertEqual(pixel.0, 20)
        XCTAssertEqual(pixel.1, 30)
        XCTAssertEqual(pixel.2, 40)
    }

    func testClockwiseRotationMovesTheLeftPixelToTheTop() throws {
        let image = TestImages.rgba(width: 2, height: 1) { x, _ in
            x == 0 ? (255, 0, 0, 255) : (0, 0, 255, 255)
        }
        let rotated = try XCTUnwrap(ImageRotator.rotateClockwise(UIImage(cgImage: image, scale: 1, orientation: .up)))
        let cgImage = try XCTUnwrap(rotated.cgImage)
        XCTAssertEqual(cgImage.width, 1)
        XCTAssertEqual(cgImage.height, 2)
        let top = try XCTUnwrap(TestImages.sample(cgImage, x: 0, y: 0))
        let bottom = try XCTUnwrap(TestImages.sample(cgImage, x: 0, y: 1))
        XCTAssertGreaterThan(Int(top.0), 200)
        XCTAssertLessThan(Int(top.2), 40)
        XCTAssertGreaterThan(Int(bottom.2), 200)
        XCTAssertLessThan(Int(bottom.0), 40)
    }

    func testNormalizerLimitsTheLongEdge() throws {
        let image = TestImages.solid(width: 100, height: 50, red: 255, green: 255, blue: 255)
        let output = try XCTUnwrap(
            ImageNormalizer.uprightCGImage(from: UIImage(cgImage: image, scale: 1, orientation: .up), maxEdge: 40)
        )
        XCTAssertEqual(output.width, 40)
        XCTAssertEqual(output.height, 20)
    }
}

private func XCTAssertEqual(_ lhs: Int, _ rhs: Int, accuracy: Int, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertLessThanOrEqual(abs(lhs - rhs), accuracy, file: file, line: line)
}
