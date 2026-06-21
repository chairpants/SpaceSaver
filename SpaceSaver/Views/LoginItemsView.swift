//
//  LoginItemsView.swift
//  SpaceSaver
//
//  Manages login items and launch agents.
//  Uses SMAppService (macOS 13+) for the app's own login item,
//  and reads LaunchAgents for user-level services.
//

import SwiftUI

struct LoginItemsView: View {
    @StateObject private var viewModel = LoginItemsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Login Items")
                    .font(.headline)

                Spacer()

                Button {
                    Task { await viewModel.loadLoginItems() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.bar)

            Divider()

            // Items list
            if viewModel.loginItems.isEmpty {
                emptyState
            } else {
                itemsList
            }
        }
        .navigationTitle("Login Items")
        .task {
            if viewModel.loginItems.isEmpty {
                await viewModel.loadLoginItems()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Items List
    private var itemsList: some View {
        List {
            ForEach(viewModel.loginItems) { item in
                HStack(spacing: 12) {
                    // Toggle
                    Toggle("", isOn: Binding(
                        get: { item.isEnabled },
                        set: { _ in
                            Task { await viewModel.toggleItem(item) }
                        }
                    ))
                    .toggleStyle(.switch)

                    // Icon based on kind
                    Image(systemName: iconForKind(item.kind))
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 24)

                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .fontWeight(.medium)

                        Text(item.kind.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Status badge
                    Text(item.isEnabled ? "Enabled" : "Disabled")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.isEnabled ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                        .clipShape(Capsule())
                        .foregroundStyle(item.isEnabled ? .green : .secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.inset)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                ProgressView("Loading login items…")
                    .controlSize(.large)
            } else {
                Image(systemName: "lock.desktopcomputer")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("No Login Items Found")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Login items and launch agents will appear here.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("Tip: You can also manage login items in System Settings → General → Login Items")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    // MARK: - Helper
    private func iconForKind(_ kind: LoginItem.Kind) -> String {
        switch kind {
        case .app:         return "app"
        case .launchAgent: return "gearshape"
        case .launchDaemon: return "gearshape.2"
        }
    }
}

