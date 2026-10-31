//
//  MontaPDFApp.swift
//  MontaPDF
//
//  Created by Carlos Ribeiro on 10/31/26.
//

import SwiftUI

@main
struct MontaPDFApp: App {
    private let container: AppContainer

    init() {
        // Unit tests run inside the app, so they get an in-memory store without CloudKit.
        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        container = AppContainer(inMemory: isRunningTests)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(container: container)
        }
    }
}
