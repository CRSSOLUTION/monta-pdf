//
//  LibraryDocument.swift
//  MontaPDF
//

import Foundation

/// A document of the library offered when filling a checklist item.
nonisolated struct LibraryDocument: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let pageCount: Int
    let createdAt: Date
}
