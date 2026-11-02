//
//  ImagePDFBuilder.swift
//  MontaPDF
//

import UIKit

nonisolated struct ImagePDFBuilder: PDFBuilding {
    /// A4 width in points. Each page keeps the image proportions.
    static let pageWidth: CGFloat = 595.2

    var maxPixelDimension: CGFloat = 2200
    var jpegQuality: CGFloat = 0.75

    func makePDF(from pages: [PageImage]) throws -> Data {
        let images = pages.compactMap { UIImage(data: $0.data) }
        guard !images.isEmpty else { throw PDFBuilderError.noPages }

        let firstPage = CGRect(x: 0, y: 0, width: Self.pageWidth, height: Self.pageWidth * 1.414)
        let renderer = UIGraphicsPDFRenderer(bounds: firstPage)

        return renderer.pdfData { context in
            for image in images {
                let prepared = prepare(image)
                let pageRect = Self.pageRect(for: prepared.size)
                context.beginPage(withBounds: pageRect, pageInfo: [:])
                prepared.draw(in: pageRect)
            }
        }
    }

    static func pageRect(for imageSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return CGRect(x: 0, y: 0, width: pageWidth, height: pageWidth * 1.414)
        }
        let height = pageWidth * imageSize.height / imageSize.width
        return CGRect(x: 0, y: 0, width: pageWidth, height: height)
    }

    /// Downscales very large images and re-encodes them as JPEG to keep the PDF small.
    private func prepare(_ image: UIImage) -> UIImage {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let longestSide = max(pixelWidth, pixelHeight)

        var output = image
        if longestSide > maxPixelDimension {
            let factor = maxPixelDimension / longestSide
            let target = CGSize(width: pixelWidth * factor, height: pixelHeight * factor)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            output = UIGraphicsImageRenderer(size: target, format: format).image { _ in
                image.draw(in: CGRect(origin: .zero, size: target))
            }
        }

        if let data = output.jpegData(compressionQuality: jpegQuality), let jpeg = UIImage(data: data) {
            return jpeg
        }
        return output
    }
}
