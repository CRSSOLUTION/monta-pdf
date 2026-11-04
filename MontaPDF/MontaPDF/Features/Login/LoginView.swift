//
//  LoginView.swift
//  MontaPDF
//

import AuthenticationServices
import SwiftUI

struct LoginView: View {
    let viewModel: LoginViewModel
    @Environment(\.colorScheme) private var colorScheme

    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Same artwork as the App Store icon, so the brand looks the same everywhere.
            Image("AppLogo")
                .resizable()
                .frame(width: 112, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(verbatim: "Monta PDF")
                    .font(.largeTitle.bold())
                Text("Scan, convert and keep your documents as PDFs.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            if !viewModel.isICloudAvailable {
                Label(
                    "iCloud is off. Your documents will stay only on this iPhone until you turn on iCloud.",
                    systemImage: "icloud.slash"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    viewModel.handleSignIn(AppleSignInMapper.map(result))
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .accessibilityIdentifier("signInWithAppleButton")
                .frame(height: 52)

                // Many people think they need an iCloud address: any Apple ID works,
                // including one created with a Gmail address.
                Text("Use your Apple ID. Works with any email, including Gmail. You can hide your email.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 16) {
                Link("Privacy Policy", destination: AppLinks.privacyPolicy)
                Link("Terms of Use", destination: AppLinks.termsOfUse)
            }
            .font(.footnote)
        }
        .padding(24)
        .alert(
            "Couldn't sign in. Please try again.",
            isPresented: Binding(
                get: { viewModel.signInFailed },
                set: { if !$0 { viewModel.dismissSignInError() } }
            )
        ) {
            Button("OK", role: .cancel) {}
        }
    }
}
