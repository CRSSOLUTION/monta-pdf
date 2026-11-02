//
//  CloudStatus.swift
//  MontaPDF
//

import Foundation

/// Tells whether iCloud is on, so we can warn that documents stay only on this device.
protocol CloudStatusProviding {
    var isICloudAvailable: Bool { get }
}
