//
//  AssembleDossierView.swift
//  MontaPDF
//

import SwiftUI

/// Screen 7: cover and summary options, where each document starts, preview and share.
struct AssembleDossierView: View {
    /// Kept in `@State` for the same reason as the checklist: the destination is rebuilt on redraws.
    @State private var viewModel: AssembleDossierViewModel

    init(viewModel: AssembleDossierViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            if let dossier = viewModel.dossier {
                summaryRow(for: dossier)
                optionsSection(for: dossier)
                pagesSection
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Assemble and send")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isAssembling && viewModel.assembled == nil {
                ProgressView()
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                viewModel.share()
            } label: {
                Label("Share PDF", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.assembled == nil || viewModel.isAssembling)
            .padding(.horizontal)
            .padding(.bottom, 8)
            .accessibilityIdentifier("sharePDFButton")
        }
        .task { await viewModel.load() }
        .sheet(item: $viewModel.shareItem, onDismiss: viewModel.shareSheetDismissed) { item in
            ActivityView(items: [item.url]) { completed in
                viewModel.shareFinished(completed: completed)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.isPreviewPresented) {
            if let assembled = viewModel.assembled {
                PDFPreviewSheet(data: assembled.data, title: viewModel.dossier?.name ?? "")
            }
        }
        .alert("Mark as sent?", isPresented: $viewModel.isAskingSent) {
            Button("Not yet", role: .cancel) {}
            Button("Mark") { viewModel.markSent() }
                .keyboardShortcut(.defaultAction)
        } message: {
            Text("\(viewModel.dossier?.name ?? "") moves to the Sent tab.")
        }
        .alert("Something went wrong", isPresented: isErrorPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Sections

    private func summaryRow(for dossier: Dossier) -> some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "doc.richtext")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(dossier.name)
                        .font(.headline)
                    if let assembled = viewModel.assembled {
                        Text("\(assembled.pageCount) pages")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("assembledPageCount")
                    }
                    DossierStatusLine(progress: dossier.progress, status: dossier.status)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func optionsSection(for dossier: Dossier) -> some View {
        Section("Options") {
            Toggle(isOn: Binding(
                get: { viewModel.includesCover },
                set: { value in Task { await viewModel.setIncludesCover(value) } }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cover")
                    Group {
                        if dossier.coverName.isEmpty {
                            Text("Packet name and date")
                        } else {
                            Text("Packet name, \(dossier.coverName) and date")
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            Toggle(isOn: Binding(
                get: { viewModel.includesSummary },
                set: { value in Task { await viewModel.setIncludesSummary(value) } }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Summary")
                    Text("Documents with the page where each one starts")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var pagesSection: some View {
        Section {
            if viewModel.includesCover {
                LabeledContent("Cover") { Text("p. \(1)") }
            }
            if viewModel.includesSummary {
                LabeledContent("Summary") { Text("p. \(viewModel.includesCover ? 2 : 1)") }
            }
            ForEach(Array((viewModel.assembled?.entries ?? []).enumerated()), id: \.offset) { _, entry in
                LabeledContent(entry.title) { Text("p. \(entry.page)") }
            }
            Button {
                viewModel.isPreviewPresented = true
            } label: {
                Label("Preview PDF", systemImage: "eye")
            }
            .disabled(viewModel.assembled == nil)
            .accessibilityIdentifier("previewPDFButton")
        } header: {
            Text("Pages")
        } footer: {
            if !viewModel.unavailableTitles.isEmpty {
                Text("Not included: \(viewModel.unavailableTitles.formatted(.list(type: .and))). It's still downloading from iCloud or was kept only as the original file.")
            }
        }
    }

    private var isErrorPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

/// Full preview of the assembled PDF before sharing.
private struct PDFPreviewSheet: View {
    let data: Data
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 1
    @State private var pageCount = 0

    var body: some View {
        NavigationStack {
            PDFKitView(data: data, currentPage: $currentPage, pageCount: $pageCount)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}
