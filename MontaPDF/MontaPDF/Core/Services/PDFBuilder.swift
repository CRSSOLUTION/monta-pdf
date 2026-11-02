//
//  PDFBuilder.swift
//  MontaPDF
//

import Foundation

/// Turns images (scanned pages or imported photos) into a single PDF.
/// `nonisolated` so the work can run off the main thread.
nonisolated protocol PDFBuilding: Sendable {
    /// Throws `PDFBuilderError.noPages` when none of the pages is a readable image.
    func makePDF(from pages: [PageImage]) throws -> Data
}
