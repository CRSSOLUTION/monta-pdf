//
//  DocumentExporter.swift
//  MontaPDF
//

import Foundation

/// Writes a document to a temporary file so it can be shared as a real file (not a link).
protocol DocumentExporting {
    func export(_ data: Data, fileName: String) throws -> URL
}
