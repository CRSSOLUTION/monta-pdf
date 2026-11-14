//
//  DossierItemRowView.swift
//  MontaPDF
//

import SwiftUI

/// A checklist line: status icon, title and its state.
struct DossierItemRowView: View {
    let item: DossierItem

    var body: some View {
        HStack(spacing: 12) {
            statusIcon
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(item.state == .notApplicable ? .secondary : .primary)
                stateText
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch item.state {
        case .added:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .missing:
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
        case .notApplicable:
            Image(systemName: "minus.circle.fill")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var stateText: some View {
        switch item.state {
        case .added:
            if let pages = item.document?.pageCount {
                Text("\(pages) pages")
                    .foregroundStyle(.secondary)
            }
        case .missing:
            if item.isRequired {
                Text("Missing")
                    .foregroundStyle(.red)
            } else {
                Text("Not added")
                    .foregroundStyle(.secondary)
            }
        case .notApplicable:
            Text("Doesn't apply")
                .foregroundStyle(.secondary)
        }
    }
}
