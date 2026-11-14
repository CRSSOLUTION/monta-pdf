//
//  ContentView.swift
//  MontaPDF
//
//  Created by Carlos Ribeiro on 10/31/26.
//

import SwiftUI

/// Shows Login when there is no session, otherwise the Dossiers and Documents tabs.
struct ContentView: View {
    let container: AppContainer
    @State private var dossiers: DossiersFeature
    @State private var documents: DocumentsFeature
    @State private var login: LoginViewModel
    @State private var isAccountPresented = false
    @State private var selectedTab: AppTab = .dossiers

    init(container: AppContainer) {
        self.container = container
        _dossiers = State(initialValue: container.makeDossiersFeature())
        _documents = State(initialValue: container.makeDocumentsFeature())
        _login = State(initialValue: container.makeLoginViewModel())
    }

    private var session: SessionManager { container.sessionManager }

    var body: some View {
        Group {
            if session.isSignedIn {
                TabView(selection: $selectedTab) {
                    DossierListView(
                        viewModel: dossiers.list,
                        makeDetail: dossiers.makeDetail,
                        makeViewer: dossiers.makeViewer
                    ) {
                        isAccountPresented = true
                    }
                    .tabItem { Label("Packets", systemImage: "folder") }
                    .tag(AppTab.dossiers)

                    DocumentListView(
                        viewModel: documents.list,
                        scanner: documents.scanner,
                        importer: documents.importer,
                        makeViewer: documents.makeViewer
                    )
                    .tabItem { Label("Documents", systemImage: "doc.text") }
                    .tag(AppTab.documents)
                }
                .sheet(isPresented: $isAccountPresented, onDismiss: reloadAfterAccount) {
                    AccountView(viewModel: container.makeAccountViewModel())
                }
            } else {
                LoginView(viewModel: login)
            }
        }
        .animation(.default, value: session.isSignedIn)
        .onChange(of: session.isSignedIn) { _, signedIn in
            if !signedIn {
                isAccountPresented = false
                selectedTab = .dossiers
            }
        }
        .task {
            await session.validateCredential()
        }
    }

    private func reloadAfterAccount() {
        dossiers.list.load()
        documents.list.load()
    }
}

#Preview {
    if let container = try? AppContainer(inMemory: true) {
        ContentView(container: container)
    } else {
        StorageErrorView {}
    }
}
