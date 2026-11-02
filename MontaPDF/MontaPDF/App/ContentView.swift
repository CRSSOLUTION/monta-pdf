//
//  ContentView.swift
//  MontaPDF
//
//  Created by Carlos Ribeiro on 10/31/26.
//

import SwiftUI

/// Shows Login when there is no session, otherwise My Documents.
struct ContentView: View {
    let container: AppContainer
    @State private var documents: DocumentsFeature
    @State private var login: LoginViewModel
    @State private var isAccountPresented = false

    init(container: AppContainer) {
        self.container = container
        _documents = State(initialValue: container.makeDocumentsFeature())
        _login = State(initialValue: container.makeLoginViewModel())
    }

    private var session: SessionManager { container.sessionManager }

    var body: some View {
        Group {
            if session.isSignedIn {
                DocumentListView(
                    viewModel: documents.list,
                    scanner: documents.scanner,
                    importer: documents.importer,
                    makeViewer: documents.makeViewer
                ) {
                    isAccountPresented = true
                }
                .sheet(isPresented: $isAccountPresented, onDismiss: documents.list.load) {
                    AccountView(viewModel: container.makeAccountViewModel())
                }
            } else {
                LoginView(viewModel: login)
            }
        }
        .animation(.default, value: session.isSignedIn)
        .onChange(of: session.isSignedIn) { _, signedIn in
            if !signedIn { isAccountPresented = false }
        }
        .task {
            await session.validateCredential()
        }
    }
}

#Preview {
    if let container = try? AppContainer(inMemory: true) {
        ContentView(container: container)
    } else {
        StorageErrorView {}
    }
}
