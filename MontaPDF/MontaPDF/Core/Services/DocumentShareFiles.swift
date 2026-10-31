//
//  DocumentShareFiles.swift
//  MontaPDF
//

import Foundation

/// Builds the files a document is shared as: "<name>.pdf" and, for imports,
/// the original with its own extension (e.g. "<name>.docx").
/// Used by both the list and the viewer, so the naming rules live in one place.
struct DocumentShareFiles {
    private let exporter: DocumentExporting

    init(exporter: DocumentExporting) {
        self.exporter = exporter
    }

    /// `nil` when the document has no PDF (not synced yet, or a Word file kept as original).
    func pdfURL(for document: Document, title: String) throws -> URL? {
        guard let data = document.pdfData else { return nil }
        return try exporter.export(data, fileName: DocumentTitleRules.fileName(for: title))
    }

    /// `nil` when the document was not imported from another file.
    func originalURL(for document: Document, title: String) throws -> URL? {
        guard let data = document.originalData else { return nil }
        let ext = ((document.originalFileName ?? "") as NSString).pathExtension
        return try exporter.export(
            data,
            fileName: DocumentTitleRules.fileName(for: title, fileExtension: ext.isEmpty ? "docx" : ext)
        )
    }
}
