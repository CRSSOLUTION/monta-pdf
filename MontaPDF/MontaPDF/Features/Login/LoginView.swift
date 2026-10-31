//
//  LoginView.swift
//  MontaPDF
//

import AuthenticationServices
import SwiftUI

struct LoginView: View {
    let viewModel: SessionViewModel
    @Environment(\.colorScheme) private var colorScheme

    init(viewModel: SessionViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.viewfinder.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white)
                .frame(width: 112, height: 112)
                .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 26))
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

            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                viewModel.handleSignIn(result)
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 52)

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
