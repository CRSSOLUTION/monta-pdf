//
//  NewDocument.swift
//  MontaPDF
//

import Foundation

/// Everything needed to create a document.
struct NewDocument {
    var pdfData: Data?
    var pageCount: Int
    /// `nil` means the document gets an automatic "Document N" name.
    var customTitle: String?
    var originalFileName: String?
    var originalData: Data?
    var createdAt: Date

    init(
        pdfData: Data?,
        pageCount: Int,
        customTitle: String? = nil,
        originalFileName: String? = nil,
        originalData: Data? = nil,
        createdAt: Date = Date()
    ) {
        self.pdfData = pdfData
        self.pageCount = pageCount
        self.customTitle = customTitle
        self.originalFileName = originalFileName
        self.originalData = originalData
        self.createdAt = createdAt
    }
}
