//
//  DossierProgressTests.swift
//  MontaPDFTests
//

import Foundation
import Testing
@testable import MontaPDF

struct DossierProgressTests {
    private func item(_ title: String, required: Bool = true, _ state: DossierItemState) -> DossierItemSnapshot {
        DossierItemSnapshot(title: title, isRequired: required, state: state)
    }

    @Test func countsOnlyRequiredItemsInChecklistOrder() {
        let progress = DossierProgress(items: [
            item("RG ou CNH", .added),
            item("Comprovante de renda", .added),
            item("Imposto de Renda", .added),
            item("Comprovante de residência", .added),
            item("Fiador: RG ou CNH", .missing),
            item("Certidão de casamento", required: false, .missing)
        ])

        #expect(progress.addedRequired == 4)
        #expect(progress.required == 5)
        #expect(progress.missingTitles == ["Fiador: RG ou CNH"])
        #expect(progress.isComplete == false)
    }

    @Test func notApplicableItemsLeaveTheCount() {
        let progress = DossierProgress(items: [
            item("RG ou CNH", .added),
            item("Fiador: RG ou CNH", .notApplicable)
        ])

        #expect(progress.addedRequired == 1)
        #expect(progress.required == 1)
        #expect(progress.missingTitles.isEmpty)
        #expect(progress.isComplete)
    }

    @Test func missingOptionalItemsDontBlockCompletion() {
        let progress = DossierProgress(items: [
            item("RG ou CNH", .added),
            item("Certidão de casamento", required: false, .missing)
        ])

        #expect(progress.isComplete)
    }

    @Test func aDossierWithNothingAddedIsNeverComplete() {
        #expect(DossierProgress(items: []).isComplete == false)
        #expect(DossierProgress(items: [item("Fiador", .notApplicable)]).isComplete == false)
        #expect(DossierProgress(items: [item("Extra", required: false, .missing)]).isComplete == false)
    }

    @Test func onlyOptionalItemsAddedIsComplete() {
        let progress = DossierProgress(items: [item("Carta", required: false, .added)])

        #expect(progress.required == 0)
        #expect(progress.isComplete)
    }

    @Test func statusFollowsProgressUntilSent() {
        let missing = DossierProgress(items: [item("RG", .missing)])
        let complete = DossierProgress(items: [item("RG", .added)])
        let sentAt = Date(timeIntervalSince1970: 1_000)

        #expect(DossierStatus(progress: missing, sentAt: nil) == .inProgress)
        #expect(DossierStatus(progress: complete, sentAt: nil) == .readyToSend)
        #expect(DossierStatus(progress: missing, sentAt: sentAt) == .sent(sentAt))
    }
}
