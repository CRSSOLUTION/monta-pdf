//
//  ScannerAlertsModifier.swift
//  MontaPDF
//

import SwiftUI

extension View {
    /// Alerts raised by the scanner: unavailable, camera denied, save failed.
    func scannerAlerts(_ scanner: ScannerViewModel) -> some View {
        modifier(ScannerAlertsModifier(scanner: scanner))
    }
}

private struct ScannerAlertsModifier: ViewModifier {
    let scanner: ScannerViewModel
    @Environment(\.openURL) private var openURL

    func body(content: Content) -> some View {
        content
            .alert(
                title(scanner.alert),
                isPresented: isPresented,
                presenting: scanner.alert
            ) { alert in
                actions(alert)
            } message: { alert in
                message(alert)
            }
    }

    private var isPresented: Binding<Bool> {
        Binding(
            get: { scanner.alert != nil },
            set: { if !$0 { scanner.alert = nil } }
        )
    }

    private func title(_ alert: ScannerAlert?) -> Text {
        switch alert ?? .failed("") {
        case .scannerUnavailable: Text("Scanner unavailable")
        case .cameraDenied: Text("Camera access needed")
        case .saveFailed: Text("Couldn't save. Please try again.")
        case .failed: Text("Something went wrong")
        }
    }

    @ViewBuilder
    private func actions(_ alert: ScannerAlert) -> some View {
        switch alert {
        case .cameraDenied:
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        case .saveFailed:
            Button("Try Again") {
                Task { await scanner.retrySave() }
            }
            Button("Discard", role: .destructive) {
                scanner.discardPendingPages()
            }
        case .scannerUnavailable, .failed:
            Button("OK", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func message(_ alert: ScannerAlert) -> some View {
        switch alert {
        case .scannerUnavailable: Text("This device can't scan documents.")
        case .cameraDenied: Text("Allow camera access in Settings to scan your documents.")
        case .saveFailed: Text("Your scanned pages were kept.")
        case .failed(let message): Text(message)
        }
    }
}
