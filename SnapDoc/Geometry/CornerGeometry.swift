import Foundation

enum CornerGeometry {
    /// Orders four points as top-left, top-right, bottom-right, bottom-left.
    ///
    /// The origin is top-left. Returns nil when the points do not form a convex page.
    static func orderedQuadrilateral(from points: [CGPoint]) -> Quadrilateral? {
        guard points.count == 4 else { return nil }

        let topLeft = points.min { ($0.x + $0.y) < ($1.x + $1.y) }!
        let bottomRight = points.max { ($0.x + $0.y) < ($1.x + $1.y) }!
        if pointsAreEqual(topLeft, bottomRight) {
            return nil
        }

        let remaining = points.filter { point in
            !pointsAreEqual(point, topLeft) && !pointsAreEqual(point, bottomRight)
        }
        guard remaining.count == 2 else { return nil }

        let topRight = remaining.max { $0.x < $1.x }!
        let bottomLeft = remaining.min { $0.x < $1.x }!
        if pointsAreEqual(topRight, bottomLeft) {
            return nil
        }

        let quad = Quadrilateral(
            topLeft: topLeft,
            topRight: topRight,
            bottomRight: bottomRight,
            bottomLeft: bottomLeft
        )
        return quad.isConvex(minArea: 0.01) ? quad : nil
    }

    /// Vision rectangle points are normalized with a bottom-left origin.
    static func quadrilateral(
        fromVisionTopLeft topLeft: CGPoint,
        topRight: CGPoint,
        bottomRight: CGPoint,
        bottomLeft: CGPoint,
        imageSize: CGSize
    ) -> Quadrilateral {
        func convert(_ point: CGPoint) -> CGPoint {
            CGPoint(
                x: point.x * imageSize.width,
                y: (1 - point.y) * imageSize.height
            )
        }
        return Quadrilateral(
            topLeft: convert(topLeft),
            topRight: convert(topRight),
            bottomRight: convert(bottomRight),
            bottomLeft: convert(bottomLeft)
        )
    }

    /// Rotates corners 90 degrees clockwise and swaps the image dimensions.
    static func rotatedClockwise(
        _ quad: Quadrilateral,
        imageSize: CGSize
    ) -> (quad: Quadrilateral, size: CGSize) {
        func rotate(_ point: CGPoint) -> CGPoint {
            CGPoint(x: imageSize.height - point.y, y: point.x)
        }
        let rotated = Quadrilateral(
            topLeft: rotate(quad.bottomLeft),
            topRight: rotate(quad.topLeft),
            bottomRight: rotate(quad.topRight),
            bottomLeft: rotate(quad.bottomRight)
        )
        return (rotated, CGSize(width: imageSize.height, height: imageSize.width))
    }

    private static func pointsAreEqual(_ lhs: CGPoint, _ rhs: CGPoint) -> Bool {
        abs(lhs.x - rhs.x) < 0.001 && abs(lhs.y - rhs.y) < 0.001
    }
}
