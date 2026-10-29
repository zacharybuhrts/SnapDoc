import Foundation

enum ImageSizing {
    /// Longest edge kept for editing and saved page images.
    static let workingMaxEdge: CGFloat = 2400
    static let thumbnailMaxEdge: CGFloat = 480

    static func fittedSize(pixelWidth: Int, pixelHeight: Int, maxEdge: CGFloat) -> CGSize {
        let width = CGFloat(max(pixelWidth, 0))
        let height = CGFloat(max(pixelHeight, 0))
        let longest = max(width, height)
        // A zero side or a non-positive limit is not a real resize.
        guard width > 0, height > 0, maxEdge > 0, longest > maxEdge else {
            return CGSize(width: floor(width), height: floor(height))
        }
        let scale = maxEdge / longest
        return CGSize(
            width: max(1, floor(width * scale)),
            height: max(1, floor(height * scale))
        )
    }
}
