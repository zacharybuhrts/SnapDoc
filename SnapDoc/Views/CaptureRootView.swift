import PhotosUI
import SwiftUI
import UIKit
import VisionKit

struct ScanSessionRoute: Identifiable {
    let id = UUID()
    let model: ScanSessionModel
}

struct CaptureRootView: View {
    @Environment(DocumentLibrary.self) private var library
    @State private var showCamera = false
    @State private var didOfferCamera = false
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isPreparing = false
    @State private var sessionRoute: ScanSessionRoute?
    @State private var errorMessage: String?
    @State private var showCameraUnavailable = false

    private var recentScans: [SavedScan] {
        Array(library.scans.prefix(8))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                background
                VStack(alignment: .leading, spacing: 20) {
                    header
                    Spacer(minLength: 8)
                    viewfinder
                    if !VNDocumentCameraViewController.isSupported {
                        simulatorNote
                    }
                    actions
                    recentSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                if isPreparing {
                    preparingOverlay
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ScanRoute.self) { route in
                ScanDetailView(scanID: route.id)
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            DocumentCameraView(
                onComplete: { images in
                    showCamera = false
                    openSession(with: images)
                },
                onCancel: { showCamera = false },
                onFailure: { message in
                    showCamera = false
                    errorMessage = message
                }
            )
            .ignoresSafeArea()
        }
        .fullScreenCover(item: $sessionRoute) { route in
            ReviewScanView(model: route.model)
                .environment(library)
        }
        .task {
            library.reload()
            guard !didOfferCamera else { return }
            didOfferCamera = true
            if VNDocumentCameraViewController.isSupported && !RuntimeEnvironment.isRunningTests {
                showCamera = true
            }
        }
        .alert("Camera needs an iPhone", isPresented: $showCameraUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The document scanner uses the iPhone camera. On the simulator, import a photo instead.")
        }
        .alert("Couldn't open those pages", isPresented: errorIsPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private var background: some View {
        ZStack {
            SnapDocColor.background
            RadialGradient(
                colors: [
                    Color(red: 0.12, green: 0.24, blue: 0.42),
                    SnapDocColor.background
                ],
                center: .top,
                startRadius: 20,
                endRadius: 560
            )
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SnapDoc")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(SnapDocColor.textPrimary)
                Text("Scan a page, clean it up, keep it.")
                    .font(.subheadline)
                    .foregroundStyle(SnapDocColor.textSecondary)
            }
            Spacer()
            NavigationLink {
                GalleryView()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "rectangle.stack")
                        .font(.title3.weight(.semibold))
                    Text("\(library.scans.count)")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(SnapDocColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .accessibilityLabel("Library, \(library.scans.count) scans")
        }
        .padding(.top, 8)
    }

    private var viewfinder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(SnapDocColor.backgroundRaised.opacity(0.65))
            ViewfinderCorners()
                .stroke(SnapDocColor.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .padding(22)
            VStack(spacing: 10) {
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.white)
                Text("Position the page in the frame")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
    }

    private var simulatorNote: some View {
        Text("This simulator has no document camera. Import a photo to try cropping, filters, and saving. Scanning works on a real iPhone.")
            .font(.footnote)
            .foregroundStyle(SnapDocColor.textSecondary)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SnapDocColor.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                if VNDocumentCameraViewController.isSupported {
                    showCamera = true
                } else {
                    showCameraUnavailable = true
                }
            } label: {
                Label("Scan Document", systemImage: "camera.fill")
            }
            .buttonStyle(SnapDocPrimaryButtonStyle())
            .disabled(isPreparing)
            .accessibilityHint("Opens the camera and captures one or more pages")

            PhotosPicker(selection: $pickerItems, maxSelectionCount: 24, matching: .images) {
                Label("Import from Photos", systemImage: "photo.on.rectangle.angled")
            }
            .buttonStyle(SnapDocSecondaryButtonStyle())
            .disabled(isPreparing)
            .onChange(of: pickerItems) { _, items in
                guard !items.isEmpty else { return }
                let batch = items
                pickerItems = []
                Task { await importPhotos(batch) }
            }
        }
    }

    @ViewBuilder
    private var recentSection: some View {
        if recentScans.isEmpty {
            Text("Saved scans show up here and in the library.")
                .font(.footnote)
                .foregroundStyle(SnapDocColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Recent")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SnapDocColor.textSecondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recentScans) { scan in
                            NavigationLink(value: ScanRoute(id: scan.id)) {
                                recentCard(scan)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func recentCard(_ scan: SavedScan) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            FileThumbnail(url: library.thumbnailURL(for: scan.id))
                .frame(width: 92, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(scan.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(width: 92, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(scan.name), \(scan.format.title)")
    }

    private var preparingOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .tint(.white)
                Text("Preparing pages…")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func importPhotos(_ items: [PhotosPickerItem]) async {
        isPreparing = true
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        guard !images.isEmpty else {
            isPreparing = false
            errorMessage = "Couldn't read those photos. Try different images."
            return
        }
        let pages = await ScanSessionBuilder.makePagesOffMain(from: images)
        isPreparing = false
        guard !pages.isEmpty else {
            errorMessage = "Couldn't prepare those pages."
            return
        }
        sessionRoute = ScanSessionRoute(model: ScanSessionModel(pages: pages))
    }

    private func openSession(with images: [UIImage]) {
        guard !images.isEmpty else { return }
        isPreparing = true
        Task {
            let pages = await ScanSessionBuilder.makePagesOffMain(from: images)
            isPreparing = false
            guard !pages.isEmpty else {
                errorMessage = "Couldn't prepare those pages."
                return
            }
            sessionRoute = ScanSessionRoute(model: ScanSessionModel(pages: pages))
        }
    }
}

private struct ViewfinderCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let length = min(36, min(rect.width, rect.height) / 4)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))

        path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))

        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - length, y: rect.maxY))

        path.move(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - length))
        return path
    }
}
