//
//  DossierItemSnapshot.swift
//  MontaPDF
//

import Foundation

/// The values of a `DossierItem` that decide the dossier progress.
nonisolated struct DossierItemSnapshot: Equatable, Sendable {
    let title: String
    let isRequired: Bool
    let state: DossierItemState
}
