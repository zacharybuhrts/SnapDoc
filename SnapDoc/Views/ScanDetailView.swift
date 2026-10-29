import SwiftUI
import UIKit

struct ScanDetailView: View {
    @Environment(DocumentLibrary.self) private var library
    @Environment(\.dismiss) private var dismiss
    let scanID: UUID

    @State private var pageImages: [UIImage] = []
    @State private var pageIndex = 0
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var showRename = false
    @State private var renameText = ""
    @State private var confirmDelete = false
    @State private var sharePayload: SharePayload?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let scan = library.scan(id: scanID) {
                detail(for: scan)
            } else if isLoading {
                ProgressView("Opening scan…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "Scan Unavailable",
                    systemImage: "doc.questionmark",
                    description: Text(loadError ?? "It may have been deleted.")
                )
            }
        }
        .background(SnapDocColor.background.ignoresSafeArea())
        .navigationTitle(library.scan(id: scanID)?.name ?? "Scan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if library.scan(id: scanID) != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            share()
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            renameText = library.scan(id: scanID)?.name ?? ""
                            showRename = true
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Scan actions")
                }
            }
        }
        .task(id: scanID) { await loadPages() }
        .sheet(item: $sharePayload) { payload in
            ActivityShareSheet(items: payload.urls)
                .ignoresSafeArea()
        }
        .alert("Rename Scan", isPresented: $showRename) {
            TextField("Name", text: $renameText)
            Button("Save") { commitRename() }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Delete this scan?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteScan() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the file from this iPhone.")
        }
        .alert("Couldn't update the scan", isPresented: errorIsPresented) {
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

    @ViewBuilder
    private func detail(for scan: SavedScan) -> some View {
        VStack(spacing: 12) {
            if isLoading && pageImages.isEmpty {
                ProgressView("Opening scan…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if pageImages.isEmpty {
                ContentUnavailableView(
                    "Couldn't Open Pages",
                    systemImage: "doc.questionmark",
                    description: Text(loadError ?? "The saved pages couldn't be read.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TabView(selection: $pageIndex) {
                    ForEach(Array(pageImages.enumerated()), id: \.offset) { index, image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(SnapDocColor.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 16)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: pageImages.count > 1 ? .automatic : .never))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(scan.createdAt.formatted(date: .abbreviated, time: .shortened))
                Text("\(scan.format.title) · \(scan.pageCount) \(scan.pageCount == 1 ? "page" : "pages")")
            }
            .font(.subheadline)
            .foregroundStyle(SnapDocColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            if let loadError, !pageImages.isEmpty {
                Text(loadError)
                    .font(.caption)
                    .foregroundStyle(SnapDocColor.danger)
                    .padding(.horizontal, 20)
            }
        }
    }

    private func loadPages() async {
        isLoading = true
        do {
            let urls = try library.pageURLs(for: scanID)
            let images = urls.compactMap { UIImage(contentsOfFile: $0.path) }
            pageImages = images
            if images.isEmpty {
                loadError = "The saved pages couldn't be opened."
            } else {
                loadError = nil
            }
        } catch {
            pageImages = []
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    private func share() {
        do {
            let urls = try library.shareURLs(for: scanID)
            sharePayload = SharePayload(urls: urls)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func commitRename() {
        do {
            try library.rename(id: scanID, to: renameText)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteScan() {
        do {
            try library.delete(id: scanID)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
