//
//  DossierTemplate.swift
//  MontaPDF
//

import Foundation

/// A ready-made checklist ("Aluguel de imóvel"). Creating a dossier copies its items,
/// so changing a template in a future version never changes existing dossiers.
nonisolated struct DossierTemplate: Identifiable, Equatable, Sendable {
    nonisolated enum ID: String, CaseIterable, Sendable {
        case rental, mortgage, job, school, blank
    }

    nonisolated enum Category: CaseIterable, Sendable {
        case realEstate, work, education, custom
    }

    nonisolated struct Item: Equatable, Sendable {
        let title: String
        let isRequired: Bool
    }

    let id: ID
    let category: Category
    let title: String
    let items: [Item]
}
