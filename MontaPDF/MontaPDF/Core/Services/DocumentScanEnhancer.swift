//
//  DocumentScanEnhancer.swift
//  MontaPDF
//

import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

nonisolated struct DocumentScanEnhancer: ScanEnhancing {
    /// Creating a CIContext is expensive, so one is shared. CIContext is thread-safe.
    private static let context = CIContext()

    /// 0 keeps the page as captured, 1 is the strongest cleanup.
    var amount: Float = 1

    /// Quality of the JPEG written after the cleanup.
    var jpegQuality: CGFloat = 0.9

    func enhance(_ page: PageImage) -> PageImage {
        guard let image = UIImage(data: page.data), let input = CIImage(image: image) else { return page }

        let filter = CIFilter.documentEnhancer()
        filter.inputImage = input
        filter.amount = amount

        guard
            let output = filter.outputImage,
            let cgImage = Self.context.createCGImage(output, from: input.extent)
        else { return page }

        let enhanced = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        guard let data = enhanced.jpegData(compressionQuality: jpegQuality) else { return page }
        return PageImage(data: data)
    }
}
