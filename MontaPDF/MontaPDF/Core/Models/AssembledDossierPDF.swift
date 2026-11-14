//
//  AssembledDossierPDF.swift
//  MontaPDF
//

import Foundation

/// The single PDF of a dossier and where each document starts.
nonisolated struct AssembledDossierPDF: Equatable, Sendable {
    nonisolated struct Entry: Equatable, Sendable {
        let title: String
        /// 1-based page where the document starts.
        let page: Int
    }

    let data: Data
    let pageCount: Int
    let entries: [Entry]
}
