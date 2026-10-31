//
//  ImportPreviewView.swift
//  MontaPDF
//

import SwiftUI

/// Shows the converted PDF before saving it.
struct ImportPreviewView: View {
    let preview: ImportPreview
    let onSave: () -> Void
    let onKeepOriginal: () -> Void
    let onCancel: () -> Void

    @State private var currentPage = 1
    @State private var pageCount = 0

    init(
        preview: ImportPreview,
        onSave: @escaping () -> Void,
        onKeepOriginal: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.preview = preview
        self.onSave = onSave
        self.onKeepOriginal = onKeepOriginal
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            PDFKitView(data: preview.pdfData, currentPage: $currentPage, pageCount: $pageCount)
                .ignoresSafeArea(edges: .bottom)
                .safeAreaInset(edge: .bottom) { actions }
                .navigationTitle(preview.originalFileName ?? String(localized: "Preview"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: onCancel)
                    }
                }
        }
        .interactiveDismissDisabled()
    }

    private var actions: some View {
        VStack(spacing: 12) {
            if preview.isWord {
                Text("Does the document look right?")
                    .font(.headline)
            }
            Button(action: onSave) {
                Text("Save PDF")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if preview.isWord {
                Button("Keep Original", action: onKeepOriginal)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding()
        .background(.regularMaterial)
    }
}
