import SwiftUI
import UIKit

struct FileThumbnail: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            SnapDocColor.paper
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "doc")
                    .font(.title2)
                    .foregroundStyle(.gray)
            }
        }
        .task(id: url) {
            image = UIImage(contentsOfFile: url.path)
        }
    }
}
