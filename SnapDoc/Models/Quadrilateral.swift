import Foundation

enum DocumentCorner: CaseIterable, Sendable {
    case topLeft
    case topRight
    case bottomRight
    case bottomLeft
}

/// Page corners in image pixels. The origin is the top-left, matching UIKit.
struct Quadrilateral: Equatable, Hashable, Codable, Sendable {
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomRight: CGPoint
    var bottomLeft: CGPoint

    static func fullImage(size: CGSize) -> Quadrilateral {
        Quadrilateral(
            topLeft: .zero,
            topRight: CGPoint(x: size.width, y: 0),
            bottomRight: CGPoint(x: size.width, y: size.height),
            bottomLeft: CGPoint(x: 0, y: size.height)
        )
    }

    subscript(corner: DocumentCorner) -> CGPoint {
        get {
            switch corner {
            case .topLeft: return topLeft
            case .topRight: return topRight
            case .bottomRight: return bottomRight
            case .bottomLeft: return bottomLeft
            }
        }
        set {
            switch corner {
            case .topLeft: topLeft = newValue
            case .topRight: topRight = newValue
            case .bottomRight: bottomRight = newValue
            case .bottomLeft: bottomLeft = newValue
            }
        }
    }

    func clamped(to size: CGSize) -> Quadrilateral {
        func clamp(_ point: CGPoint) -> CGPoint {
            CGPoint(
                x: min(max(0, point.x), max(0, size.width)),
                y: min(max(0, point.y), max(0, size.height))
            )
        }
        return Quadrilateral(
            topLeft: clamp(topLeft),
            topRight: clamp(topRight),
            bottomRight: clamp(bottomRight),
            bottomLeft: clamp(bottomLeft)
        )
    }

    func moving(_ corner: DocumentCorner, to point: CGPoint, in size: CGSize) -> Quadrilateral {
        var copy = self
        copy[corner] = CGPoint(
            x: min(max(0, point.x), max(0, size.width)),
            y: min(max(0, point.y), max(0, size.height))
        )
        return copy
    }

    func isApproximatelyFullImage(size: CGSize, tolerance: CGFloat = 1.5) -> Bool {
        let full = Self.fullImage(size: size)
        return Self.distance(topLeft, full.topLeft) <= tolerance
            && Self.distance(topRight, full.topRight) <= tolerance
            && Self.distance(bottomRight, full.bottomRight) <= tolerance
            && Self.distance(bottomLeft, full.bottomLeft) <= tolerance
    }

    /// Core Image uses a bottom-left origin. `imageHeight` is the pixel height.
    func toCIImageSpace(imageHeight: CGFloat) -> Quadrilateral {
        func convert(_ point: CGPoint) -> CGPoint {
            CGPoint(x: point.x, y: imageHeight - point.y)
        }
        return Quadrilateral(
            topLeft: convert(topLeft),
            topRight: convert(topRight),
            bottomRight: convert(bottomRight),
            bottomLeft: convert(bottomLeft)
        )
    }

    var signedArea: CGFloat {
        let points = [topLeft, topRight, bottomRight, bottomLeft]
        var sum: CGFloat = 0
        for index in 0..<points.count {
            let current = points[index]
            let next = points[(index + 1) % points.count]
            sum += current.x * next.y - next.x * current.y
        }
        return sum / 2
    }

    /// True when the corners go around the page in one direction and enclose enough pixels.
    func isConvex(minArea: CGFloat = 32) -> Bool {
        let points = [topLeft, topRight, bottomRight, bottomLeft]
        var sign: CGFloat = 0
        for index in 0..<points.count {
            let a = points[index]
            let b = points[(index + 1) % points.count]
            let c = points[(index + 2) % points.count]
            let cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x)
            if abs(cross) <= 0.0001 {
                return false
            }
            if sign == 0 {
                sign = cross
            } else if sign * cross < 0 {
                return false
            }
        }
        return abs(signedArea) >= minArea
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return (dx * dx + dy * dy).squareRoot()
    }
}
