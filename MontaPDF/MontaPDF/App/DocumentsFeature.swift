//
//  DocumentsFeature.swift
//  MontaPDF
//

import Foundation

/// ViewModels used by the My Documents screen.
struct DocumentsFeature {
    let list: DocumentListViewModel
    let scanner: ScannerViewModel
    let importer: ImportViewModel
    /// Builds the ViewModel of the PDF viewer for a document.
    let makeViewer: (UUID) -> DocumentViewerViewModel
}
