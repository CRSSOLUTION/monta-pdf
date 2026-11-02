//
//  AppContainerTests.swift
//  MontaPDFTests
//

import Foundation
import Testing
@testable import MontaPDF

@MainActor
struct AppContainerTests {
    @Test func savingAnImportReloadsTheListAndShowsTheBanner() throws {
        let container = try AppContainer(inMemory: true)
        let feature = container.makeDocumentsFeature()
        let document = try container.documentRepository.create(NewDocument(pdfData: nil, pageCount: 1))

        // The importer reports a new document; the list must pick it up.
        feature.importer.onSaved?(document.id)

        #expect(feature.list.rows.map(\.id) == [document.id])
        #expect(feature.list.savedBanner?.id == document.id)
    }

    @Test func scannerIsWiredToTheList() throws {
        let container = try AppContainer(inMemory: true)
        let feature = container.makeDocumentsFeature()
        let document = try container.documentRepository.create(NewDocument(pdfData: nil, pageCount: 2))

        feature.scanner.onSaved?(document.id)

        #expect(feature.list.rows.first?.pageCount == 2)
    }

    @Test func viewerFactoryBuildsAViewerForTheDocument() throws {
        let container = try AppContainer(inMemory: true)
        let feature = container.makeDocumentsFeature()
        let document = try container.documentRepository.create(NewDocument(pdfData: Data("pdf".utf8), pageCount: 1))

        let viewer = feature.makeViewer(document.id)
        viewer.load()

        #expect(viewer.documentID == document.id)
        #expect(viewer.state == .ready)
    }
}
