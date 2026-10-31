//
//  DocumentListView.swift
//  MontaPDF
//

import SwiftUI

struct DocumentListView: View {
    @Bindable var viewModel: DocumentListViewModel
    @Environment(\.openURL) private var openURL
    @State private var path: [UUID] = []

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("My Documents")
                .overlay(alignment: .bottom) { bottomBar }
                .overlay {
                    if viewModel.isSaving {
                        SavingOverlay()
                    }
                }
                .fullScreenCover(isPresented: $viewModel.isScannerPresented) {
                    DocumentScannerView(
                        onFinish: { pages in
                            Task { await viewModel.scannerFinished(with: pages) }
                        },
                        onCancel: { viewModel.scannerCancelled() },
                        onError: { error in viewModel.scannerFailed(error) }
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
                    alertTitle(viewModel.alert),
                    isPresented: isAlertPresented,
                    presenting: viewModel.alert
                ) { alert in
                    alertActions(alert)
                } message: { alert in
                    alertMessage(alert)
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
                    Task { await viewModel.scanTapped() }
                } label: {
                    Label("Scan", systemImage: "camera")
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
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
                    Task { await viewModel.scanTapped() }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .animation(.default, value: viewModel.savedBanner)
    }

    // MARK: - Alerts

    private var isAlertPresented: Binding<Bool> {
        Binding(
            get: { viewModel.alert != nil },
            set: { if !$0 { viewModel.alert = nil } }
        )
    }

    private func alertTitle(_ alert: DocumentListAlert?) -> Text {
        switch alert ?? .generic("") {
        case .scannerUnavailable: Text("Scanner unavailable")
        case .cameraDenied: Text("Camera access needed")
        case .saveFailed: Text("Couldn't save. Please try again.")
        case .generic: Text("Something went wrong")
        }
    }

    @ViewBuilder
    private func alertActions(_ alert: DocumentListAlert) -> some View {
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
                Task { await viewModel.retrySave() }
            }
            Button("Discard", role: .destructive) {
                viewModel.discardPendingPages()
            }
        case .scannerUnavailable, .generic:
            Button("OK", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func alertMessage(_ alert: DocumentListAlert) -> some View {
        switch alert {
        case .scannerUnavailable: Text("This device can't scan documents.")
        case .cameraDenied: Text("Allow camera access in Settings to scan your documents.")
        case .saveFailed: Text("Your scanned pages were kept.")
        case .generic(let message): Text(message)
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
                    Text("\(row.pageCount) pages")
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
