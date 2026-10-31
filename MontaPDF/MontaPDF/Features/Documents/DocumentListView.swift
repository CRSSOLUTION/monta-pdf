//
//  DocumentListView.swift
//  MontaPDF
//

import SwiftUI

struct DocumentListView: View {
    @Bindable var viewModel: DocumentListViewModel
    @Bindable var scanner: ScannerViewModel
    let importer: ImportViewModel
    let makeViewer: (UUID) -> DocumentViewerViewModel
    let onShowAccount: () -> Void
    @State private var path: [UUID] = []
    @State private var isFileImporterPresented = false
    @State private var isPhotoPickerPresented = false

    init(
        viewModel: DocumentListViewModel,
        scanner: ScannerViewModel,
        importer: ImportViewModel,
        makeViewer: @escaping (UUID) -> DocumentViewerViewModel,
        onShowAccount: @escaping () -> Void = {}
    ) {
        _viewModel = Bindable(viewModel)
        _scanner = Bindable(scanner)
        self.importer = importer
        self.makeViewer = makeViewer
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
                .importFlow(
                    importer: importer,
                    isFileImporterPresented: $isFileImporterPresented,
                    isPhotoPickerPresented: $isPhotoPickerPresented
                )
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
                    DocumentViewerView(viewModel: makeViewer(id))
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
                .scannerAlerts(scanner)
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

    // MARK: - Alerts

    private var isErrorPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}
