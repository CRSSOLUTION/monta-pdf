//
//  ConfirmWithAppleView.swift
//  MontaPDF
//

import AuthenticationServices
import SwiftUI

/// Last step of account deletion: confirm with Apple so the app can revoke the Apple ID link.
struct ConfirmWithAppleView: View {
    let viewModel: AccountViewModel
    @Environment(\.colorScheme) private var colorScheme

    init(viewModel: AccountViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 48))
                .foregroundStyle(.red)
                .accessibilityHidden(true)

            Text("Confirm with Apple")
                .font(.title2.bold())

            Text("To delete your account, confirm it's you with your Apple ID. This also removes Monta PDF from the apps that use your Apple ID.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if viewModel.isDeleting {
                ProgressView("Deleting your account...")
                    .frame(height: 52)
            } else {
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = []
                } onCompletion: { result in
                    Task { await viewModel.handleAppleConfirmation(result) }
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 52)

                Button("Cancel", role: .cancel) {
                    viewModel.cancelAppleConfirmation()
                }
            }
        }
        .padding(24)
    }
}

