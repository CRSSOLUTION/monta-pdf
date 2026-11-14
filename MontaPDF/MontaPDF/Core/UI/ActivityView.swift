//
//  ActivityView.swift
//  MontaPDF
//

import SwiftUI

/// The iOS share sheet (WhatsApp, Mail, AirDrop...).
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    /// Called with `true` when the user sent or saved the file, `false` when they cancelled.
    var onComplete: ((Bool) -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let onComplete {
            controller.completionWithItemsHandler = { _, completed, _, _ in
                onComplete(completed)
            }
        }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
