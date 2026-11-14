//
//  DossierPDFAssembler.swift
//  MontaPDF
//

import PDFKit
import UIKit

nonisolated protocol DossierPDFAssembling: Sendable {
    func assemble(_ input: DossierPDFInput) throws -> AssembledDossierPDF
}

/// Builds the single PDF of a dossier: an optional cover, an optional summary with
/// page numbers, then every document in checklist order. Everything runs on the device.
nonisolated struct DossierPDFAssembler: DossierPDFAssembling {
    /// A4 in points.
    static let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
    private static let margin: CGFloat = 56

    func assemble(_ input: DossierPDFInput) throws -> AssembledDossierPDF {
        guard !input.sections.isEmpty else { throw DossierPDFError.noDocuments }

        var documents: [PDFDocument] = []
        for section in input.sections {
            guard let document = PDFDocument(data: section.pdfData), document.pageCount > 0 else {
                throw DossierPDFError.unreadableDocument(section.title)
            }
            documents.append(document)
        }

        let entries = DossierPDFLayout.entries(
            titles: input.sections.map(\.title),
            pageCounts: documents.map(\.pageCount),
            includesCover: input.includesCover,
            includesSummary: input.includesSummary
        )

        let result = PDFDocument()
        if input.includesCover || input.includesSummary {
            let front = renderFrontPages(input: input, entries: entries)
            guard let frontDocument = PDFDocument(data: front) else { throw DossierPDFError.writeFailed }
            append(frontDocument, to: result)
        }
        for document in documents {
            append(document, to: result)
        }

        guard let data = result.dataRepresentation() else { throw DossierPDFError.writeFailed }
        return AssembledDossierPDF(data: data, pageCount: result.pageCount, entries: entries)
    }

    // MARK: - Private

    private func append(_ source: PDFDocument, to result: PDFDocument) {
        for index in 0..<source.pageCount {
            guard let page = source.page(at: index)?.copy() as? PDFPage else { continue }
            result.insert(page, at: result.pageCount)
        }
    }

    private func renderFrontPages(input: DossierPDFInput, entries: [AssembledDossierPDF.Entry]) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: Self.pageRect)
        return renderer.pdfData { context in
            if input.includesCover {
                context.beginPage()
                drawCover(input)
            }
            if input.includesSummary {
                let pages = stride(from: 0, to: entries.count, by: DossierPDFLayout.entriesPerSummaryPage)
                for start in pages {
                    context.beginPage()
                    let end = min(start + DossierPDFLayout.entriesPerSummaryPage, entries.count)
                    drawSummary(entries[start..<end], firstNumber: start + 1, showsTitle: start == 0)
                }
            }
        }
    }

    private func drawCover(_ input: DossierPDFInput) {
        let width = Self.pageRect.width - Self.margin * 2
        var y: CGFloat = 200

        UIColor.systemBlue.setFill()
        UIBezierPath(roundedRect: CGRect(x: Self.margin, y: y, width: 48, height: 4), cornerRadius: 2).fill()
        y += 28

        y += draw(input.name, font: .systemFont(ofSize: 30, weight: .bold), color: .black, at: y, width: width) + 10
        y += draw(input.templateTitle, font: .systemFont(ofSize: 16), color: .darkGray, at: y, width: width) + 36
        if !input.coverName.isEmpty {
            _ = draw(input.coverName, font: .systemFont(ofSize: 18, weight: .semibold), color: .black, at: y, width: width)
        }

        let date = input.date.formatted(date: .long, time: .omitted)
        _ = draw(date, font: .systemFont(ofSize: 13), color: .gray, at: Self.pageRect.height - Self.margin - 18, width: width)
    }

    private func drawSummary(_ entries: ArraySlice<AssembledDossierPDF.Entry>, firstNumber: Int, showsTitle: Bool) {
        let width = Self.pageRect.width - Self.margin * 2
        var y = Self.margin + 24
        if showsTitle {
            y += draw(String(localized: "Summary"), font: .systemFont(ofSize: 24, weight: .bold), color: .black, at: y, width: width) + 24
        }
        let font = UIFont.systemFont(ofSize: 14)
        for (offset, entry) in entries.enumerated() {
            let number = "\(firstNumber + offset). \(entry.title)"
            let page = "\(entry.page)"
            let pageWidth: CGFloat = 48
            _ = draw(page, font: font, color: .black, at: y, width: width, alignment: .right)
            let height = draw(number, font: font, color: .black, at: y, width: width - pageWidth)
            y += max(height, 18) + 10
        }
    }

    /// Draws text at the left margin and returns its height.
    private func draw(
        _ text: String,
        font: UIFont,
        color: UIColor,
        at y: CGFloat,
        width: CGFloat,
        alignment: NSTextAlignment = .left
    ) -> CGFloat {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byWordWrapping
        let attributed = NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ])
        let bounds = attributed.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        attributed.draw(with: CGRect(x: Self.margin, y: y, width: width, height: ceil(bounds.height)),
                        options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return ceil(bounds.height)
    }
}
