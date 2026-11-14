//
//  DossierListViewModel.swift
//  MontaPDF
//

import Foundation
import Observation

/// The Dossiers tab: the list, its two filters and the "new dossier" flow.
@Observable
@MainActor
final class DossierListViewModel {
    private(set) var rows: [DossierRow] = []
    var filter: DossierFilter = .inProgress
    var isCreating = false
    var errorMessage: String?

    private let repository: DossierRepository
    private let session: SessionManager
    private let templates: () -> [DossierTemplate]

    init(
        repository: DossierRepository,
        session: SessionManager,
        templates: @escaping () -> [DossierTemplate] = { DossierTemplates.all() }
    ) {
        self.repository = repository
        self.session = session
        self.templates = templates
    }

    var inProgressRows: [DossierRow] { rows.filter { !$0.isSent } }
    var sentRows: [DossierRow] { rows.filter(\.isSent) }

    var visibleRows: [DossierRow] {
        filter == .inProgress ? inProgressRows : sentRows
    }

    /// No dossier at all yet: the screen explains the idea instead of showing empty filters.
    var isEmpty: Bool { rows.isEmpty }

    var availableTemplates: [DossierTemplate] { templates() }

    /// Prefilled "name on cover": the name shared with Sign in with Apple, if any.
    var defaultCoverName: String { session.session?.name ?? "" }

    func load() {
        do {
            rows = try repository.fetchAll().map { DossierRow(dossier: $0) }
        } catch {
            errorMessage = String(localized: "Couldn't load your packets.")
        }
    }

    func startCreating() {
        isCreating = true
    }

    /// Creates the dossier, closes the sheet and returns its id so the screen can open it.
    func create(from template: DossierTemplate, name: String, coverName: String) -> UUID? {
        do {
            let dossier = try repository.create(from: template, name: name, coverName: coverName)
            isCreating = false
            filter = .inProgress
            load()
            return dossier.id
        } catch {
            errorMessage = String(localized: "Couldn't create the packet. Please try again.")
            return nil
        }
    }
}
