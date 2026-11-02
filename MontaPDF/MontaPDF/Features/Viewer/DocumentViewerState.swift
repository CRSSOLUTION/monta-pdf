//
//  DocumentViewerState.swift
//  MontaPDF
//

import Foundation

nonisolated enum DocumentViewerState: Equatable, Sendable {
    case loading
    case ready
    /// The PDF hasn't arrived from iCloud yet.
    case downloading
    /// Imported Word file kept without a PDF.
    case originalOnly
    case notFound
}
