//
//  AccountView.swift
//  MontaPDF
//

import AuthenticationServices
import SwiftUI

struct AccountView: View {
    @State private var viewModel: AccountViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: AccountViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.name ?? String(localized: "Apple Account"))
                            .font(.headline)
                        if let email = viewModel.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("iCloud") {
                    LabeledContent("Documents", value: viewModel.documentCount, format: .number)
                    LabeledContent("Space used") {
                        Text(viewModel.storageBytes, format: .byteCount(style: .file))
                    }
                }

                Section {
                    Link(destination: AppLinks.privacyPolicy) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    Link(destination: AppLinks.termsOfUse) {
                        Label("Terms of Use", systemImage: "doc.plaintext")
                    }
                    Link(destination: AppLinks.support) {
                        Label("Support", systemImage: "envelope")
                    }
                    LabeledContent("Version", value: viewModel.appVersion)
                }

                Section {
                    Button("Sign Out") {
                        viewModel.isConfirmingSignOut = true
                    }
                    Button("Delete Account", role: .destructive) {
                        viewModel.startDeleteAccount()
                    }
                } footer: {
                    Text("Signing out keeps your documents in your iCloud.")
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Sign out?",
                isPresented: $viewModel.isConfirmingSignOut,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    viewModel.signOut()
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Delete your account?", isPresented: $viewModel.isConfirmingDelete) {
                TextField(viewModel.deleteConfirmationWord, text: $viewModel.deleteConfirmationText)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                Button("Delete Account", role: .destructive) {
                    viewModel.confirmDeleteAccount()
                }
                .disabled(!viewModel.canDeleteAccount)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All your documents will be deleted from this iPhone and from iCloud. This can't be undone. Type \(viewModel.deleteConfirmationWord) to confirm.")
            }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.dismissError() } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $viewModel.isConfirmingWithApple) {
                ConfirmWithAppleView(viewModel: viewModel)
                    .presentationDetents([.medium])
                    .interactiveDismissDisabled(viewModel.isDeleting)
            }
            .task {
                viewModel.load()
            }
        }
    }
}

/// Last step of account deletion: confirm with Apple so the app can revoke the Apple ID link.
private struct ConfirmWithAppleView: View {
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

