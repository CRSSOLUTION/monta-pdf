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
    @State private var documentsViewModel: DocumentListViewModel
    @State private var isAccountPresented = false

    init(container: AppContainer) {
        self.container = container
        _documentsViewModel = State(initialValue: container.makeDocumentListViewModel())
    }

    private var session: SessionViewModel { container.sessionViewModel }

    var body: some View {
        Group {
            if session.isSignedIn {
                DocumentListView(viewModel: documentsViewModel) {
                    isAccountPresented = true
                }
                .sheet(isPresented: $isAccountPresented, onDismiss: documentsViewModel.load) {
                    AccountView(viewModel: container.makeAccountViewModel())
                }
            } else {
                LoginView(viewModel: session)
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
    ContentView(container: AppContainer(inMemory: true))
}
