import SwiftUI

struct GalleryView: View {
    @Environment(DocumentLibrary.self) private var library
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var renameTarget: SavedScan?
    @State private var renameText = ""
    @State private var deleteTarget: SavedScan?
    @State private var sharePayload: SharePayload?
    @State private var errorMessage: String?

    private let columns = [GridItem(.adaptive(minimum: 156), spacing: 14)]

    private var filteredScans: [SavedScan] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return library.scans }
        return library.scans.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    var body: some View {
        Group {
            if library.scans.isEmpty {
                ContentUnavailableView {
                    Label("No Scans Yet", systemImage: "doc.viewfinder")
                } description: {
                    Text("Scan a document or import a photo. It will show up here.")
                } actions: {
                    Button("Back to Camera") { dismiss() }
                        .buttonStyle(.borderedProminent)
                }
            } else if filteredScans.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(filteredScans) { scan in
                            NavigationLink(value: ScanRoute(id: scan.id)) {
                                scanCard(scan)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    share(scan)
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                Button {
                                    renameText = scan.name
                                    renameTarget = scan
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    deleteTarget = scan
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(SnapDocColor.background.ignoresSafeArea())
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $query, prompt: "Search scans")
        .navigationDestination(for: ScanRoute.self) { route in
            ScanDetailView(scanID: route.id)
        }
        .refreshable { library.reload() }
        .sheet(item: $sharePayload) { payload in
            ActivityShareSheet(items: payload.urls)
                .ignoresSafeArea()
        }
        .alert("Rename Scan", isPresented: renameIsPresented) {
            TextField("Name", text: $renameText)
            Button("Save") { commitRename() }
            Button("Cancel", role: .cancel) { renameTarget = nil }
        }
        .confirmationDialog(
            "Delete this scan?",
            isPresented: deleteIsPresented,
            titleVisibility: .visible,
            presenting: deleteTarget
        ) { scan in
            Button("Delete \(scan.name)", role: .destructive) {
                delete(scan)
            }
            Button("Cancel", role: .cancel) {}
        } message: { scan in
            Text("\(scan.name) will be removed from this iPhone.")
        }
        .alert("Couldn't update the library", isPresented: errorIsPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear { library.reload() }
    }

    private var renameIsPresented: Binding<Bool> {
        Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )
    }

    private var deleteIsPresented: Binding<Bool> {
        Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        )
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func scanCard(_ scan: SavedScan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            FileThumbnail(url: library.thumbnailURL(for: scan.id))
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(alignment: .topLeading) {
                    Text(scan.format.title)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.6), in: Capsule())
                        .foregroundStyle(.white)
                        .padding(8)
                }
            Text(scan.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
            Text(scan.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(SnapDocColor.textSecondary)
            Text("\(scan.pageCount) \(scan.pageCount == 1 ? "page" : "pages")")
                .font(.caption2)
                .foregroundStyle(SnapDocColor.textSecondary)
        }
        .padding(10)
        .background(SnapDocColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func share(_ scan: SavedScan) {
        do {
            let urls = try library.shareURLs(for: scan.id)
            sharePayload = SharePayload(urls: urls)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func commitRename() {
        guard let target = renameTarget else { return }
        do {
            try library.rename(id: target.id, to: renameText)
            renameTarget = nil
        } catch {
            renameTarget = nil
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ scan: SavedScan) {
        do {
            try library.delete(id: scan.id)
            deleteTarget = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
