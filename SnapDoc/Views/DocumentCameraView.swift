import SwiftUI
import VisionKit

struct DocumentCameraView: UIViewControllerRepresentable {
    var onComplete: ([UIImage]) -> Void
    var onCancel: () -> Void
    var onFailure: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete, onCancel: onCancel, onFailure: onFailure)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {
        context.coordinator.onComplete = onComplete
        context.coordinator.onCancel = onCancel
        context.coordinator.onFailure = onFailure
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var onComplete: ([UIImage]) -> Void
        var onCancel: () -> Void
        var onFailure: (String) -> Void

        init(
            onComplete: @escaping ([UIImage]) -> Void,
            onCancel: @escaping () -> Void,
            onFailure: @escaping (String) -> Void
        ) {
            self.onComplete = onComplete
            self.onCancel = onCancel
            self.onFailure = onFailure
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            var images: [UIImage] = []
            images.reserveCapacity(scan.pageCount)
            for index in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: index))
            }
            onComplete(images)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            onFailure(error.localizedDescription)
        }
    }
}
