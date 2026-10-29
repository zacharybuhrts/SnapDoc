import SwiftUI

@main
struct SnapDocApp: App {
    @State private var library = DocumentLibrary()

    var body: some Scene {
        WindowGroup {
            CaptureRootView()
                .environment(library)
                .preferredColorScheme(.dark)
        }
    }
}
