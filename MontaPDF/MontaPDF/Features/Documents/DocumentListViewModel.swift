//
//  DocumentListViewModel.swift
//  MontaPDF
//

import Foundation
import Observation

/// What the document list shows for each document.
struct DocumentRow: Identifiable {
    let id: UUID
    let title: String
    let createdAt: Date
    let pageCount: Int
}

@Observable
@MainActor
final class DocumentListViewModel {
    private(set) var rows: [DocumentRow] = []
    private(set) var errorMessage: String?

    private let repository: DocumentRepository
    private let namer: DocumentNamer
    private var documents: [Document] = []

    init(repository: DocumentRepository, namer: DocumentNamer = DocumentNamer()) {
        self.repository = repository
        self.namer = namer
    }

    func load() {
        perform {
            documents = try repository.fetchAll()
        }
    }

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

    #if DEBUG
    /// Temporary helper to see the list working until the scanner exists.
    func addSampleDocument() {
        perform {
            try repository.create(pageCount: 1, fileName: "\(UUID().uuidString).pdf")
            documents = try repository.fetchAll()
        }
    }
    #endif

    func dismissError() {
        errorMessage = nil
    }

    private func perform(_ work: () throws -> Void) {
        do {
            try work()
            errorMessage = nil
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
                    pageCount: document.pageCount
                )
            }
    }
}
