//
//  DocumentConverter.swift
//  MontaPDF
//

import Foundation

nonisolated struct ConvertedPDF: Sendable {
    let data: Data
    let pageCount: Int
}

nonisolated enum DocumentConverterError: Error {
    case loadFailed
    case emptyDocument
    case timedOut
}

/// Converts a document (e.g. Word) into PDF. The engine can be swapped later
/// (e.g. a paid SDK) without touching the rest of the app.
protocol DocumentConverter {
    func convertToPDF(data: Data, fileName: String) async throws -> ConvertedPDF
}
