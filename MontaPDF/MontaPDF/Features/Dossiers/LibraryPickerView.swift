//
//  LibraryPickerView.swift
//  MontaPDF
//

import SwiftUI

/// Sheet to fill a checklist item with a document already in the library.
struct LibraryPickerView: View {
    let documents: [LibraryDocument]
    let onChoose: (UUID) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if documents.isEmpty {
                    ContentUnavailableView("No documents yet", systemImage: "doc.text")
                } else {
                    List(documents) { document in
                        Button {
                            onChoose(document.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(document.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                HStack(spacing: 8) {
                                    Text("\(document.pageCount) pages")
                                    Text(document.createdAt, format: .dateTime.day().month().year())
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityIdentifier("libraryDocument")
                    }
                }
            }
            .navigationTitle("Choose from library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
