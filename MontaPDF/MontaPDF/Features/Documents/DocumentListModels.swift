//
//  DocumentListModels.swift
//  MontaPDF
//

import Foundation

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
