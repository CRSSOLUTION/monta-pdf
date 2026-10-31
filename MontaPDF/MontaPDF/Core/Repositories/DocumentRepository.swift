//
//  DocumentRepository.swift
//  MontaPDF
//

import Foundation

/// Data access for documents. ViewModels depend on this protocol, never on SwiftData directly.
@MainActor
protocol DocumentRepository {
    /// All documents, newest first.
    func fetchAll() throws -> [Document]

    func document(id: UUID) throws -> Document?

    @discardableResult
    func create(_ newDocument: NewDocument) throws -> Document

    /// Sets a custom title, applying `DocumentTitleRules`. A title that ends up empty
    /// brings back the automatic name.
    func rename(_ document: Document, to title: String) throws

    func delete(_ document: Document) throws

    /// Deletes every document (used when the account is deleted).
    func deleteAll() throws
}
