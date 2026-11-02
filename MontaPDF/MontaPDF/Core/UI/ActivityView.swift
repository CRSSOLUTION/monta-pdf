//
//  ActivityView.swift
//  MontaPDF
//

import SwiftUI

/// The iOS share sheet (WhatsApp, Mail, AirDrop...).
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
