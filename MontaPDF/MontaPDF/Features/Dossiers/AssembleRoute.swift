//
//  AssembleRoute.swift
//  MontaPDF
//

import Foundation

/// Opens the "Assemble and send" screen of a dossier.
nonisolated struct AssembleRoute: Hashable, Sendable {
    let dossierID: UUID
}
