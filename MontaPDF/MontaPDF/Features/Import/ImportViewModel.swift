//
//  ImportViewModel.swift
//  MontaPDF
//

import Foundation
import Observation

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

    /// Only images: one PDF in selection order, shown in a preview.
    /// One PDF or Word file: saved as it is, or converted with a preview.
    /// Several files of other kinds: each one becomes its own document.
    func importFiles(_ files: [ImportedFile]) async {
        guard !files.isEmpty else { return }
        let kinds = files.map(\.kind)

        if kinds.allSatisfy({ $0 == .image }) {
            let pages = files.map { PageImage(data: $0.data) }
            let title = files.count == 1 ? DocumentTitleRules.title(fromFileName: files[0].name) : nil
            await buildImagePreview(pages, title: title, originalFileName: files.count == 1 ? files[0].name : nil)
            return
        }

        guard files.count == 1, let file = files.first else {
            await importEachFile(files)
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
        await buildImagePreview(photos.map { PageImage(data: $0) }, title: nil, originalFileName: nil)
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

    /// Saves every file as its own document, without previews.
    /// A Word file that can't be converted is kept as the original, so nothing is lost.
    private func importEachFile(_ files: [ImportedFile]) async {
        isConverting = true
        defer { isConverting = false }
        var skipped = 0
        for file in files {
            if await saveWithoutPreview(file) == false {
                skipped += 1
            }
        }
        if skipped > 0 {
            alert = .someFilesSkipped(skipped)
        }
    }

    private func saveWithoutPreview(_ file: ImportedFile) async -> Bool {
        let title = DocumentTitleRules.title(fromFileName: file.name)
        switch file.kind {
        case .pdf:
            let pageCount = PDFPageCounter.count(file.data)
            guard pageCount > 0 else { return false }
            return save(NewDocument(pdfData: file.data, pageCount: pageCount, customTitle: title, originalFileName: file.name))
        case .word:
            if let converted = try? await converter.convertToPDF(data: file.data, fileName: file.name) {
                return save(NewDocument(
                    pdfData: converted.data,
                    pageCount: converted.pageCount,
                    customTitle: title,
                    originalFileName: file.name,
                    originalData: file.data
                ))
            }
            return save(NewDocument(pdfData: nil, pageCount: 0, customTitle: title, originalFileName: file.name, originalData: file.data))
        case .image:
            let builder = pdfBuilder
            let page = PageImage(data: file.data)
            guard let data = try? await Task.detached(priority: .userInitiated, operation: {
                try builder.makePDF(from: [page])
            }).value else { return false }
            return save(NewDocument(pdfData: data, pageCount: PDFPageCounter.count(data), customTitle: title, originalFileName: file.name))
        case .unsupported:
            return false
        }
    }

    private func buildImagePreview(_ pages: [PageImage], title: String?, originalFileName: String?) async {
        guard !pages.isEmpty else {
            alert = .unsupported
            return
        }
        isConverting = true
        defer { isConverting = false }
        do {
            let builder = pdfBuilder
            let data = try await Task.detached(priority: .userInitiated) {
                try builder.makePDF(from: pages)
            }.value
            preview = ImportPreview(
                pdfData: data,
                // Unreadable pictures are skipped, so count the pages actually in the PDF.
                pageCount: PDFPageCounter.count(data),
                title: title,
                originalFileName: originalFileName,
                originalData: nil
            )
        } catch PDFBuilderError.noPages {
            alert = .unsupported
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

    @discardableResult
    private func save(_ newDocument: NewDocument) -> Bool {
        do {
            let document = try repository.create(newDocument)
            onSaved?(document.id)
            return true
        } catch {
            alert = .failed
            return false
        }
    }
}
