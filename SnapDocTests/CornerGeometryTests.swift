import XCTest
@testable import SnapDoc

final class CornerGeometryTests: XCTestCase {
    func testOrdersScrambledRectangle() throws {
        let points = [
            CGPoint(x: 90, y: 90),
            CGPoint(x: 0, y: 0),
            CGPoint(x: 100, y: 10),
            CGPoint(x: 10, y: 80)
        ]
        let quad = try XCTUnwrap(CornerGeometry.orderedQuadrilateral(from: points))
        XCTAssertPointEqual(quad.topLeft, CGPoint(x: 0, y: 0))
        XCTAssertPointEqual(quad.topRight, CGPoint(x: 100, y: 10))
        XCTAssertPointEqual(quad.bottomRight, CGPoint(x: 90, y: 90))
        XCTAssertPointEqual(quad.bottomLeft, CGPoint(x: 10, y: 80))
        XCTAssertTrue(quad.isConvex())
    }

    func testRejectsTooFewPointsAndDuplicates() {
        XCTAssertNil(CornerGeometry.orderedQuadrilateral(from: [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 1)]))
        let duplicate = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 0, y: 0),
            CGPoint(x: 10, y: 0),
            CGPoint(x: 10, y: 10)
        ]
        XCTAssertNil(CornerGeometry.orderedQuadrilateral(from: duplicate))
    }

    func testVisionNormalizedPointsUseTopLeftPixels() {
        let quad = CornerGeometry.quadrilateral(
            fromVisionTopLeft: CGPoint(x: 0, y: 1),
            topRight: CGPoint(x: 1, y: 1),
            bottomRight: CGPoint(x: 1, y: 0),
            bottomLeft: CGPoint(x: 0, y: 0),
            imageSize: CGSize(width: 200, height: 100)
        )
        XCTAssertPointEqual(quad.topLeft, CGPoint(x: 0, y: 0))
        XCTAssertPointEqual(quad.topRight, CGPoint(x: 200, y: 0))
        XCTAssertPointEqual(quad.bottomRight, CGPoint(x: 200, y: 100))
        XCTAssertPointEqual(quad.bottomLeft, CGPoint(x: 0, y: 100))
    }

    func testClockwiseRotationTurnsFullFrameIntoTheNewFullFrame() {
        let size = CGSize(width: 100, height: 40)
        let rotated = CornerGeometry.rotatedClockwise(Quadrilateral.fullImage(size: size), imageSize: size)
        XCTAssertEqual(rotated.size, CGSize(width: 40, height: 100))
        let expected = Quadrilateral.fullImage(size: rotated.size)
        XCTAssertPointEqual(rotated.quad.topLeft, expected.topLeft)
        XCTAssertPointEqual(rotated.quad.topRight, expected.topRight)
        XCTAssertPointEqual(rotated.quad.bottomRight, expected.bottomRight)
        XCTAssertPointEqual(rotated.quad.bottomLeft, expected.bottomLeft)
    }

    func testCoreImageSpaceFlipsVerticalAxis() {
        let quad = Quadrilateral.fullImage(size: CGSize(width: 200, height: 100))
        let converted = quad.toCIImageSpace(imageHeight: 100)
        XCTAssertPointEqual(converted.topLeft, CGPoint(x: 0, y: 100))
        XCTAssertPointEqual(converted.topRight, CGPoint(x: 200, y: 100))
        XCTAssertPointEqual(converted.bottomRight, CGPoint(x: 200, y: 0))
        XCTAssertPointEqual(converted.bottomLeft, CGPoint(x: 0, y: 0))
    }

    func testClampAndFullImageDetection() {
        let size = CGSize(width: 50, height: 40)
        let outside = Quadrilateral(
            topLeft: CGPoint(x: -5, y: 2),
            topRight: CGPoint(x: 80, y: 3),
            bottomRight: CGPoint(x: 40, y: 90),
            bottomLeft: CGPoint(x: 4, y: 30)
        )
        let clamped = outside.clamped(to: size)
        XCTAssertPointEqual(clamped.topLeft, CGPoint(x: 0, y: 2))
        XCTAssertPointEqual(clamped.topRight, CGPoint(x: 50, y: 3))
        XCTAssertPointEqual(clamped.bottomRight, CGPoint(x: 40, y: 40))
        XCTAssertPointEqual(clamped.bottomLeft, CGPoint(x: 4, y: 30))
        XCTAssertTrue(Quadrilateral.fullImage(size: size).isApproximatelyFullImage(size: size))
        XCTAssertFalse(clamped.isApproximatelyFullImage(size: size))
    }

    func testSelfIntersectingQuadIsNotConvex() {
        let bowtie = Quadrilateral(
            topLeft: CGPoint(x: 0, y: 0),
            topRight: CGPoint(x: 0, y: 10),
            bottomRight: CGPoint(x: 10, y: 0),
            bottomLeft: CGPoint(x: 10, y: 10)
        )
        XCTAssertFalse(bowtie.isConvex(minArea: 1))
    }
}
