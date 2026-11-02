//
//  ScanEnhancer.swift
//  MontaPDF
//

import UIKit

/// Cleans up scanned pages like a document scanner app: removes shadows and
/// folds, whitens the paper and darkens the text. Runs on the device.
nonisolated protocol ScanEnhancing: Sendable {
    func enhance(_ image: UIImage) -> UIImage
}
