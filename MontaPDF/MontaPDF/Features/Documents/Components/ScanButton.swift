//
//  ScanButton.swift
//  MontaPDF
//

import SwiftUI

/// The big floating Scan button at the bottom of the list.
struct ScanButton: View {
    let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label("Scan", systemImage: "camera.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .shadow(radius: 4, y: 2)
        .accessibilityIdentifier("scanButton")
    }
}
