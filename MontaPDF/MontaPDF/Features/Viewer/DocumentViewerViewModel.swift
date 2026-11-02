//
//  DocumentViewerViewModel.swift
//  MontaPDF
//

import Foundation
import Observation

@Observable
@MainActor
final class DocumentViewerViewModel {
    let documentID: UUID
    private(set) var title = ""
    private(set) var pdfData: Data?
    private(set) var shareURL: URL?
    /// Imported original (e.g. .docx), offered next to the PDF when sharing.
    private(set) var originalShareURL: URL?
    private(set) var state: DocumentViewerState = .loading
    private(set) var isDeleted = false
    private(set) var errorMessage: String?

    var isRenaming = false
    var renameDraft = ""
    var isConfirmingDelete = false

    private let repository: DocumentRepository
    private let namer: DocumentNamer
    private let shareFiles: DocumentShareFiles

    init(
        documentID: UUID,
        repository: DocumentRepository,
        namer: DocumentNamer,
        exporter: DocumentExporting
    ) {
        self.documentID = documentID
        self.repository = repository
        self.namer = namer
        self.shareFiles = DocumentShareFiles(exporter: exporter)
    }

    func load() {
        do {
            guard let document = try repository.document(id: documentID) else {
                state = .notFound
                return
            }
            let titles = namer.displayTitles(for: try repository.fetchAll())
            title = titles[documentID] ?? document.title
            pdfData = document.pdfData
            originalShareURL = try? shareFiles.originalURL(for: document, title: title)
            shareURL = try? shareFiles.pdfURL(for: document, title: title)
            if document.pdfData != nil {
                state = .ready
            } else {
                state = document.originalData == nil ? .downloading : .originalOnly
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startRename() {
        renameDraft = title
        isRenaming = true
    }

    func confirmRename() {
        guard !DocumentTitleRules.sanitize(renameDraft).isEmpty else { return }
        do {
            guard let document = try repository.document(id: documentID) else { return }
            try repository.rename(document, to: renameDraft)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmDelete() {
        do {
            if let document = try repository.document(id: documentID) {
                try repository.delete(document)
            }
            isDeleted = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func dismissError() {
        errorMessage = nil
    }
}
