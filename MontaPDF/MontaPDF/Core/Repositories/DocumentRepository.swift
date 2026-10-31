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

    @discardableResult
    func create(
        pageCount: Int,
        fileName: String,
        originalFileName: String?,
        createdAt: Date
    ) throws -> Document

    /// Sets a custom title. An empty (or whitespace only) title brings back the automatic name.
    func rename(_ document: Document, to title: String) throws

    func delete(_ document: Document) throws
}

extension DocumentRepository {
    @discardableResult
    func create(
        pageCount: Int,
        fileName: String,
        originalFileName: String? = nil
    ) throws -> Document {
        try create(
            pageCount: pageCount,
            fileName: fileName,
            originalFileName: originalFileName,
            createdAt: Date()
        )
    }
}
