//
//  DossierDetailView.swift
//  MontaPDF
//

import SwiftUI

/// The checklist of a dossier: what is added, what is missing and what doesn't apply.
struct DossierDetailView: View {
    @Bindable var viewModel: DossierDetailViewModel

    var body: some View {
        Group {
            if let dossier = viewModel.dossier {
                checklist(for: dossier)
            } else if viewModel.isLoaded {
                ContentUnavailableView("Packet not found", systemImage: "folder.badge.questionmark")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.load() }
    }

    private func checklist(for dossier: Dossier) -> some View {
        List {
            Section {
                DossierProgressHeader(dossier: dossier)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
            }
            if !viewModel.requiredItems.isEmpty {
                Section("Required") {
                    ForEach(viewModel.requiredItems) { item in
                        DossierItemRowView(item: item)
                    }
                }
            }
            if !viewModel.optionalItems.isEmpty {
                Section("Optional items") {
                    ForEach(viewModel.optionalItems) { item in
                        DossierItemRowView(item: item)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(dossier.name)
    }
}

/// Template name and "X of Y required" with a bar.
private struct DossierProgressHeader: View {
    let dossier: Dossier

    var body: some View {
        let progress = dossier.progress
        VStack(alignment: .leading, spacing: 6) {
            if let id = DossierTemplate.ID(rawValue: dossier.templateID),
               let template = DossierTemplates.template(id: id) {
                Text(template.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if progress.required > 0 {
                Text("\(progress.addedRequired) of \(progress.required) required")
                    .font(.subheadline.weight(.semibold))
                    .accessibilityIdentifier("dossierProgress")
                ProgressView(value: Double(progress.addedRequired), total: Double(progress.required))
                    .accessibilityHidden(true)
            }
            if dossier.editedAfterSending {
                Label("Edited after sending", systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
