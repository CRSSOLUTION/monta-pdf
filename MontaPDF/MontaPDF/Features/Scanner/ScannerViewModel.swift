//
//  ScannerViewModel.swift
//  MontaPDF
//

import Foundation
import Observation
import UIKit

nonisolated enum ScannerAlert: Identifiable, Equatable, Sendable {
    case scannerUnavailable
    case cameraDenied
    /// Building or saving the PDF failed; the pages are kept for a retry.
    case saveFailed
    case failed(String)

    var id: String {
        switch self {
        case .scannerUnavailable: "scannerUnavailable"
        case .cameraDenied: "cameraDenied"
        case .saveFailed: "saveFailed"
        case .failed(let message): "failed-\(message)"
        }
    }
}

/// Opens the VisionKit scanner and turns the captured pages into a saved PDF document.
@Observable
@MainActor
final class ScannerViewModel {
    var isScannerPresented = false
    private(set) var isSaving = false
    var alert: ScannerAlert?

    /// Called with the new document's id after a successful save.
    var onSaved: ((UUID) -> Void)?

    private let repository: DocumentRepository
    private let pdfBuilder: PDFBuilding
    private let scanEnhancer: ScanEnhancing
    private let availability: ScannerAvailability
    /// Pages kept after a failed save, so the user can try again without scanning again.
    private var pendingPages: [UIImage] = []

    init(
        repository: DocumentRepository,
        pdfBuilder: PDFBuilding,
        scanEnhancer: ScanEnhancing,
        availability: ScannerAvailability
    ) {
        self.repository = repository
        self.pdfBuilder = pdfBuilder
        self.scanEnhancer = scanEnhancer
        self.availability = availability
    }

    /// Called by the Scan button. Opens the scanner or explains why it can't.
    /// Uses sample pages on the simulator, which has no camera.
    func scanTapped() async {
        guard availability.isScannerSupported else {
            #if DEBUG && targetEnvironment(simulator)
            await saveScannedPages(SampleScan.pages())
            #else
            alert = .scannerUnavailable
            #endif
            return
        }
        guard availability.cameraAccess != .denied else {
            alert = .cameraDenied
            return
        }
        isScannerPresented = true
    }

    func scannerFinished(with pages: [UIImage]) async {
        isScannerPresented = false
        await saveScannedPages(pages)
    }

    func scannerCancelled() {
        isScannerPresented = false
    }

    func scannerFailed(_ error: Error) {
        isScannerPresented = false
        alert = .failed(error.localizedDescription)
    }

    func retrySave() async {
        await saveScannedPages(pendingPages)
    }

    func discardPendingPages() {
        pendingPages = []
    }

    func saveScannedPages(_ pages: [UIImage]) async {
        guard !pages.isEmpty, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            let builder = pdfBuilder
            let enhancer = scanEnhancer
            let data = try await Task.detached(priority: .userInitiated) {
                // Clean up the pages (shadows, folds, white paper) before building the PDF.
                try builder.makePDF(from: pages.map { enhancer.enhance($0) })
            }.value
            let document = try repository.create(NewDocument(pdfData: data, pageCount: pages.count))
            pendingPages = []
            onSaved?(document.id)
        } catch {
            pendingPages = pages
            alert = .saveFailed
        }
    }
}
