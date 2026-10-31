//
//  DocumentListView.swift
//  MontaPDF
//

import PhotosUI
import SwiftUI

struct DocumentListView: View {
    @Bindable var viewModel: DocumentListViewModel
    @Bindable var scanner: ScannerViewModel
    let importer: ImportViewModel
    let onShowAccount: () -> Void
    @Environment(\.openURL) private var openURL
    @State private var path: [UUID] = []
    @State private var isFileImporterPresented = false
    @State private var isPhotoPickerPresented = false
    @State private var photoSelection: [PhotosPickerItem] = []

    init(
        viewModel: DocumentListViewModel,
        scanner: ScannerViewModel,
        importer: ImportViewModel,
        onShowAccount: @escaping () -> Void = {}
    ) {
        _viewModel = Bindable(viewModel)
        _scanner = Bindable(scanner)
        self.importer = importer
        self.onShowAccount = onShowAccount
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("My Documents")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Files", systemImage: "folder") {
                                isFileImporterPresented = true
                            }
                            Button("Photos", systemImage: "photo.on.rectangle") {
                                isPhotoPickerPresented = true
                            }
                        } label: {
                            Label("Import", systemImage: "square.and.arrow.down")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: onShowAccount) {
                            Label("Account", systemImage: "person.crop.circle")
                        }
                    }
                }
                .fileImporter(
                    isPresented: $isFileImporterPresented,
                    allowedContentTypes: ImportKind.supportedTypes,
                    allowsMultipleSelection: true
                ) { result in
                    if case .success(let urls) = result {
                        Task { await importer.importFiles(at: urls) }
                    }
                }
                .photosPicker(
                    isPresented: $isPhotoPickerPresented,
                    selection: $photoSelection,
                    maxSelectionCount: 30,
                    selectionBehavior: .ordered,
                    matching: .images
                )
                .onChange(of: photoSelection) { _, items in
                    guard !items.isEmpty else { return }
                    photoSelection = []
                    Task { await importPhotos(items) }
                }
                .sheet(item: importPreview) { preview in
                    ImportPreviewView(
                        preview: preview,
                        onSave: { importer.savePreview() },
                        onKeepOriginal: { importer.keepOriginal() },
                        onCancel: { importer.cancelPreview() }
                    )
                }
                .alert(
                    importAlertTitle(importer.alert),
                    isPresented: isImportAlertPresented,
                    presenting: importer.alert
                ) { alert in
                    if alert == .conversionFailed {
                        Button("Keep Original") { importer.keepOriginal() }
                        Button("Cancel", role: .cancel) { importer.cancelPreview() }
                    } else {
                        Button("OK", role: .cancel) {}
                    }
                } message: { alert in
                    switch alert {
                    case .unsupported: Text("Send an image, a PDF or a Word file.")
                    case .conversionFailed: Text("You can keep the original file and share it as it is.")
                    case .failed: Text("Please try again.")
                    }
                }
                .confirmationDialog(
                    "Share as",
                    isPresented: $viewModel.isChoosingShareFormat,
                    titleVisibility: .visible
                ) {
                    Button("PDF") { viewModel.shareChosen(.pdf) }
                    Button("Original File") { viewModel.shareChosen(.original) }
                    Button("Cancel", role: .cancel) {}
                }
                .overlay(alignment: .bottom) { bottomBar }
                .overlay {
                    if scanner.isSaving || importer.isConverting {
                        SavingOverlay()
                    }
                }
                .fullScreenCover(isPresented: $scanner.isScannerPresented) {
                    DocumentScannerView(
                        onFinish: { pages in
                            Task { await scanner.scannerFinished(with: pages) }
                        },
                        onCancel: { scanner.scannerCancelled() },
                        onError: { error in scanner.scannerFailed(error) }
                    )
                    .ignoresSafeArea()
                }
                .navigationDestination(for: UUID.self) { id in
                    DocumentViewerView(viewModel: viewModel.makeViewerViewModel(for: id))
                }
                .renameDocumentAlert(
                    isPresented: $viewModel.isRenaming,
                    name: $viewModel.renameDraft
                ) { _ in
                    viewModel.confirmRename()
                }
                .deleteDocumentAlert(
                    isPresented: $viewModel.isConfirmingDelete,
                    title: viewModel.deleteTarget?.title ?? ""
                ) {
                    viewModel.confirmDelete()
                }
                .sheet(item: $viewModel.shareItem) { item in
                    ActivityView(items: [item.url])
                        .presentationDetents([.medium, .large])
                }
                .onAppear {
                    viewModel.load()
                }
                .alert(
                    scannerAlertTitle(scanner.alert),
                    isPresented: isScannerAlertPresented,
                    presenting: scanner.alert
                ) { alert in
                    scannerAlertActions(alert)
                } message: { alert in
                    scannerAlertMessage(alert)
                }
                .alert(
                    "Something went wrong",
                    isPresented: isErrorPresented
                ) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.rows.isEmpty {
            ContentUnavailableView {
                Label("Do you want to capture a document?", systemImage: "doc.viewfinder")
            } description: {
                Text("Scan paper documents and keep them as PDFs, synced with iCloud.")
            } actions: {
                Button {
                    Task { await scanner.scanTapped() }
                } label: {
                    Label("Scan", systemImage: "camera")
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("or import a file") {
                    isFileImporterPresented = true
                }
            }
        } else {
            List {
                ForEach(viewModel.rows) { row in
                    NavigationLink(value: row.id) {
                        DocumentRowView(row: row) {
                            await viewModel.thumbnail(for: row.id)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            viewModel.startDelete(id: row.id)
                        }
                        Button("Rename", systemImage: "pencil") {
                            viewModel.startRename(id: row.id)
                        }
                        .tint(.orange)
                    }
                    .contextMenu {
                        Button("Open", systemImage: "doc.text") {
                            path.append(row.id)
                        }
                        Button("Rename", systemImage: "pencil") {
                            viewModel.startRename(id: row.id)
                        }
                        Button("Share", systemImage: "square.and.arrow.up") {
                            viewModel.share(id: row.id)
                        }
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            viewModel.startDelete(id: row.id)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 88)
            }
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        VStack(spacing: 12) {
            if let banner = viewModel.savedBanner {
                SavedBannerView(
                    banner: banner,
                    onRename: { viewModel.startRename(id: banner.id) },
                    onDismiss: { viewModel.dismissBanner() }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if !viewModel.rows.isEmpty {
                ScanButton {
                    Task { await scanner.scanTapped() }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .animation(.default, value: viewModel.savedBanner)
    }

    // MARK: - Import

    private func importPhotos(_ items: [PhotosPickerItem]) async {
        var photos: [Data] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                photos.append(data)
            }
        }
        await importer.importPhotos(photos)
    }

    private var importPreview: Binding<ImportPreview?> {
        Binding(
            get: { importer.preview },
            set: { importer.preview = $0 }
        )
    }

    private var isImportAlertPresented: Binding<Bool> {
        Binding(
            get: { importer.alert != nil },
            set: { if !$0 { importer.alert = nil } }
        )
    }

    private func importAlertTitle(_ alert: ImportAlert?) -> Text {
        switch alert ?? .failed {
        case .unsupported: Text("Unsupported format")
        case .conversionFailed: Text("Couldn't convert this document")
        case .failed: Text("Couldn't import the file")
        }
    }

    // MARK: - Alerts

    private var isErrorPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private var isScannerAlertPresented: Binding<Bool> {
        Binding(
            get: { scanner.alert != nil },
            set: { if !$0 { scanner.alert = nil } }
        )
    }

    private func scannerAlertTitle(_ alert: ScannerAlert?) -> Text {
        switch alert ?? .failed("") {
        case .scannerUnavailable: Text("Scanner unavailable")
        case .cameraDenied: Text("Camera access needed")
        case .saveFailed: Text("Couldn't save. Please try again.")
        case .failed: Text("Something went wrong")
        }
    }

    @ViewBuilder
    private func scannerAlertActions(_ alert: ScannerAlert) -> some View {
        switch alert {
        case .cameraDenied:
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        case .saveFailed:
            Button("Try Again") {
                Task { await scanner.retrySave() }
            }
            Button("Discard", role: .destructive) {
                scanner.discardPendingPages()
            }
        case .scannerUnavailable, .failed:
            Button("OK", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func scannerAlertMessage(_ alert: ScannerAlert) -> some View {
        switch alert {
        case .scannerUnavailable: Text("This device can't scan documents.")
        case .cameraDenied: Text("Allow camera access in Settings to scan your documents.")
        case .saveFailed: Text("Your scanned pages were kept.")
        case .failed(let message): Text(message)
        }
    }
}

private struct DocumentRowView: View {
    let row: DocumentRow
    let loadThumbnail: () async -> UIImage?
    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 44, height: 58)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(.separator), lineWidth: 0.5))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(.headline)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(row.createdAt, format: .dateTime.day().month().year())
                    if row.hasPDF || !row.hasOriginal {
                        Text("\(row.pageCount) pages")
                    } else {
                        Text("Original file")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .task(id: row.id) {
            thumbnail = await loadThumbnail()
        }
    }
}

private struct ScanButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Scan", systemImage: "camera.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .shadow(radius: 4, y: 2)
    }
}

private struct SavedBannerView: View {
    let banner: SavedBanner
    let onRename: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("\(banner.title) saved")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Spacer()
            Button("Rename", action: onRename)
                .font(.subheadline.weight(.semibold))
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .task(id: banner.id) {
            try? await Task.sleep(for: .seconds(5))
            onDismiss()
        }
    }
}

private struct SavingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.2).ignoresSafeArea()
            ProgressView("Building your PDF...")
                .padding(24)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
