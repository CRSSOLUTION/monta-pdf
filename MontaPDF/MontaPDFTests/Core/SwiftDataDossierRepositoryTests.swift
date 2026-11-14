//
//  SwiftDataDossierRepositoryTests.swift
//  MontaPDFTests
//

import Foundation
import SwiftData
import Testing
@testable import MontaPDF

@MainActor
struct SwiftDataDossierRepositoryTests {
    private let container: ModelContainer
    private let repository: SwiftDataDossierRepository
    private let documents: SwiftDataDocumentRepository
    private let rental: DossierTemplate

    init() throws {
        container = try makeInMemoryContainer()
        repository = SwiftDataDossierRepository(container: container)
        documents = SwiftDataDocumentRepository(container: container)
        rental = try #require(DossierTemplates.template(id: .rental, localization: "pt-BR"))
    }

    private func makeDocument(pages: Int = 1) throws -> Document {
        try documents.create(NewDocument(pdfData: Data("pdf".utf8), pageCount: pages))
    }

    // MARK: - Create

    @Test func createCopiesTheTemplateItemsInOrder() throws {
        let dossier = try repository.create(from: rental, name: " Apto Rua das Flores ", coverName: " Ana Souza ")

        #expect(dossier.name == "Apto Rua das Flores")
        #expect(dossier.coverName == "Ana Souza")
        #expect(dossier.templateID == "rental")
        #expect(dossier.sortedItems.map(\.title) == rental.items.map(\.title))
        #expect(dossier.sortedItems.map(\.isRequired) == rental.items.map(\.isRequired))
        #expect(dossier.sortedItems.map(\.order) == Array(0..<rental.items.count))
        #expect(dossier.sortedItems.allSatisfy { $0.state == .missing })
        #expect(dossier.status == .inProgress)
        #expect(try repository.fetchAll().map(\.id) == [dossier.id])
    }

    @Test func emptyNameFallsBackToTheTemplateTitle() throws {
        let dossier = try repository.create(from: rental, name: "  ", coverName: "")

        #expect(dossier.name == "Aluguel de imóvel")
        #expect(dossier.coverName.isEmpty)
    }

    @Test func fetchAllListsNewestFirstAndFindsById() throws {
        let first = try repository.create(from: rental, name: "Primeiro", coverName: "")
        first.createdAt = referenceDate
        try container.mainContext.save()
        try repository.create(from: rental, name: "Segundo", coverName: "")

        #expect(try repository.fetchAll().map(\.name) == ["Segundo", "Primeiro"])
        #expect(try repository.dossier(id: first.id)?.name == "Primeiro")
        #expect(try repository.dossier(id: UUID()) == nil)
    }

    // MARK: - Items

