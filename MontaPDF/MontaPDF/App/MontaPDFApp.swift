//
//  MontaPDFApp.swift
//  MontaPDF
//
//  Created by Carlos Ribeiro on 10/31/26.
//

import SwiftUI

@main
struct MontaPDFApp: App {
    @State private var startup: AppStartup

    init() {
        // Unit tests run inside the app, so they get an in-memory store without CloudKit.
        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        _startup = State(initialValue: AppStartup { try AppContainer(inMemory: isRunningTests) })
    }

    var body: some Scene {
        WindowGroup {
            if let container = startup.container {
                ContentView(container: container)
            } else {
                StorageErrorView(onRetry: startup.start)
            }
        }
    }
}
