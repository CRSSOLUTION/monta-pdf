//
//  ImportKindTests.swift
//  MontaPDFTests
//

import Testing
@testable import MontaPDF

struct ImportKindTests {
    @Test(arguments: ["photo.jpg", "photo.JPEG", "scan.png", "IMG_0001.heic"])
    func imagesAreImages(fileName: String) {
        #expect(ImportKind.classify(fileName: fileName) == .image)
    }

    @Test func pdfIsPDF() {
        #expect(ImportKind.classify(fileName: "Bill.pdf") == .pdf)
    }

    @Test(arguments: ["Contract.docx", "Old.DOC"])
    func wordFilesAreWord(fileName: String) {
        #expect(ImportKind.classify(fileName: fileName) == .word)
    }

    @Test(arguments: ["sheet.xlsx", "slides.pptx", "notes", "archive.zip"])
    func otherFormatsAreUnsupported(fileName: String) {
        #expect(ImportKind.classify(fileName: fileName) == .unsupported)
    }
}
