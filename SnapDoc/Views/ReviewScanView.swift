import SwiftUI

struct ReviewScanView: View {
    @Environment(DocumentLibrary.self) private var library
    @Environment(\.dismiss) private var dismiss
    @Bindable var model: ScanSessionModel

    @State private var showCorners = false
    @State private var showSave = false
    @State private var confirmDelete = false
    @State private var savedScan: SavedScan?
    @State private var showSavedAlert = false
    @State private var sharePayload: SharePayload?
    @State private var savedCount = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                preview
                pageStrip
                filterRow
                editRow
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .background(SnapDocColor.background.ignoresSafeArea())
            .navigationTitle(pageTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { showSave = true }
                        .disabled(model.pages.isEmpty)
                }
            }
        }
        .fullScreenCover(isPresented: $showCorners) {
            CornerEditorView(model: model)
        }
        .sheet(isPresented: $showSave) {
            SaveScanSheet(model: model) { scan in
                showSave = false
                savedScan = scan
                savedCount += 1
                showSavedAlert = true
            }
            .environment(library)
        }
        .sheet(item: $sharePayload) { payload in
            ActivityShareSheet(items: payload.urls)
                .ignoresSafeArea()
        }
        .confirmationDialog(
            model.pages.count <= 1 ? "Discard this scan?" : "Remove this page?",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button(model.pages.count <= 1 ? "Discard" : "Remove Page", role: .destructive) {
                let wasLast = model.pages.count <= 1
                model.deleteSelected()
                if wasLast { dismiss() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Saved", isPresented: $showSavedAlert) {
            Button("Share") { shareSavedScan() }
            Button("Done", role: .cancel) {}
        } message: {
            Text("\(savedScan?.name ?? "Scan") is in your library. You can share it again from there.")
        }
        .sensoryFeedback(.success, trigger: savedCount)
    }

    private var pageTitle: String {
        guard !model.pages.isEmpty else { return "Review" }
        return "Page \(model.selectedIndex + 1) of \(model.pages.count)"
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SnapDocColor.paper)
            if let image = model.previewImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(10)
            }
            if model.isRendering {
                ProgressView()
                    .controlSize(.large)
                    .tint(SnapDocColor.accent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Enhanced page preview")
    }

    private var pageStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(model.pages.enumerated()), id: \.element.id) { index, page in
                    Button {
                        model.select(id: page.id)
                    } label: {
                        Image(uiImage: page.source)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 52, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(
                                        page.id == model.selectedPageID ? SnapDocColor.accent : Color.clear,
                                        lineWidth: 3
                                    )
                            }
                            .overlay(alignment: .bottomTrailing) {
                                Text("\(index + 1)")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(.black.opacity(0.55), in: Capsule())
                                    .foregroundStyle(.white)
                                    .padding(4)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Page \(index + 1)")
                    .accessibilityAddTraits(page.id == model.selectedPageID ? .isSelected : [])
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(EnhancementMode.allCases) { mode in
                    FilterChip(
                        title: mode.title,
                        isSelected: model.selectedPage?.mode == mode
                    ) {
                        model.setMode(mode)
                    }
                }
            }
        }
        .accessibilityLabel("Enhancement")
    }

    private var editRow: some View {
        HStack(spacing: 10) {
            reviewButton("Crop", systemImage: "crop") { showCorners = true }
            reviewButton("Rotate", systemImage: "rotate.right") { model.rotateSelectedClockwise() }
            reviewButton("Earlier", systemImage: "chevron.left") { model.moveSelected(offset: -1) }
                .disabled(model.selectedIndex == 0)
            reviewButton("Later", systemImage: "chevron.right") { model.moveSelected(offset: 1) }
                .disabled(model.selectedIndex >= model.pages.count - 1)
            reviewButton("Delete", systemImage: "trash") { confirmDelete = true }
        }
    }

    private func reviewButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                Text(title)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(SnapDocColor.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func shareSavedScan() {
        guard let savedScan else { return }
        do {
            let urls = try library.shareURLs(for: savedScan.id)
            sharePayload = SharePayload(urls: urls)
        } catch {
            sharePayload = nil
        }
    }
}