    @Test func attachingDocumentsCompletesTheDossier() throws {
        let dossier = try repository.create(from: rental, name: "Apto", coverName: "")
        let required = dossier.sortedItems.filter(\.isRequired)

        for item in required.dropLast() {
            try repository.attach(try makeDocument(), to: item)
        }
        #expect(dossier.progress.addedRequired == 4)
        #expect(dossier.progress.required == 5)
        #expect(dossier.progress.missingTitles == ["Fiador: RG ou CNH"])
        #expect(dossier.status == .inProgress)

        try repository.attach(try makeDocument(), to: try #require(required.last))
        #expect(dossier.status == .readyToSend)
    }

    @Test func notApplicableTakesTheDocumentOutAndLeavesTheCount() throws {
        let dossier = try repository.create(from: rental, name: "Apto", coverName: "")
        let guarantor = try #require(dossier.sortedItems.first { $0.title == "Fiador: RG ou CNH" })
        let document = try makeDocument()
        try repository.attach(document, to: guarantor)

        try repository.setNotApplicable(true, for: guarantor)

        #expect(guarantor.state == .notApplicable)
        #expect(guarantor.document == nil)
        #expect(dossier.progress.required == 4)
        #expect(try documents.fetchAll().map(\.id) == [document.id])

        try repository.setNotApplicable(false, for: guarantor)
        #expect(guarantor.state == .missing)
        #expect(dossier.progress.required == 5)
    }

    @Test func attachingClearsNotApplicable() throws {
        let dossier = try repository.create(from: rental, name: "Apto", coverName: "")
        let item = try #require(dossier.sortedItems.first)
        try repository.setNotApplicable(true, for: item)

        try repository.attach(try makeDocument(), to: item)

        #expect(item.state == .added)
    }

    @Test func detachKeepsTheDocumentInTheLibrary() throws {
        let dossier = try repository.create(from: rental, name: "Apto", coverName: "")
        let item = try #require(dossier.sortedItems.first)
        let document = try makeDocument()
        try repository.attach(document, to: item)

        try repository.detach(item)

        #expect(item.state == .missing)
        #expect(try documents.fetchAll().map(\.id) == [document.id])
    }

    @Test func deletingADocumentEmptiesTheItemsThatUseIt() throws {
        let rentalDossier = try repository.create(from: rental, name: "Apto", coverName: "")
        let job = try #require(DossierTemplates.template(id: .job, localization: "pt-BR"))
        let jobDossier = try repository.create(from: job, name: "Emprego", coverName: "")
        let rentalID = try #require(rentalDossier.sortedItems.first)
        let jobID = try #require(jobDossier.sortedItems.first)
        let document = try makeDocument(pages: 2)
        try repository.attach(document, to: rentalID)
        try repository.attach(document, to: jobID)
        #expect(document.dossierItems?.count == 2)

        try documents.delete(document)

        #expect(rentalID.state == .missing)
        #expect(jobID.state == .missing)
        #expect(rentalDossier.sortedItems.count == rental.items.count)
    }

    @Test func addItemGoesToTheEndAndIgnoresEmptyTitles() throws {
        let dossier = try repository.create(from: rental, name: "Apto", coverName: "")

        let added = try repository.addItem(to: dossier, title: " Carta do fiador ", isRequired: false)
        let ignored = try repository.addItem(to: dossier, title: "   ", isRequired: true)

        #expect(added?.title == "Carta do fiador")
        #expect(added?.order == rental.items.count)
        #expect(ignored == nil)
        #expect(dossier.sortedItems.last?.title == "Carta do fiador")
        #expect(dossier.sortedItems.count == rental.items.count + 1)
    }

    @Test func blankListStartsEmptyAndGrows() throws {
        let blank = try #require(DossierTemplates.template(id: .blank, localization: "pt-BR"))
        let dossier = try repository.create(from: blank, name: "Visto", coverName: "")
        #expect(dossier.sortedItems.isEmpty)
        #expect(dossier.status == .inProgress)

        let item = try #require(try repository.addItem(to: dossier, title: "Passaporte", isRequired: true))
        #expect(item.order == 0)
        try repository.attach(try makeDocument(), to: item)

        #expect(dossier.status == .readyToSend)
    }

    @Test func renameItemKeepsTheOldTitleWhenEmpty() throws {
        let dossier = try repository.create(from: rental, name: "Apto", coverName: "")
        let item = try #require(dossier.sortedItems.first)

        try repository.rename(item, to: "  ")
        #expect(item.title == "RG ou CNH")

        try repository.rename(item, to: "RG")
        #expect(item.title == "RG")
    }

    @Test func reorderSavesTheNewOrder() throws {
        let dossier = try repository.create(from: rental, name: "Apto", coverName: "")
        let reversed = Array(dossier.sortedItems.reversed())

        try repository.reorder(reversed)

        #expect(dossier.sortedItems.map(\.title) == rental.items.reversed().map(\.title))
    }

    @Test func removeTakesTheItemOutButKeepsItsDocument() throws {
        let dossier = try repository.create(from: rental, name: "Apto", coverName: "")
        let item = try #require(dossier.sortedItems.first)
        let document = try makeDocument()
        try repository.attach(document, to: item)

        try repository.remove(item)

        #expect(dossier.sortedItems.count == rental.items.count - 1)
        #expect(dossier.sortedItems.first?.title == "Comprovante de renda")
        #expect(try documents.fetchAll().map(\.id) == [document.id])
    }

    // MARK: - Dossier

    @Test func renameAndCoverName() throws {
        let dossier = try repository.create(from: rental, name: "Apto", coverName: "")

        try repository.rename(dossier, to: "")
        #expect(dossier.name == "Apto")
        try repository.rename(dossier, to: "Apto Rua das Flores")
        try repository.setCoverName(" Ana Souza ", for: dossier)

        #expect(dossier.name == "Apto Rua das Flores")
        #expect(dossier.coverName == "Ana Souza")
    }

    @Test func editingASentDossierKeepsItSentWithAWarning() throws {
        let dossier = try repository.create(from: rental, name: "Apto", coverName: "")
        try repository.markSent(dossier, at: referenceDate)
        #expect(dossier.status == .sent(referenceDate))
        #expect(dossier.editedAfterSending == false)

        try repository.addItem(to: dossier, title: "Holerite de outubro", isRequired: true)

        #expect(dossier.status == .sent(referenceDate))
        #expect(dossier.editedAfterSending)

        try repository.reopen(dossier)
        #expect(dossier.status == .inProgress)
        #expect(dossier.editedAfterSending == false)
    }

    @Test func editingANotSentDossierDoesNotMarkItEdited() throws {
        let dossier = try repository.create(from: rental, name: "Apto", coverName: "")

        try repository.attach(try makeDocument(), to: try #require(dossier.sortedItems.first))

        #expect(dossier.editedAfterSending == false)
    }

    @Test func deleteRemovesItemsButKeepsDocuments() throws {
        let dossier = try repository.create(from: rental, name: "Apto", coverName: "")
        let document = try makeDocument()
        try repository.attach(document, to: try #require(dossier.sortedItems.first))

        try repository.delete(dossier)

        #expect(try repository.fetchAll().isEmpty)
        #expect(try container.mainContext.fetch(FetchDescriptor<DossierItem>()).isEmpty)
        #expect(try documents.fetchAll().map(\.id) == [document.id])
    }

    @Test func deleteAllRemovesEveryDossier() throws {
        try repository.create(from: rental, name: "Apto", coverName: "")
        try repository.create(from: rental, name: "Casa", coverName: "")

        try repository.deleteAll()

        #expect(try repository.fetchAll().isEmpty)
    }
}
