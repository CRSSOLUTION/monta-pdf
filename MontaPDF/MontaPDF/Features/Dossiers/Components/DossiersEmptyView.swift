//
//  DossiersEmptyView.swift
//  MontaPDF
//

import SwiftUI

/// First use: explains the idea in one sentence and three short steps.
struct DossiersEmptyView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Gather everything they asked for in one PDF", systemImage: "doc.on.doc")
        } description: {
            VStack(spacing: 16) {
                Text("Pick a template, like a rental or a new job, see what's missing and send it all at once.")
                VStack(alignment: .leading, spacing: 8) {
                    step("1. Pick a template")
                    step("2. Add each document")
                    step("3. Send a single PDF")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            }
        }
    }

    private func step(_ text: LocalizedStringKey) -> some View {
        Text(text)
    }
}
