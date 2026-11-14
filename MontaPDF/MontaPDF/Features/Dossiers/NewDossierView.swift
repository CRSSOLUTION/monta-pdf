//
//  NewDossierView.swift
//  MontaPDF
//

import SwiftUI

/// Sheet to start a dossier: pick a template, then name it.
struct NewDossierView: View {
    let templates: [DossierTemplate]
    let defaultCoverName: String
    let onCreate: (DossierTemplate, String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(DossierTemplate.Category.allCases, id: \.self) { category in
                    let matches = filtered.filter { $0.category == category }
                    if !matches.isEmpty {
                        Section(category.title) {
                            ForEach(matches) { template in
                                NavigationLink(value: template.id) {
                                    TemplateRowView(template: template)
                                }
                                .accessibilityIdentifier("templateRow_\(template.id.rawValue)")
                            }
                        }
                    }
                }
                Section {
                    EmptyView()
                } footer: {
                    Text("Templates are suggestions. Confirm the list with whoever asked for the documents.")
                }
            }
            .overlay {
                if filtered.isEmpty {
                    ContentUnavailableView.search(text: search)
                }
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search templates")
            .navigationTitle("New packet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(for: DossierTemplate.ID.self) { id in
                if let template = templates.first(where: { $0.id == id }) {
                    NewDossierFormView(template: template, defaultCoverName: defaultCoverName, onCreate: onCreate)
                }
            }
        }
    }

    private var filtered: [DossierTemplate] {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return templates }
        return templates.filter { template in
            template.title.localizedStandardContains(query)
                || template.items.contains { $0.title.localizedStandardContains(query) }
        }
    }
}

/// A template in the list: icon, title and how many documents it has.
private struct TemplateRowView: View {
    let template: DossierTemplate

    var body: some View {
        HStack(spacing: 12) {
            TemplateIcon(id: template.id)
            if template.items.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.title)
                    Text("Build your own list")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(template.title)
                Spacer(minLength: 8)
                Text("\(template.items.count) documents")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.tertiarySystemFill), in: Capsule())
            }
        }
    }
}
