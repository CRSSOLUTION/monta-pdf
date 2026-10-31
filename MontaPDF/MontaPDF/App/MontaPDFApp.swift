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
    @State private var viewModel: DocumentListViewModel

    init() {
        // Unit tests run inside the app, so they get an in-memory store without CloudKit.
        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        let container = AppContainer(inMemory: isRunningTests)
        self.container = container
        _viewModel = State(initialValue: container.makeDocumentListViewModel())
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
