//
//  SystemCloudStatus.swift
//  MontaPDF
//

import Foundation

struct SystemCloudStatus: CloudStatusProviding {
    var isICloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
}
