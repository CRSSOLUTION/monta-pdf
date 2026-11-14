//
//  DossierListView.swift
//  MontaPDF
//

import SwiftUI

/// The Dossiers tab: dossiers in progress or sent, and the button to start a new one.
struct DossierListView: View {
    @Bindable var viewModel: DossierListViewModel
    let makeDetail: (UUID) -> DossierDetailViewModel
    let onShowAccount: () -> Void
    @State private var path: [UUID] = []
    /// Opened once the "new dossier" sheet has closed.
    @State private var createdID: UUID?

    init(
        viewModel: DossierListViewModel,
        makeDetail: @escaping (UUID) -> DossierDetailViewModel,
        onShowAccount: @escaping () -> Void = {}
    ) {
        _viewModel = Bindable(viewModel)
        self.makeDetail = makeDetail
        self.onShowAccount = onShowAccount
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("Packets")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: onShowAccount) {
                            Label("Account", systemImage: "person.crop.circle")
                        }
                        .accessibilityIdentifier("accountButton")
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Button {
                        viewModel.startCreating()
                    } label: {
                        Label("New packet", systemImage: "plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .accessibilityIdentifier("newDossierButton")
                }
                .sheet(isPresented: $viewModel.isCreating, onDismiss: openCreatedDossier) {
                    NewDossierView(
                        templates: viewModel.availableTemplates,
                        defaultCoverName: viewModel.defaultCoverName
                    ) { template, name, coverName in
                        createdID = viewModel.create(from: template, name: name, coverName: coverName)
                    }
                }
                .navigationDestination(for: UUID.self) { id in
                    DossierDetailView(viewModel: makeDetail(id))
                }
                .onAppear {
                    viewModel.load()
                }
                .alert("Something went wrong", isPresented: isErrorPresented) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isEmpty {
            DossiersEmptyView()
        } else {
            List {
                Section {
                    Picker("Show", selection: $viewModel.filter) {
                        Text("In progress (\(viewModel.inProgressRows.count))").tag(DossierFilter.inProgress)
                        Text("Sent (\(viewModel.sentRows.count))").tag(DossierFilter.sent)
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                Section {
                    if viewModel.visibleRows.isEmpty {
                        Group {
                            if viewModel.filter == .inProgress {
                                Text("No packets in progress")
                            } else {
                                Text("No packets sent yet")
                            }
                        }
                        .foregroundStyle(.secondary)
                    }
                    ForEach(viewModel.visibleRows) { row in
                        NavigationLink(value: row.id) {
                            DossierRowView(row: row)
                        }
                        .accessibilityIdentifier("dossierRow")
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private func openCreatedDossier() {
        guard let id = createdID else { return }
        createdID = nil
        path.append(id)
    }

    private var isErrorPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}
