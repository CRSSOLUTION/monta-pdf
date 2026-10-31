//
//  DocumentViewerView.swift
//  MontaPDF
//

import SwiftUI

struct DocumentViewerView: View {
    @State private var viewModel: DocumentViewerViewModel
    @State private var currentPage = 1
    @State private var pageCount = 0
    @Environment(\.dismiss) private var dismiss

    init(viewModel: DocumentViewerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button {
                        viewModel.startRename()
                    } label: {
                        Text(viewModel.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    .accessibilityHint(Text("Rename"))
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    shareButton
                    Menu {
                        Button("Rename", systemImage: "pencil") {
                            viewModel.startRename()
                        }
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            viewModel.isConfirmingDelete = true
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
            .renameDocumentAlert(
                isPresented: $viewModel.isRenaming,
                name: $viewModel.renameDraft
            ) { _ in
                viewModel.confirmRename()
            }
            .deleteDocumentAlert(
                isPresented: $viewModel.isConfirmingDelete,
                title: viewModel.title
            ) {
                viewModel.confirmDelete()
            }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.dismissError() } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onChange(of: viewModel.isDeleted) { _, deleted in
                if deleted { dismiss() }
            }
            .task {
                viewModel.load()
            }
    }

    /// Word imports offer the PDF or the original file.
    @ViewBuilder
    private var shareButton: some View {
        switch (viewModel.shareURL, viewModel.originalShareURL) {
        case let (pdf?, original?):
            Menu {
                ShareLink("PDF", item: pdf)
                ShareLink("Original File", item: original)
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        case let (pdf?, nil):
            ShareLink(item: pdf) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        case let (nil, original?):
            ShareLink(item: original) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        case (nil, nil):
            EmptyView()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .downloading:
            ContentUnavailableView {
                Label("Downloading from iCloud...", systemImage: "icloud.and.arrow.down")
            } description: {
                Text("If you're offline, connect to the internet to open this document.")
            }
        case .originalOnly:
            ContentUnavailableView {
                Label("Original file kept", systemImage: "doc.richtext")
            } description: {
                Text("This document was saved without converting to PDF. You can share the original file.")
            }
        case .notFound:
            ContentUnavailableView("Document not found", systemImage: "doc.questionmark")
        case .ready:
            if let data = viewModel.pdfData {
                PDFKitView(data: data, currentPage: $currentPage, pageCount: $pageCount)
                    .ignoresSafeArea(edges: .bottom)
                    .overlay(alignment: .bottom) {
                        if pageCount > 1 {
                            Text("Page \(currentPage) of \(pageCount)")
                                .font(.footnote.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.regularMaterial, in: Capsule())
                                .padding(.bottom, 24)
                        }
                    }
            }
        }
    }
}
