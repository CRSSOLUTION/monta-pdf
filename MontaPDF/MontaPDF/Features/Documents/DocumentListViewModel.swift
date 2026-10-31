//
//  DocumentListViewModel.swift
//  MontaPDF
//

import Foundation
import Observation
import UIKit

/// What the document list shows for each document.
nonisolated struct DocumentRow: Identifiable, Sendable {
    let id: UUID
    let title: String
    let createdAt: Date
    let pageCount: Int
    /// `false` for imported Word files kept without a PDF.
    var hasPDF = true
    /// Set for imported files (e.g. "Contract.docx").
    var originalFileName: String?
    var hasOriginal = false
}

nonisolated enum ShareFormat: Sendable {
    case pdf
    case original
}

/// Shown at the bottom of the list after a document is saved.
nonisolated struct SavedBanner: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
}

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
    private let exporter: DocumentExporting
    private var documents: [Document] = []
    private var thumbnails: [UUID: UIImage] = [:]

    init(
        repository: DocumentRepository,
        namer: DocumentNamer,
        exporter: DocumentExporting
    ) {
        self.repository = repository
        self.namer = namer
        self.exporter = exporter
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
            try repository.rename(document, to: DocumentTitleRules.sanitize(title))
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
        let newTitle = DocumentTitleRules.sanitize(renameDraft)
        guard !newTitle.isEmpty else { return }
        rename(id: id, to: newTitle)
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
            switch format {
            case .pdf:
                guard let data = document.pdfData else { return }
                let url = try exporter.export(data, fileName: DocumentTitleRules.fileName(for: row.title))
                shareItem = ShareItem(url: url)
            case .original:
                guard let data = document.originalData else { return }
                let ext = ((document.originalFileName ?? "") as NSString).pathExtension
                let url = try exporter.export(
                    data,
                    fileName: DocumentTitleRules.fileName(for: row.title, fileExtension: ext.isEmpty ? "docx" : ext)
                )
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
    func thumbnail(for id: UUID) async -> UIImage? {
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
