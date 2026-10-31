//
//  ContentView.swift
//  MontaPDF
//
//  Created by Carlos Ribeiro on 10/31/26.
//

import SwiftUI

struct ContentView: View {
    let viewModel: DocumentListViewModel

    var body: some View {
        DocumentListView(viewModel: viewModel)
    }
}

#Preview {
    ContentView(viewModel: AppContainer(inMemory: true).makeDocumentListViewModel())
}
