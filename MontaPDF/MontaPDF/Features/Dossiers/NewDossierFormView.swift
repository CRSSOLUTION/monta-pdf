//
//  NewDossierFormView.swift
//  MontaPDF
//

import SwiftUI

/// Second step of the sheet: the dossier name, the name on the cover and the items it will have.
struct NewDossierFormView: View {
    let template: DossierTemplate
    let onCreate: (DossierTemplate, String, String) -> Void
    @State private var name = ""
    @State private var coverName: String

    init(template: DossierTemplate, defaultCoverName: String, onCreate: @escaping (DossierTemplate, String, String) -> Void) {
        self.template = template
        self.onCreate = onCreate
        _coverName = State(initialValue: defaultCoverName)
    }

    var body: some View {
        Form {
            Section {
                TextField("Packet name", text: $name, prompt: Text(template.title))
                    .submitLabel(.done)
                    .accessibilityIdentifier("dossierNameField")
            } header: {
                Text("Packet name")
            } footer: {
                Text("Use a name that helps you recognize this packet.")
            }

            Section {
                TextField("Name on cover", text: $coverName)
                    .textContentType(.name)
                    .accessibilityIdentifier("coverNameField")
            } header: {
                Text("Name on cover")
            } footer: {
                Text("Appears on the PDF cover.")
            }

            Section {
                if template.items.isEmpty {
                    Text("No documents yet. You'll add them in the next step.")
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(template.items.enumerated()), id: \.offset) { _, item in
                    HStack {
                        Text(item.title)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 8)
                        if !item.isRequired {
                            Text("Optional")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(.tertiarySystemFill), in: Capsule())
                        }
                    }
                }
            } header: {
                Text("Documents included (\(template.items.count))")
            }
        }
        .navigationTitle(template.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                onCreate(template, name, coverName)
            } label: {
                Text("Create packet")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom, 8)
            .accessibilityIdentifier("createDossierButton")
        }
    }
}
