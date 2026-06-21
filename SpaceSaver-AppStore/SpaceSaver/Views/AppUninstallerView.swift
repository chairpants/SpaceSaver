//
//  AppUninstallerView.swift
//  SpaceSaver (App Store Version)
//
//  Lists installed applications - sandbox version has limited functionality.
//  App Store version: Shows sandbox limitation notice.
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

            // Content
            if viewModel.filteredApps.isEmpty && !viewModel.isScanning {
                sandboxNoticeView
            } else {
                appTable
            }
        }
        .navigationTitle("App Uninstaller")
        .frame(minWidth: 600, minHeight: 400)
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

    // MARK: - Sandbox Notice View
    private var sandboxNoticeView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            VStack(spacing: 12) {
                Text("Feature Limited in App Store Version")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text("Due to App Sandbox restrictions, App Uninstaller cannot access the Applications folder or other system locations. This feature requires full disk access.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 450)

                Text("Download the non-App Store version for complete app uninstallation.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 450)
            }

            Button {
                // Open non-App Store download page
                if let url = URL(string: "https://github.com/yourusername/spacesaver/releases") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label("Get Full Version", systemImage: "arrow.up.right.square")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
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
                Label("Scan Unavailable", systemImage: "arrow.clockwise")
            }
            .disabled(true)

            Spacer()
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
}

#Preview {
    AppUninstallerView()
}
