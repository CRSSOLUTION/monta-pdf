//
//  SystemScannerAvailability.swift
//  MontaPDF
//

import AVFoundation
import VisionKit

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
