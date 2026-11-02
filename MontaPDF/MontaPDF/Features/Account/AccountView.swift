//
//  AccountView.swift
//  MontaPDF
//

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
                    .accessibilityIdentifier("deleteAccountButton")
                } footer: {
                    Text("Signing out keeps your documents in your iCloud.")
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("accountDoneButton")
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
