//
//  ScannerAvailability.swift
//  MontaPDF
//

import AVFoundation
import VisionKit

nonisolated enum CameraAccess: Sendable {
    case allowed
    case notDetermined
    case denied
}

/// Answers whether the document scanner can be opened right now.
protocol ScannerAvailability {
    var isScannerSupported: Bool { get }
    var cameraAccess: CameraAccess { get }
}

struct SystemScannerAvailability: ScannerAvailability {
    var isScannerSupported: Bool {
        VNDocumentCameraViewController.isSupported
    }

    var cameraAccess: CameraAccess {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: .allowed
        case .notDetermined: .notDetermined
        default: .denied
        }
    }
}
