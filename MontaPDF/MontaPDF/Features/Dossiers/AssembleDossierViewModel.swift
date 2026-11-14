//
//  AssembleDossierViewModel.swift
//  MontaPDF
//

import Foundation
import Observation

/// "Assemble and send": builds the single PDF (cover, summary, documents), shares it
/// with the iOS share sheet and asks whether to mark the dossier as sent.
@Observable
@MainActor
final class AssembleDossierViewModel {
    let dossierID: UUID
    private(set) var dossier: Dossier?
    private(set) var assembled: AssembledDossierPDF?
    private(set) var isAssembling = false
    var errorMessage: String?
    var shareItem: ShareItem?
    var isAskingSent = false
    var isPreviewPresented = false
    /// Set by the share sheet: the user sent or saved the file (not cancelled).
    private var shareCompleted = false

    private let repository: DossierRepository
    private let assembler: DossierPDFAssembling
    private let exporter: DocumentExporting
    private let now: () -> Date

    init(
        dossierID: UUID,
        repository: DossierRepository,
        assembler: DossierPDFAssembling,
        exporter: DocumentExporting,
        now: @escaping () -> Date = { Date() }
    ) {
        self.dossierID = dossierID
        self.repository = repository
        self.assembler = assembler
        self.exporter = exporter
        self.now = now
    }

    var includesCover: Bool { dossier?.includesCover ?? true }
    var includesSummary: Bool { dossier?.includesSummary ?? true }

    /// e.g. "Apto Rua das Flores - Ana Souza.pdf"
    var fileName: String {
        guard let dossier else { return DocumentTitleRules.fileName(for: "") }
        let title = dossier.coverName.isEmpty ? dossier.name : "\(dossier.name) - \(dossier.coverName)"
        return DocumentTitleRules.fileName(for: title)
    }

    /// Added items whose PDF isn't on the device (still downloading from iCloud,
    /// or a Word file kept without a PDF). They are left out of the PDF.
    var unavailableTitles: [String] {
        addedItems.filter { $0.document?.pdfData == nil }.map(\.title)
    }

    func load() async {
        dossier = try? repository.dossier(id: dossierID)
        await assemble()
    }

    func setIncludesCover(_ value: Bool) async {
        await setOptions(includesCover: value, includesSummary: includesSummary)
    }

    func setIncludesSummary(_ value: Bool) async {
        await setOptions(includesCover: includesCover, includesSummary: value)
    }

    func assemble() async {
        guard let dossier else { return }
        let input = makeInput(for: dossier)
        let assembler = assembler
        isAssembling = true
        defer { isAssembling = false }
        do {
            assembled = try await Task.detached(priority: .userInitiated) {
                try assembler.assemble(input)
            }.value
        } catch {
            assembled = nil
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sharing

    func share() {
        guard let assembled else { return }
        do {
            shareCompleted = false
            shareItem = ShareItem(url: try exporter.export(assembled.data, fileName: fileName))
        } catch {
            errorMessage = String(localized: "Couldn't create the PDF. Please try again.")
        }
    }

    /// Called by the share sheet when the user picks an action or cancels.
    func shareFinished(completed: Bool) {
        shareCompleted = completed
        if completed {
            shareItem = nil
        }
    }

    /// Once the share sheet is gone, ask whether the dossier was sent.
    func shareSheetDismissed() {
        guard shareCompleted, dossier?.sentAt == nil else { return }
        shareCompleted = false
        isAskingSent = true
    }

    func markSent() {
        guard let dossier else { return }
        do {
            try repository.markSent(dossier, at: now())
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private

    private var addedItems: [DossierItem] {
        dossier?.sortedItems.filter { $0.state == .added } ?? []
    }

    private func setOptions(includesCover: Bool, includesSummary: Bool) async {
        guard let dossier else { return }
        do {
            try repository.setOptions(includesCover: includesCover, includesSummary: includesSummary, for: dossier)
        } catch {
            errorMessage = error.localizedDescription
        }
        await assemble()
    }

    private func makeInput(for dossier: Dossier) -> DossierPDFInput {
        let templateTitle = DossierTemplate.ID(rawValue: dossier.templateID)
            .flatMap { DossierTemplates.template(id: $0)?.title } ?? ""
        let sections = addedItems.compactMap { item -> DossierPDFInput.Section? in
            guard let data = item.document?.pdfData else { return nil }
            return DossierPDFInput.Section(title: item.title, pdfData: data)
        }
        return DossierPDFInput(
            name: dossier.name,
            templateTitle: templateTitle,
            coverName: dossier.coverName,
            date: now(),
            includesCover: dossier.includesCover,
            includesSummary: dossier.includesSummary,
            sections: sections
        )
    }
}
