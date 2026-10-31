//
//  ActivityView.swift
//  MontaPDF
//

import SwiftUI

/// Identifiable wrapper so a file URL can drive `.sheet(item:)`.
nonisolated struct ShareItem: Identifiable, Equatable, Sendable {
    let id = UUID()
    let url: URL
}

/// The iOS share sheet (WhatsApp, Mail, AirDrop...).
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
