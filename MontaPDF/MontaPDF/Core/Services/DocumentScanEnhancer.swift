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

    func enhance(_ image: UIImage) -> UIImage {
        guard let input = CIImage(image: image) else { return image }

        let filter = CIFilter.documentEnhancer()
        filter.inputImage = input
        filter.amount = amount

        guard
            let output = filter.outputImage,
            let cgImage = Self.context.createCGImage(output, from: input.extent)
        else { return image }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
