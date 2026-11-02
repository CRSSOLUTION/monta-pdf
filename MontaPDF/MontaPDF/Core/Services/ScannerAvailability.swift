//
//  ScannerAvailability.swift
//  MontaPDF
//

import Foundation

/// Answers whether the document scanner can be opened right now.
protocol ScannerAvailability {
    var isScannerSupported: Bool { get }
    var cameraAccess: CameraAccess { get }
}
