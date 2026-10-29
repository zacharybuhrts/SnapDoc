import UIKit

/// One page in the review session, before it is written to disk.
///
/// `source` is orientation-up and already limited to a working pixel size.
/// Corners are in that image's pixel space, origin top-left.
struct EditablePage: Identifiable, @unchecked Sendable {
    let id: UUID
    var source: UIImage
    var pixelSize: CGSize
    var corners: Quadrilateral
    var detectedCorners: Quadrilateral
    var mode: EnhancementMode

    init(
        id: UUID = UUID(),
        source: UIImage,
        pixelSize: CGSize,
        corners: Quadrilateral,
        detectedCorners: Quadrilateral,
        mode: EnhancementMode
    ) {
        self.id = id
        self.source = source
        self.pixelSize = pixelSize
        self.corners = corners
        self.detectedCorners = detectedCorners
        self.mode = mode
    }
}
