//
//  DocumentScanEnhancerTests.swift
//  MontaPDFTests
//

import Testing
import UIKit
@testable import MontaPDF

struct DocumentScanEnhancerTests {
    @Test func keepsThePageSize() throws {
        let page = makeTestPage(width: 40, height: 60)

        let enhanced = DocumentScanEnhancer().enhance(page)

        let image = try #require(UIImage(data: enhanced.data))
        #expect(image.size.width * image.scale == 40)
        #expect(image.size.height * image.scale == 60)
    }

    @Test func zeroAmountStillReturnsAnImage() {
        let enhanced = DocumentScanEnhancer(amount: 0).enhance(makeTestPage())

        #expect(UIImage(data: enhanced.data) != nil)
    }

    @Test func unreadablePageIsReturnedUnchanged() {
        let page = PageImage(data: Data("not an image".utf8))

        #expect(DocumentScanEnhancer().enhance(page) == page)
    }
}
