//
//  DocumentListViewModel.swift
//  MontaPDF
//

import Foundation
import Observation

@Observable
@MainActor
final class DocumentListViewModel {
    private(set) var rows: [DocumentRow] = []
    private(set) var savedBanner: SavedBanner?
    var errorMessage: String?

    // Rename, delete and share
    var isRenaming = false
    var renameDraft = ""
    private(set) var renameTargetID: UUID?
    var isConfirmingDelete = false
    private(set) var deleteTarget: DocumentRow?
    var shareItem: ShareItem?
    /// Word imports ask whether to share the PDF or the original file.
    var isChoosingShareFormat = false
    private(set) var shareChoiceID: UUID?

    private let repository: DocumentRepository
    private let namer: DocumentNamer
    private let shareFiles: DocumentShareFiles
    private var documents: [Document] = []
    private var thumbnails: [UUID: Data] = [:]

    init(
        repository: DocumentRepository,
        namer: DocumentNamer,
        exporter: DocumentExporting
    ) {
        self.repository = repository
        self.namer = namer
        self.shareFiles = DocumentShareFiles(exporter: exporter)
    }

    // MARK: - Loading

    func load() {
        perform {
            documents = try repository.fetchAll()
        }
    }

    /// Reloads the list and shows the "saved" banner for a new document.
    func documentAdded(id: UUID) {
        load()
        if let row = rows.first(where: { $0.id == id }) {
            savedBanner = SavedBanner(id: id, title: row.title)
        }
    }

    func dismissBanner() {
        savedBanner = nil
    }

    // MARK: - Editing

    func delete(at offsets: IndexSet) {
        let ids = offsets.map { rows[$0].id }
        delete(ids: ids)
    }

    func delete(ids: [UUID]) {
        perform {
            for document in documents where ids.contains(document.id) {
                try repository.delete(document)
            }
            documents = try repository.fetchAll()
        }
    }

    func rename(id: UUID, to title: String) {
        guard let document = documents.first(where: { $0.id == id }) else { return }
        perform {
            try repository.rename(document, to: title)
            documents = try repository.fetchAll()
        }
    }

    func startRename(id: UUID) {
        guard let row = rows.first(where: { $0.id == id }) else { return }
        renameTargetID = id
        renameDraft = row.title
        isRenaming = true
    }

    func confirmRename() {
        guard let id = renameTargetID else { return }
        guard !DocumentTitleRules.sanitize(renameDraft).isEmpty else { return }
        rename(id: id, to: renameDraft)
        renameTargetID = nil
        if savedBanner?.id == id {
            savedBanner = nil
        }
    }

    func startDelete(id: UUID) {
        guard let row = rows.first(where: { $0.id == id }) else { return }
        deleteTarget = row
        isConfirmingDelete = true
    }

    func confirmDelete() {
        guard let target = deleteTarget else { return }
        delete(ids: [target.id])
        thumbnails[target.id] = nil
        deleteTarget = nil
    }

    /// Shares the PDF. Word imports first ask: PDF or original?
    func share(id: UUID) {
        guard let document = documents.first(where: { $0.id == id }) else { return }
        switch (document.pdfData != nil, document.originalData != nil) {
        case (true, true):
            shareChoiceID = id
            isChoosingShareFormat = true
        case (true, false):
            share(id: id, format: .pdf)
        case (false, true):
            share(id: id, format: .original)
        case (false, false):
            break
        }
    }

    func share(id: UUID, format: ShareFormat) {
        guard
            let document = documents.first(where: { $0.id == id }),
            let row = rows.first(where: { $0.id == id })
        else { return }
        perform {
            let url: URL?
            switch format {
            case .pdf: url = try shareFiles.pdfURL(for: document, title: row.title)
            case .original: url = try shareFiles.originalURL(for: document, title: row.title)
            }
            if let url {
                shareItem = ShareItem(url: url)
            }
        }
    }

    func shareChosen(_ format: ShareFormat) {
        guard let id = shareChoiceID else { return }
        shareChoiceID = nil
        share(id: id, format: format)
    }

    /// First page of the PDF, cached after the first render.
    func thumbnail(for id: UUID) async -> Data? {
        if let cached = thumbnails[id] { return cached }
        guard let data = documents.first(where: { $0.id == id })?.pdfData else { return nil }
        let image = await ThumbnailRenderer.render(data, size: CGSize(width: 120, height: 160))
        thumbnails[id] = image
        return image
    }

    // MARK: - Private

    private func perform(_ work: () throws -> Void) {
        do {
            try work()
        } catch {
            errorMessage = error.localizedDescription
        }
        rebuildRows()
    }

    private func rebuildRows() {
        let titles = namer.displayTitles(for: documents)
        rows = documents
            .sorted { $0.createdAt > $1.createdAt }
            .map { document in
                DocumentRow(
                    id: document.id,
                    title: titles[document.id] ?? document.title,
                    createdAt: document.createdAt,
                    pageCount: document.pageCount,
                    hasPDF: document.pdfData != nil,
                    originalFileName: document.originalFileName,
                    hasOriginal: document.originalData != nil
                )
            }
    }
}
