//
//  SavedBannerView.swift
//  MontaPDF
//

import SwiftUI

/// "Document N saved" banner with a Rename shortcut. Hides itself after 5 seconds.
struct SavedBannerView: View {
    let banner: SavedBanner
    let onRename: () -> Void
    let onDismiss: () -> Void

    init(banner: SavedBanner, onRename: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.banner = banner
        self.onRename = onRename
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("\(banner.title) saved")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Spacer()
            Button("Rename", action: onRename)
                .font(.subheadline.weight(.semibold))
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .task(id: banner.id) {
            try? await Task.sleep(for: .seconds(5))
            onDismiss()
        }
    }
}
