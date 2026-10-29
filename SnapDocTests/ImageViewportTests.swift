import XCTest
@testable import SnapDoc

final class ImageViewportTests: XCTestCase {
    func testWideImageIsLetterboxedVertically() {
        let viewport = ImageViewport(imageSize: CGSize(width: 200, height: 100), viewSize: CGSize(width: 100, height: 100))
        let fitted = viewport.fittedRect
        XCTAssertEqual(fitted.minX, 0, accuracy: 0.001)
        XCTAssertEqual(fitted.minY, 25, accuracy: 0.001)
        XCTAssertEqual(fitted.width, 100, accuracy: 0.001)
        XCTAssertEqual(fitted.height, 50, accuracy: 0.001)
    }

    func testTallImageIsLetterboxedHorizontally() {
        let viewport = ImageViewport(imageSize: CGSize(width: 100, height: 200), viewSize: CGSize(width: 100, height: 100))
        let fitted = viewport.fittedRect
        XCTAssertEqual(fitted.minX, 25, accuracy: 0.001)
        XCTAssertEqual(fitted.minY, 0, accuracy: 0.001)
        XCTAssertEqual(fitted.width, 50, accuracy: 0.001)
        XCTAssertEqual(fitted.height, 100, accuracy: 0.001)
    }

    func testPointMappingRoundTrips() {
        let viewport = ImageViewport(imageSize: CGSize(width: 200, height: 100), viewSize: CGSize(width: 100, height: 100))
        let imagePoint = CGPoint(x: 200, y: 100)
        let viewPoint = viewport.viewPoint(fromImage: imagePoint)
        XCTAssertPointEqual(viewPoint, CGPoint(x: 100, y: 75))
        XCTAssertPointEqual(viewport.imagePoint(fromView: viewPoint), imagePoint)
    }

    func testZeroSizeDoesNotCrash() {
        let viewport = ImageViewport(imageSize: .zero, viewSize: CGSize(width: 10, height: 10))
        XCTAssertEqual(viewport.fittedRect, .zero)
        XCTAssertEqual(viewport.viewPoint(fromImage: CGPoint(x: 1, y: 1)), .zero)
        XCTAssertEqual(viewport.imagePoint(fromView: CGPoint(x: 1, y: 1)), .zero)
    }
}
