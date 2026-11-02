//
//  ScannerViewModelTests.swift
//  MontaPDFTests
//

import Foundation
import PDFKit
import SwiftData
import Testing
import UIKit
@testable import MontaPDF

@MainActor
struct ScannerViewModelTests {
    private let repository: SwiftDataDocumentRepository

    init() throws {
        repository = SwiftDataDocumentRepository(container: try makeInMemoryContainer())
    }

    private func makeViewModel(
        builder: FakePDFBuilder = FakePDFBuilder(),
        enhancer: FakeScanEnhancer = FakeScanEnhancer(),
        availability: FakeScannerAvailability = FakeScannerAvailability()
    ) -> ScannerViewModel {
        ScannerViewModel(
            repository: repository,
            pdfBuilder: builder,
            scanEnhancer: enhancer,
            availability: availability
        )
    }

    @Test func scanOpensTheScannerWhenAvailable() async {
        let viewModel = makeViewModel()

        await viewModel.scanTapped()

        #expect(viewModel.isScannerPresented)
        #expect(viewModel.alert == nil)
    }

    @Test func scanWithCameraDeniedExplainsHowToFix() async {
        let viewModel = makeViewModel(availability: FakeScannerAvailability(cameraAccess: .denied))

        await viewModel.scanTapped()

        #expect(viewModel.isScannerPresented == false)
        #expect(viewModel.alert == .cameraDenied)
    }

    @Test func finishingTheScanSavesOneDocumentAndReportsIt() async throws {
        let viewModel = makeViewModel()
        var savedID: UUID?
        viewModel.onSaved = { savedID = $0 }
        viewModel.isScannerPresented = true

        await viewModel.scannerFinished(with: [makeTestPage(), makeTestPage(), makeTestPage()])

        #expect(viewModel.isScannerPresented == false)
        #expect(viewModel.isSaving == false)
        let stored = try #require(try repository.fetchAll().first)
        #expect(stored.pageCount == 3)
        let pdf = try #require(stored.pdfData.flatMap { PDFDocument(data: $0) })
        #expect(pdf.pageCount == 3)
        #expect(savedID == stored.id)
    }

    @Test func everyScannedPageIsEnhancedBeforeBuildingThePDF() async {
        let enhancer = FakeScanEnhancer()
        let viewModel = makeViewModel(enhancer: enhancer)

        await viewModel.saveScannedPages([makeTestPage(), makeTestPage(), makeTestPage()])

        #expect(enhancer.enhancedCount == 3)
    }

    @Test func failedSaveKeepsPagesAndRetrySavesThem() async throws {
        let viewModel = makeViewModel(builder: FakePDFBuilder(failures: 1))

        await viewModel.saveScannedPages([makeTestPage(), makeTestPage()])

        #expect(viewModel.alert == .saveFailed)
        #expect(try repository.fetchAll().isEmpty)

        await viewModel.retrySave()

        #expect(try repository.fetchAll().first?.pageCount == 2)
    }

    @Test func discardingPendingPagesMakesRetryDoNothing() async throws {
        let viewModel = makeViewModel(builder: FakePDFBuilder(failures: 1))
        await viewModel.saveScannedPages([makeTestPage()])

        viewModel.discardPendingPages()
        await viewModel.retrySave()

        #expect(try repository.fetchAll().isEmpty)
    }

    @Test func scannerErrorShowsAMessageAndClosesTheScanner() {
        let viewModel = makeViewModel()
        viewModel.isScannerPresented = true

        viewModel.scannerFailed(TestError())

        #expect(viewModel.isScannerPresented == false)
        #expect(viewModel.alert == .failed("Test failure"))
    }

    @Test func cancellingClosesTheScanner() {
        let viewModel = makeViewModel()
        viewModel.isScannerPresented = true

        viewModel.scannerCancelled()

        #expect(viewModel.isScannerPresented == false)
    }
}
