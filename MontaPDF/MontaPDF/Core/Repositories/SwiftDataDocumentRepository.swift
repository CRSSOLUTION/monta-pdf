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

    func document(id: UUID) throws -> Document? {
        var descriptor = FetchDescriptor<Document>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    @discardableResult
    func create(_ newDocument: NewDocument) throws -> Document {
        let id = UUID()
        let title = newDocument.customTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let document = Document(
            id: id,
            title: title,
            isCustomTitle: !title.isEmpty,
            createdAt: newDocument.createdAt,
            pageCount: newDocument.pageCount,
            fileName: "\(id.uuidString).pdf",
            originalFileName: newDocument.originalFileName,
            pdfData: newDocument.pdfData,
            originalData: newDocument.originalData
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
