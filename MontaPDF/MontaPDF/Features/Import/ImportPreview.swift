//
//  ImportPreview.swift
//  MontaPDF
//

import Foundation

/// A converted file waiting for the user to confirm it.
nonisolated struct ImportPreview: Identifiable, Sendable {
    let id = UUID()
    let pdfData: Data
    let pageCount: Int
    /// Custom title (from the file name). `nil` gives an automatic "Document N".
    let title: String?
    let originalFileName: String?
    /// Kept only for Word files.
    let originalData: Data?

    var isWord: Bool { originalData != nil }
}
