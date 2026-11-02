//
//  ThumbnailRenderer.swift
//  MontaPDF
//

import PDFKit
import UIKit

/// Renders the first page of a PDF as a small image, off the main thread.
nonisolated enum ThumbnailRenderer {
    /// PNG bytes of the first page, or nil when the PDF can't be read.
    static func render(_ pdfData: Data, size: CGSize) async -> Data? {
        await Task.detached(priority: .utility) {
            guard let page = PDFDocument(data: pdfData)?.page(at: 0) else { return nil }
            return page.thumbnail(of: size, for: .mediaBox).pngData()
        }.value
    }
}
