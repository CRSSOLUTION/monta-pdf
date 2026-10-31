//
//  ImagePDFBuilderTests.swift
//  MontaPDFTests
//

import Foundation
import PDFKit
import Testing
import UIKit
@testable import MontaPDF

struct ImagePDFBuilderTests {
    private let builder = ImagePDFBuilder()

    @Test func emptyListThrows() {
        #expect(throws: PDFBuilderError.self) {
            try builder.makePDF(from: [])
        }
    }

    @Test func everyImageBecomesAPageInOrder() throws {
        let images = [makeTestImage(width: 20, height: 30), makeTestImage(width: 40, height: 20)]

        let data = try builder.makePDF(from: images)

        let pdf = try #require(PDFDocument(data: data))
        #expect(pdf.pageCount == 2)
        let first = try #require(pdf.page(at: 0)).bounds(for: .mediaBox)
        let second = try #require(pdf.page(at: 1)).bounds(for: .mediaBox)
        #expect(first.height > first.width)
        #expect(second.width > second.height)
    }

    @Test func pageKeepsTheImageProportionsAtA4Width() {
        let rect = ImagePDFBuilder.pageRect(for: CGSize(width: 100, height: 200))

        #expect(rect.width == ImagePDFBuilder.pageWidth)
        #expect(rect.height == ImagePDFBuilder.pageWidth * 2)
    }
}
