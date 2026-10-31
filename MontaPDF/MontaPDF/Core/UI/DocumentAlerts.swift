//
//  DocumentAlerts.swift
//  MontaPDF
//

import SwiftUI

extension View {
    /// "Rename Document" alert with a text field. Save is disabled while the name is empty.
    func renameDocumentAlert(
        isPresented: Binding<Bool>,
        name: Binding<String>,
        onSave: @escaping (String) -> Void
    ) -> some View {
        alert("Rename Document", isPresented: isPresented) {
            TextField("Name", text: name)
            Button("Cancel", role: .cancel) {}
            Button("Save") { onSave(name.wrappedValue) }
                .disabled(DocumentTitleRules.sanitize(name.wrappedValue).isEmpty)
        }
    }

    /// "Delete «name»?" confirmation.
    func deleteDocumentAlert(
        isPresented: Binding<Bool>,
        title: String,
        onDelete: @escaping () -> Void
    ) -> some View {
        alert(Text("Delete “\(title)”?"), isPresented: isPresented) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The document will be deleted from this iPhone and from iCloud.")
        }
    }
}
