//
//  DossierRow.swift
//  MontaPDF
//

import Foundation

/// What a row of the dossier list shows.
nonisolated struct DossierRow: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let templateID: DossierTemplate.ID?
    let progress: DossierProgress
    let status: DossierStatus

    var isSent: Bool {
        if case .sent = status { return true }
        return false
    }
}

extension DossierRow {
    @MainActor
    init(dossier: Dossier) {
        self.init(
            id: dossier.id,
            name: dossier.name,
            templateID: DossierTemplate.ID(rawValue: dossier.templateID),
            progress: dossier.progress,
            status: dossier.status
        )
    }
}
