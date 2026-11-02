//
//  PDFBuilder.swift
//  MontaPDF
//

import UIKit

/// Turns images (scanned pages or imported photos) into a single PDF.
/// `nonisolated` so the work can run off the main thread.
nonisolated protocol PDFBuilding: Sendable {
    func makePDF(from images: [UIImage]) throws -> Data
}
