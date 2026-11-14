//
//  DossierRowView.swift
//  MontaPDF
//

import SwiftUI

/// A dossier in the list: name, "X of Y" with a bar, and what is missing.
struct DossierRowView: View {
    let row: DossierRow

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            TemplateIcon(id: row.templateID)
            VStack(alignment: .leading, spacing: 6) {
                Text(row.name)
                    .font(.headline)
                if row.progress.required > 0, !row.isSent {
                    HStack(spacing: 8) {
                        Text("\(row.progress.addedRequired) of \(row.progress.required)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        ProgressView(value: Double(row.progress.addedRequired), total: Double(row.progress.required))
                            .frame(maxWidth: 140)
                            .accessibilityHidden(true)
                    }
                }
                DossierStatusLine(progress: row.progress, status: row.status)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

/// The line under the name: what is missing, ready to send, or when it was sent.
struct DossierStatusLine: View {
    let progress: DossierProgress
    let status: DossierStatus

    var body: some View {
        switch status {
        case .sent(let date):
            Label {
                Text("Sent on \(date.formatted(date: .abbreviated, time: .omitted))")
            } icon: {
                Image(systemName: "paperplane")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        case .readyToSend:
            Label("Ready to send", systemImage: "checkmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.green)
        case .inProgress:
            missingText
                .font(.subheadline)
        }
    }

    @ViewBuilder
    private var missingText: some View {
        let missing = progress.missingTitles
        if missing.count == 1, let title = missing.first {
            Text("Missing: \(title)")
                .foregroundStyle(.red)
        } else if missing.count > 1 {
            Text("\(missing.count) missing: \(missing.formatted(.list(type: .and)))")
                .foregroundStyle(.red)
        } else {
            Text("No documents yet")
                .foregroundStyle(.secondary)
        }
    }
}
