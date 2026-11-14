//
//  DossierPDFError.swift
//  MontaPDF
//

import Foundation

nonisolated enum DossierPDFError: Error, Equatable, LocalizedError {
    /// No document with a PDF to assemble.
    case noDocuments
    /// A document's PDF couldn't be read.
    case unreadableDocument(String)
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .noDocuments:
            String(localized: "Add at least one document before assembling the PDF.")
        case .unreadableDocument(let title):
            String(localized: "Couldn't read \(title). Replace it and try again.")
        case .writeFailed:
            String(localized: "Couldn't create the PDF. Please try again.")
        }
    }
}
