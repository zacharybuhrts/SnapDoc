import XCTest
@testable import SnapDoc

final class ImageSizingTests: XCTestCase {
    func testSmallImageIsUnchanged() {
        let size = ImageSizing.fittedSize(pixelWidth: 10, pixelHeight: 8, maxEdge: 40)
        XCTAssertEqual(size, CGSize(width: 10, height: 8))
    }

    func testLongEdgeIsLimited() {
        let size = ImageSizing.fittedSize(pixelWidth: 100, pixelHeight: 50, maxEdge: 40)
        XCTAssertEqual(size, CGSize(width: 40, height: 20))
    }

    func testPortraitLongEdgeIsLimited() {
        let size = ImageSizing.fittedSize(pixelWidth: 30, pixelHeight: 90, maxEdge: 45)
        XCTAssertEqual(size, CGSize(width: 15, height: 45))
    }

    func testZeroAndNegativeEdgesStaySafe() {
        XCTAssertEqual(ImageSizing.fittedSize(pixelWidth: 0, pixelHeight: 20, maxEdge: 10), CGSize(width: 0, height: 20))
        XCTAssertEqual(ImageSizing.fittedSize(pixelWidth: 10, pixelHeight: 10, maxEdge: 0), CGSize(width: 10, height: 10))
    }
}
