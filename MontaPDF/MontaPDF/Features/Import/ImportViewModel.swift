//
//  ImportViewModel.swift
//  MontaPDF
//

import Foundation
import Observation
import UIKit

/// A converted file waiting for the user to confirm it.
nonisolated struct ImportPreview: Identifiable, Sendable {
    let id = UUID()
    let pdfData: Data
    let pageCount: Int
    /// Custom title (from the file name). `nil` gives an automatic "Document N".
    let title: String?
    let originalFileName: String?
    /// Kept only for Word files.
    let originalData: Data?

    var isWord: Bool { originalData != nil }
}

nonisolated enum ImportAlert: Identifiable, Equatable, Sendable {
    case unsupported
    /// Word conversion failed; the user can still keep the original.
    case conversionFailed
    case failed

    var id: Self { self }
}

@Observable
@MainActor
final class ImportViewModel {
    private(set) var isConverting = false
    var preview: ImportPreview?
    var alert: ImportAlert?

    private let repository: DocumentRepository
    private let pdfBuilder: PDFBuilding
    private let converter: DocumentConverter
    /// Called with the new document's id after a successful save.
    var onSaved: ((UUID) -> Void)?
    /// Word file whose conversion failed, so "Keep Original" still works.
    private var failedWordFile: ImportedFile?

    init(
        repository: DocumentRepository,
        pdfBuilder: PDFBuilding,
        converter: DocumentConverter
    ) {
        self.repository = repository
        self.pdfBuilder = pdfBuilder
        self.converter = converter
    }

    // MARK: - Entry points

    func importFiles(at urls: [URL]) async {
        do {
            await importFiles(try ImportedFile.read(urls))
        } catch {
            alert = .failed
        }
    }

    /// Images go into one PDF in selection order; PDF and Word must be picked alone.
    func importFiles(_ files: [ImportedFile]) async {
        guard !files.isEmpty else { return }
        let kinds = files.map(\.kind)

        if kinds.allSatisfy({ $0 == .image }) {
            let images = files.compactMap { UIImage(data: $0.data) }
            let title = files.count == 1 ? DocumentTitleRules.title(fromFileName: files[0].name) : nil
            await buildImagePreview(images, title: title, originalFileName: files.count == 1 ? files[0].name : nil)
            return
        }

        guard files.count == 1, let file = files.first else {
            alert = .unsupported
            return
        }

        switch file.kind {
        case .pdf:
            savePDFAsIs(file)
        case .word:
            await convertWord(file)
        case .image, .unsupported:
            alert = .unsupported
        }
    }

    /// Photos picked from the library, in selection order.
    func importPhotos(_ photos: [Data]) async {
        let images = photos.compactMap { UIImage(data: $0) }
        await buildImagePreview(images, title: nil, originalFileName: nil)
    }

    // MARK: - Preview actions

    func savePreview() {
        guard let preview else { return }
        save(NewDocument(
            pdfData: preview.pdfData,
            pageCount: preview.pageCount,
            customTitle: preview.title,
            originalFileName: preview.originalFileName,
            originalData: preview.originalData
        ))
        self.preview = nil
    }

    /// Saves only the Word file, without the converted PDF.
    func keepOriginal() {
        if let preview, let data = preview.originalData {
            saveOriginalOnly(data: data, fileName: preview.originalFileName ?? "Document.docx")
            self.preview = nil
        } else if let file = failedWordFile {
            saveOriginalOnly(data: file.data, fileName: file.name)
            failedWordFile = nil
        }
    }

    func cancelPreview() {
        preview = nil
        failedWordFile = nil
    }

    // MARK: - Private

    private func buildImagePreview(_ images: [UIImage], title: String?, originalFileName: String?) async {
        guard !images.isEmpty else {
            alert = .unsupported
            return
        }
        isConverting = true
        defer { isConverting = false }
        do {
            let builder = pdfBuilder
            let data = try await Task.detached(priority: .userInitiated) {
                try builder.makePDF(from: images)
            }.value
            preview = ImportPreview(
                pdfData: data,
                pageCount: images.count,
                title: title,
                originalFileName: originalFileName,
                originalData: nil
            )
        } catch {
            alert = .failed
        }
    }

    private func convertWord(_ file: ImportedFile) async {
        isConverting = true
        defer { isConverting = false }
        do {
            let converted = try await converter.convertToPDF(data: file.data, fileName: file.name)
            preview = ImportPreview(
                pdfData: converted.data,
                pageCount: converted.pageCount,
                title: DocumentTitleRules.title(fromFileName: file.name),
                originalFileName: file.name,
                originalData: file.data
            )
        } catch {
            failedWordFile = file
            alert = .conversionFailed
        }
    }

    private func savePDFAsIs(_ file: ImportedFile) {
        let pageCount = PDFPageCounter.count(file.data)
        guard pageCount > 0 else {
            alert = .unsupported
            return
        }
        save(NewDocument(
            pdfData: file.data,
            pageCount: pageCount,
            customTitle: DocumentTitleRules.title(fromFileName: file.name),
            originalFileName: file.name
        ))
    }

    private func saveOriginalOnly(data: Data, fileName: String) {
        save(NewDocument(
            pdfData: nil,
            pageCount: 0,
            customTitle: DocumentTitleRules.title(fromFileName: fileName),
            originalFileName: fileName,
            originalData: data
        ))
    }

    private func save(_ newDocument: NewDocument) {
        do {
            let document = try repository.create(newDocument)
            onSaved?(document.id)
        } catch {
            alert = .failed
        }
    }
}
