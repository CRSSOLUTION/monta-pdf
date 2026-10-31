//
//  Document.swift
//  MontaPDF
//

import Foundation
import SwiftData

/// A PDF document stored in the user's library.
///
/// CloudKit rules: every property is `var` with a default value, no `.unique`
/// attributes and relationships (when added) must be optional.
@Model
final class Document {
    var id: UUID = UUID()
    /// Custom title chosen by the user. Empty while `isCustomTitle` is `false`,
    /// because automatic names ("Document N") are computed by `DocumentNamer`.
    var title: String = ""
    var isCustomTitle: Bool = false
    var createdAt: Date = Date()
    var pageCount: Int = 0
    /// Name used when the PDF is written to disk (e.g. "<uuid>.pdf").
    var fileName: String = ""
    /// Name of the imported file, when the document came from an import.
    var originalFileName: String?
    /// The PDF itself. External storage keeps it out of the database row and
    /// CloudKit syncs it as an asset, so files follow the user to every device.
    @Attribute(.externalStorage) var pdfData: Data?
    /// The imported original (e.g. a .docx), kept untouched.
    @Attribute(.externalStorage) var originalData: Data?

    init(
        id: UUID = UUID(),
        title: String = "",
        isCustomTitle: Bool = false,
        createdAt: Date = Date(),
        pageCount: Int = 0,
        fileName: String = "",
        originalFileName: String? = nil,
        pdfData: Data? = nil,
        originalData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.isCustomTitle = isCustomTitle
        self.createdAt = createdAt
        self.pageCount = pageCount
        self.fileName = fileName
        self.originalFileName = originalFileName
        self.pdfData = pdfData
        self.originalData = originalData
    }
}
