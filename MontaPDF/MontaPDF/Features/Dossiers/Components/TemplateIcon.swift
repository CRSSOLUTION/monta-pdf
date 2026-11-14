//
//  TemplateIcon.swift
//  MontaPDF
//

import SwiftUI

/// Gray rounded square with the template symbol, used in lists.
struct TemplateIcon: View {
    let id: DossierTemplate.ID?

    var body: some View {
        Image(systemName: id?.symbolName ?? "folder")
            .font(.body)
            .foregroundStyle(.secondary)
            .frame(width: 36, height: 36)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityHidden(true)
    }
}
