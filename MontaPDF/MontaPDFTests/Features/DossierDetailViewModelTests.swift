//
//  DossierDetailViewModelTests.swift
//  MontaPDFTests
//

import Foundation
import SwiftData
import Testing
import UIKit
@testable import MontaPDF

@MainActor
struct DossierDetailViewModelTests {
    private let repository: SwiftDataDossierRepository
    private let documents: SwiftDataDocumentRepository
    private let dossier: Dossier

    init() throws {
        let container = try makeInMemoryContainer()
        repository = SwiftDataDossierRepository(container: container)
        documents = SwiftDataDocumentRepository(container: container)
        let rental = try #require(DossierTemplates.template(id: .rental, localization: "pt-BR"))
        dossier = try repository.create(from: rental, name: "Apto Rua das Flores", coverName: "Ana Souza")
    }

    private func makeViewModel(dossierID: UUID? = nil) -> DossierDetailViewModel {
        let viewModel = DossierDetailViewModel(
            dossierID: dossierID ?? dossier.id,
            repository: repository,
            documents: documents,
            scanner: ScannerViewModel(
                repository: documents,
                pdfBuilder: FakePDFBuilder(),
                scanEnhancer: FakeScanEnhancer(),
                availability: FakeScannerAvailability()
            ),
            importer: ImportViewModel(repository: documents, pdfBuilder: FakePDFBuilder(), converter: FakeDocumentConverter())
        )
        viewModel.load()
        return viewModel
    }

    private func item(_ title: String, in viewModel: DossierDetailViewModel) throws -> DossierItem {
        try #require(viewModel.dossier?.sortedItems.first { $0.title == title })
    }

    @Test func loadsTheChecklistSplitByRequired() {
        let viewModel = makeViewModel()

        #expect(viewModel.dossier?.id == dossier.id)
        #expect(viewModel.requiredItems.count == 5)
        #expect(viewModel.optionalItems.map(\.title) == ["Certidão de casamento"])
    }

    @Test func missingDossierIsEmpty() {
        let viewModel = makeViewModel(dossierID: UUID())

        #expect(viewModel.isLoaded)
        #expect(viewModel.dossier == nil)
    }

    @Test func scanningFillsTheItemAndNamesTheDocumentAfterIt() async throws {
        let viewModel = makeViewModel()
        let guarantor = try item("Fiador: RG ou CNH", in: viewModel)

        viewModel.startAdding(guarantor)
        #expect(viewModel.isAddOptionsPresented)
        #expect(viewModel.targetItem?.id == guarantor.id)
        await viewModel.scan()
        #expect(viewModel.scanner.isScannerPresented)
        await viewModel.scanner.scannerFinished(with: [makeTestPage(), makeTestPage()])

        #expect(guarantor.state == .added)
        #expect(guarantor.document?.pageCount == 2)
        #expect(guarantor.document?.title == "Fiador: RG ou CNH")
        #expect(viewModel.targetItem == nil)
        #expect(try documents.fetchAll().count == 1)
    }

    @Test func aSavedDocumentWithoutATargetIsLeftAlone() async throws {
        let viewModel = makeViewModel()

        await viewModel.scanner.saveScannedPages([makeTestPage()])

        #expect(viewModel.requiredItems.allSatisfy { $0.state == .missing })
        #expect(try documents.fetchAll().count == 1)
    }

    @Test func onlyTheFirstImportedFileFillsTheItem() async throws {
        let viewModel = makeViewModel()
        let identity = try item("RG ou CNH", in: viewModel)
        viewModel.startAdding(identity)

        await viewModel.importer.importPhotos([makeTestImage().pngData() ?? Data()])
        viewModel.importer.savePreview()
        let first = identity.document?.id
        await viewModel.importer.importPhotos([makeTestImage().pngData() ?? Data()])
        viewModel.importer.savePreview()

        #expect(first != nil)
        #expect(identity.document?.id == first)
        #expect(try documents.fetchAll().count == 2)
    }

