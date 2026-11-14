//
//  DossierPDFInput.swift
//  MontaPDF
//

import Foundation

/// Everything needed to assemble a dossier PDF, as plain values.
nonisolated struct DossierPDFInput: Sendable {
    nonisolated struct Section: Equatable, Sendable {
        let title: String
        let pdfData: Data
    }

    let name: String
    let templateTitle: String
    let coverName: String
    let date: Date
    let includesCover: Bool
    let includesSummary: Bool
    /// Documents in checklist order.
    let sections: [Section]
}
