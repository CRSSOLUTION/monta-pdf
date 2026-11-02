//
//  StorageErrorView.swift
//  MontaPDF
//

import SwiftUI

/// Shown when the app can't open its storage at launch (instead of crashing).
struct StorageErrorView: View {
    let onRetry: () -> Void

    init(onRetry: @escaping () -> Void) {
        self.onRetry = onRetry
    }

    var body: some View {
        ContentUnavailableView {
            Label("Couldn't open your documents", systemImage: "exclamationmark.icloud")
        } description: {
            Text("Monta PDF couldn't open its storage. Try again, or restart the app. If it keeps happening, contact support.")
        } actions: {
            Button("Try Again", action: onRetry)
                .buttonStyle(.borderedProminent)
            Link("Contact Support", destination: AppLinks.support)
        }
    }
}
