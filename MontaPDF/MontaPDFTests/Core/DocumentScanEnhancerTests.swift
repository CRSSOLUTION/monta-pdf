//
//  DocumentScanEnhancerTests.swift
//  MontaPDFTests
//

import Testing
import UIKit
@testable import MontaPDF

struct DocumentScanEnhancerTests {
    @Test func keepsThePageSizeAndOrientation() {
        let page = makeTestImage(width: 40, height: 60)

        let enhanced = DocumentScanEnhancer().enhance(page)

        #expect(enhanced.size == page.size)
        #expect(enhanced.imageOrientation == page.imageOrientation)
    }

    @Test func zeroAmountStillReturnsAnImage() {
        let page = makeTestImage()

        let enhanced = DocumentScanEnhancer(amount: 0).enhance(page)

        #expect(enhanced.size == page.size)
    }
}
