//
//  DocumentViewerViewModel.swift
//  MontaPDF
//

import Foundation
import Observation

nonisolated enum DocumentViewerState: Equatable, Sendable {
    case loading
    case ready
    /// The PDF hasn't arrived from iCloud yet.
    case downloading
    /// Imported Word file kept without a PDF.
    case originalOnly
    case notFound
}

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
    private let exporter: DocumentExporting

    init(
        documentID: UUID,
        repository: DocumentRepository,
        namer: DocumentNamer? = nil,
        exporter: DocumentExporting? = nil
    ) {
        self.documentID = documentID
        self.repository = repository
        self.namer = namer ?? DocumentNamer()
        self.exporter = exporter ?? TemporaryFileExporter()
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
            if let original = document.originalData {
                let ext = ((document.originalFileName ?? "") as NSString).pathExtension
                originalShareURL = try? exporter.export(
                    original,
                    fileName: DocumentTitleRules.fileName(for: title, fileExtension: ext.isEmpty ? "docx" : ext)
                )
            }
            if let data = document.pdfData {
                state = .ready
                shareURL = try? exporter.export(data, fileName: DocumentTitleRules.fileName(for: title))
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
        let newTitle = DocumentTitleRules.sanitize(renameDraft)
        guard !newTitle.isEmpty else { return }
        do {
            guard let document = try repository.document(id: documentID) else { return }
            try repository.rename(document, to: newTitle)
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
