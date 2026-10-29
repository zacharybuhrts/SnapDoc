import SwiftUI

struct SaveScanSheet: View {
    @Environment(DocumentLibrary.self) private var library
    @Environment(\.dismiss) private var dismiss
    @Bindable var model: ScanSessionModel
    var onSaved: (SavedScan) -> Void

    @State private var format: ExportFormat = .pdf
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Name")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SnapDocColor.textSecondary)
                TextField("Scan name", text: $model.name)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .padding(14)
                    .background(SnapDocColor.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(.white)

                Text("Format")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SnapDocColor.textSecondary)
                Picker("Format", selection: $format) {
                    ForEach(ExportFormat.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                Text(pageSummary)
                    .font(.footnote)
                    .foregroundStyle(SnapDocColor.textSecondary)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(SnapDocColor.danger)
                }

                Spacer()

                Button {
                    save()
                } label: {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Save to Library")
                    }
                }
                .buttonStyle(SnapDocPrimaryButtonStyle())
                .disabled(isSaving || model.pages.isEmpty)
            }
            .padding(20)
            .background(SnapDocColor.background.ignoresSafeArea())
            .navigationTitle("Save Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
    }

    private var pageSummary: String {
        let count = model.pages.count
        let pages = count == 1 ? "1 page" : "\(count) pages"
        switch format {
        case .pdf:
            return "\(pages) will be saved as one PDF."
        case .jpeg:
            return "\(pages) will be saved as JPEG images."
        case .png:
            return "\(pages) will be saved as PNG images."
        }
    }

    private func save() {
        let format = format
        let pages = model.pages
        let requestedName = ScanNaming.cleaned(model.name) ?? ScanNaming.defaultTitle(for: Date())
        model.name = requestedName
        isSaving = true
        errorMessage = nil
        Task {
            do {
                let draft = try await Task.detached(priority: .userInitiated) {
                    try ScanExporter.draft(name: requestedName, format: format, pages: pages)
                }.value
                let saved = try library.save(draft)
                isSaving = false
                onSaved(saved)
            } catch {
                isSaving = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