    @Test func choosingFromTheLibraryReusesADocument() throws {
        let existing = try documents.create(NewDocument(pdfData: Data("pdf".utf8), pageCount: 3, customTitle: "Holerites"))
        let viewModel = makeViewModel()
        let income = try item("Comprovante de renda", in: viewModel)
        viewModel.startAdding(income)

        viewModel.chooseFromLibrary()
        #expect(viewModel.isLibraryPresented)
        #expect(viewModel.libraryDocuments.map(\.title) == ["Holerites"])
        viewModel.libraryDocumentChosen(id: existing.id)

        #expect(viewModel.isLibraryPresented == false)
        #expect(income.document?.id == existing.id)
        #expect(existing.title == "Holerites", "A reused document keeps its name")
    }

    @Test func notApplicableAndBack() throws {
        let viewModel = makeViewModel()
        let marriage = try item("Certidão de casamento", in: viewModel)

        viewModel.setNotApplicable(true, for: marriage)
        #expect(marriage.state == .notApplicable)

        viewModel.setNotApplicable(false, for: marriage)
        #expect(marriage.state == .missing)
    }

    @Test func removeDocumentKeepsItInTheLibrary() throws {
        let document = try documents.create(NewDocument(pdfData: nil, pageCount: 1))
        let viewModel = makeViewModel()
        let identity = try item("RG ou CNH", in: viewModel)
        try repository.attach(document, to: identity)

        viewModel.removeDocument(from: identity)

        #expect(identity.state == .missing)
        #expect(try documents.fetchAll().count == 1)
    }

    @Test func renameItem() throws {
        let viewModel = makeViewModel()
        let identity = try item("RG ou CNH", in: viewModel)

        viewModel.startRename(identity)
        #expect(viewModel.isRenaming)
        #expect(viewModel.renameDraft == "RG ou CNH")
        viewModel.renameDraft = "CNH"
        viewModel.confirmRename()

        #expect(identity.title == "CNH")
    }

    @Test func addItemGoesToItsSection() {
        let viewModel = makeViewModel()
        viewModel.startAddingItem()
        #expect(viewModel.isAddingItem)

        viewModel.addItem(title: "Carta do fiador", isRequired: false)

        #expect(viewModel.isAddingItem == false)
        #expect(viewModel.optionalItems.map(\.title) == ["Certidão de casamento", "Carta do fiador"])
    }

    @Test func removeItemAfterConfirming() throws {
        let viewModel = makeViewModel()
        let guarantor = try item("Fiador: RG ou CNH", in: viewModel)

        viewModel.startRemove(guarantor)
        #expect(viewModel.isConfirmingRemove)
        viewModel.confirmRemove()

        #expect(viewModel.requiredItems.count == 4)
        #expect(viewModel.dossier?.progress.required == 4)
    }

    @Test func swipeToDeleteRemovesFromTheRightSection() {
        let viewModel = makeViewModel()

        viewModel.removeOptional(at: IndexSet(integer: 0))
        viewModel.removeRequired(at: IndexSet(integer: 0))

        #expect(viewModel.optionalItems.isEmpty)
        #expect(viewModel.requiredItems.first?.title == "Comprovante de renda")
    }

    @Test func moveKeepsRequiredBeforeOptional() {
        let viewModel = makeViewModel()
        viewModel.addItem(title: "Carta do fiador", isRequired: false)

        viewModel.moveRequired(from: IndexSet(integer: 4), to: 0)
        viewModel.moveOptional(from: IndexSet(integer: 1), to: 0)

        #expect(viewModel.requiredItems.map(\.title) == [
            "Fiador: RG ou CNH", "RG ou CNH", "Comprovante de renda", "Imposto de Renda", "Comprovante de residência"
        ])
        #expect(viewModel.optionalItems.map(\.title) == ["Carta do fiador", "Certidão de casamento"])
        #expect(viewModel.dossier?.sortedItems.map(\.order) == Array(0..<7))
    }

    @Test func movingMatchesSwiftUIMoveSemantics() {
        let items = ["a", "b", "c", "d"]

        #expect(DossierDetailViewModel.moving(items, from: IndexSet(integer: 3), to: 0) == ["d", "a", "b", "c"])
        #expect(DossierDetailViewModel.moving(items, from: IndexSet(integer: 0), to: 4) == ["b", "c", "d", "a"])
        #expect(DossierDetailViewModel.moving(items, from: IndexSet(integer: 0), to: 2) == ["b", "a", "c", "d"])
        #expect(DossierDetailViewModel.moving(items, from: IndexSet([0, 2]), to: 4) == ["b", "d", "a", "c"])
    }
}
