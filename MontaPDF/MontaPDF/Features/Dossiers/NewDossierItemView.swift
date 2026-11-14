//
//  NewDossierItemView.swift
//  MontaPDF
//

import SwiftUI

/// Sheet to add an item the template doesn't have ("Carta do fiador").
struct NewDossierItemView: View {
    let onAdd: (String, Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var isRequired = true

    var body: some View {
        NavigationStack {
            Form {
                TextField("Item name", text: $title)
                    .accessibilityIdentifier("newItemNameField")
                Toggle("Required", isOn: $isRequired)
            }
            .navigationTitle("Add item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { onAdd(title, isRequired) }
                        .disabled(DocumentTitleRules.sanitize(title).isEmpty)
                        .accessibilityIdentifier("confirmAddItemButton")
                }
            }
        }
        .presentationDetents([.medium])
    }
}
