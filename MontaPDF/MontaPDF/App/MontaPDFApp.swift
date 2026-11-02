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
        let options = LaunchOptions()
        _startup = State(initialValue: AppStartup {
            let container = try AppContainer(inMemory: options.usesInMemoryStore)
            if options.startsSignedIn {
                container.sessionManager.signIn(with: AppleSignInCredential(
                    userID: "ui-test",
                    fullName: "UI Test",
                    email: "ui-test@example.com",
                    authorizationCode: nil
                ))
            }
            return container
        })
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
