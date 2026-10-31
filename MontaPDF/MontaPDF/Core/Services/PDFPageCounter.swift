//
//  PDFPageCounter.swift
//  MontaPDF
//

import Foundation
import PDFKit

nonisolated enum PDFPageCounter {
    /// Number of pages, or 0 when the data isn't a valid PDF.
    static func count(_ data: Data) -> Int {
        PDFDocument(data: data)?.pageCount ?? 0
    }
}
