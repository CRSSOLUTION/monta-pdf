//
//  DocumentListView.swift
//  MontaPDF
//

import SwiftUI

struct DocumentListView: View {
    @Bindable var viewModel: DocumentListViewModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
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
        .task {
            viewModel.load()
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
                    DocumentRowView(row: row)
                }
                .onDelete(perform: viewModel.delete(at:))
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
                SavedBannerView(banner: banner) {
                    viewModel.dismissBanner()
                }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(row.title)
                .font(.headline)
            HStack(spacing: 8) {
                Text(row.createdAt, format: .dateTime.day().month().year())
                Text("\(row.pageCount) pages")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
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
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("\(banner.title) saved")
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .task(id: banner.id) {
            try? await Task.sleep(for: .seconds(4))
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
