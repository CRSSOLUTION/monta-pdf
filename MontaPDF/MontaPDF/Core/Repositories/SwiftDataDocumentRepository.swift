//
//  SwiftDataDocumentRepository.swift
//  MontaPDF
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataDocumentRepository: DocumentRepository {
    /// Kept so the container lives as long as the repository uses its context.
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init(container: ModelContainer) {
        self.container = container
    }

    func fetchAll() throws -> [Document] {
        let descriptor = FetchDescriptor<Document>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    @discardableResult
    func create(
        pageCount: Int,
        fileName: String,
        originalFileName: String?,
        createdAt: Date
    ) throws -> Document {
        let document = Document(
            createdAt: createdAt,
            pageCount: pageCount,
            fileName: fileName,
            originalFileName: originalFileName
        )
        context.insert(document)
        try context.save()
        return document
    }

    func rename(_ document: Document, to title: String) throws {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        document.title = trimmed
        document.isCustomTitle = !trimmed.isEmpty
        try context.save()
    }

    func delete(_ document: Document) throws {
        context.delete(document)
        try context.save()
    }
}
