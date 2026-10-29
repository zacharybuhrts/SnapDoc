import SwiftUI

struct CornerEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var model: ScanSessionModel
    @State private var draft: Quadrilateral?
    @State private var dragOrigin: Quadrilateral?
    @State private var activeCorner: DocumentCorner?
    @State private var detectMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Drag the corners onto the edges of the page. The area outside the box is cropped away.")
                    .font(.footnote)
                    .foregroundStyle(SnapDocColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let page = model.selectedPage {
                    editor(for: page)
                }

                if let detectMessage {
                    Text(detectMessage)
                        .font(.caption)
                        .foregroundStyle(SnapDocColor.textSecondary)
                }

                HStack(spacing: 10) {
                    toolButton("Detect", systemImage: "viewfinder") { detect() }
                    toolButton("Full Page", systemImage: "rectangle") { useFullPage() }
                }
            }
            .padding(16)
            .background(SnapDocColor.background.ignoresSafeArea())
            .navigationTitle("Adjust Crop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { apply() }
                        .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            if draft == nil {
                draft = model.selectedPage?.corners
            }
        }
    }

    @ViewBuilder
    private func editor(for page: EditablePage) -> some View {
        let corners = draft ?? page.corners
        GeometryReader { geo in
            let viewport = ImageViewport(imageSize: page.pixelSize, viewSize: geo.size)
            ZStack {
                SnapDocColor.backgroundRaised
                Image(uiImage: page.source)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)
                Canvas { context, size in
                    var path = Path(CGRect(origin: .zero, size: size))
                    path.addPath(quadPath(viewport: viewport, corners: corners))
                    context.fill(path, with: .color(.black.opacity(0.55)), style: FillStyle(eoFill: true))
                    context.stroke(
                        quadPath(viewport: viewport, corners: corners),
                        with: .color(SnapDocColor.accent),
                        lineWidth: 2
                    )
                }
                .allowsHitTesting(false)

                ForEach(DocumentCorner.allCases, id: \.self) { corner in
                    Circle()
                        .fill(.white)
                        .overlay {
                            Circle().stroke(SnapDocColor.accent, lineWidth: 3)
                        }
                        .frame(width: 22, height: 22)
                        .position(viewport.viewPoint(fromImage: corners[corner]))
                        .allowsHitTesting(false)
                }
            }
            .coordinateSpace(name: "editor")
            .contentShape(Rectangle())
            .gesture(dragGesture(viewport: viewport, page: page, corners: corners))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func dragGesture(viewport: ImageViewport, page: EditablePage, corners: Quadrilateral) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("editor"))
            .onChanged { value in
                if activeCorner == nil {
                    let origin = draft ?? corners
                    activeCorner = hitCorner(at: value.startLocation, viewport: viewport, corners: origin)
                    dragOrigin = origin
                }
                guard let activeCorner, let dragOrigin else { return }
                let imagePoint = viewport.imagePoint(fromView: value.location)
                let candidate = dragOrigin.moving(activeCorner, to: imagePoint, in: page.pixelSize)
                if candidate.isConvex() {
                    draft = candidate
                }
            }
            .onEnded { _ in
                activeCorner = nil
                dragOrigin = nil
            }
    }

    private func quadPath(viewport: ImageViewport, corners: Quadrilateral) -> Path {
        var path = Path()
        let points = DocumentCorner.allCases.map { viewport.viewPoint(fromImage: corners[$0]) }
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }

    private func hitCorner(at location: CGPoint, viewport: ImageViewport, corners: Quadrilateral) -> DocumentCorner? {
        let hits = DocumentCorner.allCases.map { corner -> (DocumentCorner, CGFloat) in
            let point = viewport.viewPoint(fromImage: corners[corner])
            let dx = point.x - location.x
            let dy = point.y - location.y
            return (corner, dx * dx + dy * dy)
        }
        guard let nearest = hits.min(by: { $0.1 < $1.1 }), nearest.1 <= 44 * 44 else {
            return nil
        }
        return nearest.0
    }

    private func toolButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(SnapDocColor.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    private func detect() {
        guard let page = model.selectedPage, let cgImage = page.source.cgImage else { return }
        if let found = PageRectangleDetector.detectCorners(in: cgImage) {
            let clamped = found.clamped(to: page.pixelSize)
            draft = clamped.isConvex() ? clamped : Quadrilateral.fullImage(size: page.pixelSize)
            detectMessage = "Corners updated from the detected page."
        } else {
            draft = Quadrilateral.fullImage(size: page.pixelSize)
            detectMessage = "No page was detected. The crop is set to the full image."
        }
    }

    private func useFullPage() {
        guard let page = model.selectedPage else { return }
        draft = Quadrilateral.fullImage(size: page.pixelSize)
        detectMessage = nil
    }

    private func apply() {
        if let draft {
            model.setCorners(draft)
        }
        dismiss()
    }
}
