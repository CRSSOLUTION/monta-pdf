//
//  DossierDetailView.swift
//  MontaPDF
//

import SwiftUI

/// The checklist of a dossier: what is added, what is missing and what doesn't apply.
struct DossierDetailView: View {
    /// Kept in `@State`: the destination is rebuilt whenever the list redraws, and a new
    /// ViewModel would lose the scanner or the dialogs in the middle of their use.
    @State private var viewModel: DossierDetailViewModel
    /// Pushes the PDF viewer of a document on the navigation stack.
    let openDocument: (UUID) -> Void
    /// Pushes the "Assemble and send" screen.
    let openAssemble: () -> Void

    init(
        viewModel: DossierDetailViewModel,
        openDocument: @escaping (UUID) -> Void,
        openAssemble: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.openDocument = openDocument
        self.openAssemble = openAssemble
    }

    private var scanner: ScannerViewModel { viewModel.scanner }

    private var isScannerPresented: Binding<Bool> {
        Binding(
            get: { viewModel.scanner.isScannerPresented },
            set: { viewModel.scanner.isScannerPresented = $0 }
        )
    }

    var body: some View {
        Group {
            if let dossier = viewModel.dossier {
                checklist(for: dossier)
            } else if viewModel.isLoaded {
                ContentUnavailableView("Packet not found", systemImage: "folder.badge.questionmark")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.load() }
        .confirmationDialog(
            viewModel.targetItem?.title ?? "",
            isPresented: $viewModel.isAddOptionsPresented,
            titleVisibility: .visible
        ) {
            Button("Scan document") { Task { await viewModel.scan() } }
            Button("Import file") { viewModel.importFile() }
            Button("Choose photos") { viewModel.choosePhotos() }
            Button("Choose from library") { viewModel.chooseFromLibrary() }
            if let item = viewModel.targetItem, item.state != .notApplicable {
                Button("Doesn't apply") { viewModel.setNotApplicable(true, for: item) }
            }
            Button("Cancel", role: .cancel) {}
        }
        .importFlow(
            importer: viewModel.importer,
            isFileImporterPresented: $viewModel.isFileImporterPresented,
            isPhotoPickerPresented: $viewModel.isPhotoPickerPresented
        )
        .fullScreenCover(isPresented: isScannerPresented) {
            DocumentScannerView(
                onFinish: { pages in
                    Task { await scanner.scannerFinished(with: pages) }
                },
                onCancel: { scanner.scannerCancelled() },
                onError: { error in scanner.scannerFailed(error) }
            )
            .ignoresSafeArea()
        }
        .scannerAlerts(scanner)
        .overlay {
            if scanner.isSaving || viewModel.importer.isConverting {
                SavingOverlay()
            }
        }
        .sheet(isPresented: $viewModel.isLibraryPresented) {
            LibraryPickerView(documents: viewModel.libraryDocuments) { id in
                viewModel.libraryDocumentChosen(id: id)
            }
        }
        .sheet(isPresented: $viewModel.isAddingItem) {
            NewDossierItemView { title, isRequired in
                viewModel.addItem(title: title, isRequired: isRequired)
            }
        }
        .alert("Rename item", isPresented: $viewModel.isRenaming) {
            TextField("Name", text: $viewModel.renameDraft)
            Button("Cancel", role: .cancel) {}
            Button("Save") { viewModel.confirmRename() }
                .disabled(DocumentTitleRules.sanitize(viewModel.renameDraft).isEmpty)
        }
        .alert(
            "Remove \(viewModel.targetItem?.title ?? "") from the list?",
            isPresented: $viewModel.isConfirmingRemove
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) { viewModel.confirmRemove() }
        } message: {
            Text("The document stays in your library.")
        }
        .alert(missingAlertTitle, isPresented: $viewModel.isConfirmingMissing) {
            Button("Add now") { viewModel.addFirstMissing() }
                .keyboardShortcut(.defaultAction)
            Button("Assemble anyway") { openAssemble() }
        } message: {
            Text("Not added yet: \(viewModel.missingRequiredTitles.formatted(.list(type: .and))). Assemble the PDF anyway?")
        }
        .alert("Something went wrong", isPresented: isErrorPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func checklist(for dossier: Dossier) -> some View {
        List {
            Section {
                DossierProgressHeader(dossier: dossier)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
            }
            if !viewModel.requiredItems.isEmpty {
                Section("Required") {
                    ForEach(viewModel.requiredItems) { item in
                        row(for: item)
                    }
                    .onMove(perform: viewModel.moveRequired)
                    .onDelete(perform: viewModel.removeRequired)
                }
            }
            if !viewModel.optionalItems.isEmpty {
                Section("Optional items") {
                    ForEach(viewModel.optionalItems) { item in
                        row(for: item)
                    }
                    .onMove(perform: viewModel.moveOptional)
                    .onDelete(perform: viewModel.removeOptional)
                }
            }
            Section {
                Button {
                    viewModel.startAddingItem()
                } label: {
                    Label("Add item", systemImage: "plus")
                }
                .accessibilityIdentifier("addItemButton")
            }
        }
        .listStyle(.insetGrouped)
        .safeAreaInset(edge: .bottom) {
            Button {
                if viewModel.assembleTapped() { openAssemble() }
            } label: {
                Label("Assemble PDF", systemImage: "doc.on.doc")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.canAssemble)
            .padding(.horizontal)
            .padding(.bottom, 8)
            .accessibilityIdentifier("assemblePDFButton")
        }
        .navigationTitle(dossier.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
    }

    private func row(for item: DossierItem) -> some View {
        DossierItemRowView(
            item: item,
            loadThumbnail: { await viewModel.thumbnail(for: item) },
            onAdd: { viewModel.startAdding(item) },
            onView: { if let id = item.document?.id { openDocument(id) } },
            onRemoveDocument: { viewModel.removeDocument(from: item) },
            onRename: { viewModel.startRename(item) },
            onSetNotApplicable: { viewModel.setNotApplicable($0, for: item) },
            onRemoveItem: { viewModel.startRemove(item) }
        )
    }

    private var missingAlertTitle: Text {
        Text("\(viewModel.missingRequiredTitles.count) required documents missing")
    }

    private var isErrorPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

/// Template name and "X of Y required" with a bar.
private struct DossierProgressHeader: View {
    let dossier: Dossier

    var body: some View {
        let progress = dossier.progress
        VStack(alignment: .leading, spacing: 6) {
            if let id = DossierTemplate.ID(rawValue: dossier.templateID),
               let template = DossierTemplates.template(id: id) {
                Text(template.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if progress.required > 0 {
                Text("\(progress.addedRequired) of \(progress.required) required")
                    .font(.subheadline.weight(.semibold))
                    .accessibilityIdentifier("dossierProgress")
                ProgressView(value: Double(progress.addedRequired), total: Double(progress.required))
                    .accessibilityHidden(true)
            }
            if dossier.editedAfterSending {
                Label("Edited after sending", systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
