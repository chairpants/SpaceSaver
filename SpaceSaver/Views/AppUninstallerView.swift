//
//  AppUninstallerView.swift
//  SpaceSaver
//
//  Lists installed applications and helps uninstall them
//  along with their related files (caches, preferences, etc.)
//

import SwiftUI

struct AppUninstallerView: View {
    @StateObject private var viewModel = AppUninstallerViewModel()

    // Sort order for the apps table — click a column header to sort.
    // Default: largest apps first.
    @State private var sortOrder: [KeyPathComparator<AppInfo>] = [
        KeyPathComparator(\.sizeInBytes, order: .reverse)
    ]

    /// Apps matching the search, sorted by the current column sort order.
    private var sortedApps: [AppInfo] {
        viewModel.filteredApps.sorted(using: sortOrder)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar

            Divider()

            // App list
            if viewModel.filteredApps.isEmpty && !viewModel.isScanning {
                emptyState
            } else {
                appTable
            }
        }
        .navigationTitle("App Uninstaller")
        .task {
            if viewModel.apps.isEmpty {
                await viewModel.scan()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search apps…", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(.bar)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button {
                Task { await viewModel.scan() }
            } label: {
                Label(viewModel.isScanning ? "Scanning…" : "Refresh", systemImage: "arrow.clockwise")
            }
            .disabled(viewModel.isScanning)

            Spacer()

            if viewModel.selectedApp != nil {
                Button(role: .destructive) {
                    viewModel.showUninstallConfirmation = true
                } label: {
                    Label("Uninstall", systemImage: "trash")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // MARK: - App Table
    private var appTable: some View {
        Table(sortedApps, sortOrder: $sortOrder) {
            TableColumn("App", value: \.name) { app in
                HStack(spacing: 8) {
                    // App icon — icon(forFile:) always returns a valid NSImage
                    let appIcon = NSWorkspace.shared.icon(forFile: app.url.path)
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.name)
                            .fontWeight(.medium)
                        if let version = app.version {
                            Text("v\(version)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .width(200)

            TableColumn("Size", value: \.sizeInBytes) { app in
                Text(app.formattedSize)
                    .monospacedDigit()
            }
            .width(100)

            TableColumn("Last Opened", value: \.sortDate) { app in
                Text(app.formattedLastOpened)
            }
            .width(120)

            TableColumn("Path") { app in
                Text(app.url.deletingLastPathComponent().path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            TableColumn("Actions") { app in
                HStack(spacing: 4) {
                    Button {
                        viewModel.revealInFinder(app)
                    } label: {
                        Image(systemName: "folder")
                    }
                    .buttonStyle(.borderless)

                    Button {
                        Task {
                            await viewModel.findRelatedFiles(for: app)
                        }
                    } label: {
                        Image(systemName: "link")
                    }
                    .buttonStyle(.borderless)
                    .help("Find related files")
                }
            }
            .width(80)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            if viewModel.isScanning {
                ProgressView("Scanning applications…")
                    .controlSize(.large)
            } else {
                Image(systemName: "app.dashed")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("No Applications Found")
                    .font(.title3)
                    .fontWeight(.semibold)

                if !viewModel.searchText.isEmpty {
                    Text("No apps match \"\(viewModel.searchText)\"")
                        .foregroundStyle(.secondary)
                }

                Button("Scan Again") {
                    Task { await viewModel.scan() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

