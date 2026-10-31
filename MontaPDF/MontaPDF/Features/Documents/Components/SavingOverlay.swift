//
//  SavingOverlay.swift
//  MontaPDF
//

import SwiftUI

/// Dimmed overlay with "Building your PDF..." while a scan or import is saved.
struct SavingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.2).ignoresSafeArea()
            ProgressView("Building your PDF...")
                .padding(24)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
