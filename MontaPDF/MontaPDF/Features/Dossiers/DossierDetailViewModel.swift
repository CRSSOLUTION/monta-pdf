//
//  DossierDetailViewModel.swift
//  MontaPDF
//

import Foundation
import Observation

/// One dossier and its checklist.
@Observable
@MainActor
final class DossierDetailViewModel {
    let dossierID: UUID
    private(set) var dossier: Dossier?
    private(set) var isLoaded = false

    private let repository: DossierRepository

    init(dossierID: UUID, repository: DossierRepository) {
        self.dossierID = dossierID
        self.repository = repository
    }

    var requiredItems: [DossierItem] { dossier?.sortedItems.filter(\.isRequired) ?? [] }
    var optionalItems: [DossierItem] { dossier?.sortedItems.filter { !$0.isRequired } ?? [] }

    func load() {
        dossier = try? repository.dossier(id: dossierID)
        isLoaded = true
    }
}
