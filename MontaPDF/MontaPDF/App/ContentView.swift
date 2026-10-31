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
        NavigationStack {
            Group {
                if viewModel.rows.isEmpty {
                    ContentUnavailableView(
                        "No documents yet",
                        systemImage: "doc.text",
                        description: Text("Scanned and imported documents will appear here.")
                    )
                } else {
                    List {
                        ForEach(viewModel.rows) { row in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.title)
                                    .font(.headline)
                                HStack(spacing: 8) {
                                    Text(row.createdAt, format: .dateTime.day().month().year())
                                    Text("\(row.pageCount) pages")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: viewModel.delete(at:))
                    }
                }
            }
            .navigationTitle("Documents")
            .toolbar {
                #if DEBUG
                ToolbarItem(placement: .primaryAction) {
                    Button("Add sample document", systemImage: "plus") {
                        viewModel.addSampleDocument()
                    }
                }
                #endif
            }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.dismissError() } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .task {
            viewModel.load()
        }
    }
}

#Preview {
    ContentView(viewModel: AppContainer(inMemory: true).makeDocumentListViewModel())
}
