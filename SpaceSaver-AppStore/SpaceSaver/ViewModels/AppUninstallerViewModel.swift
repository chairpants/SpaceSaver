//
//  AppUninstallerViewModel.swift
//  SpaceSaver (App Store Version)
//
//  ViewModel for the App Uninstaller feature.
//  Lists installed apps - sandbox version has limited functionality.
//

import SwiftUI

// MARK: - AppInfo
// Represents an installed application with its metadata.
struct AppInfo: Identifiable {
    let id = UUID()
    let url: URL                  // Path to the .app bundle
    let name: String              // Display name
    let bundleIdentifier: String? // e.g., "com.apple.Safari"
    let version: String?          // e.g., "17.0"
    let sizeInBytes: Int64         // App bundle size
    let lastOpened: Date?         // Last launch date
    var isSelected: Bool = false

    var formattedSize: String {
        FileSizeFormatter.string(fromBytes: sizeInBytes)
    }

    var formattedLastOpened: String {
        guard let date = lastOpened else { return "Never" }
        return date.formatted(.relative(presentation: .named))
    }

    /// Non-optional date for table column sorting.
    var sortDate: Date {
        lastOpened ?? .distantPast
    }
}

@MainActor
final class AppUninstallerViewModel: ObservableObject {

    // MARK: - Published State
    @Published var apps: [AppInfo] = []
    @Published var isScanning = false
    @Published var errorMessage: String?
    @Published var showUninstallConfirmation = false
    @Published var isUninstalling = false
    @Published var relatedFiles: [URL] = []  // Files related to selected app
    @Published var searchText: String = ""
    @Published var showSandboxNotice = false

    // MARK: - Computed Properties

    /// Filtered apps matching search text
    var filteredApps: [AppInfo] {
        guard !searchText.isEmpty else { return apps }
        return apps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Selected app (for showing related files)
    var selectedApp: AppInfo? {
        apps.first(where: { $0.isSelected })
    }

    // MARK: - Sandbox Notice
    var sandboxNotice: String {
        "Due to App Sandbox restrictions, SpaceSaver can show installed apps " +
        "but cannot directly uninstall them. To uninstall an app, drag it from " +
        "Finder to the Trash, or use Finder's Move to Trash option."
    }

    // MARK: - Scan for Apps
    /// Scans /Applications and ~/Applications for installed apps.
    /// Note: In sandbox mode, access is limited to user-selected locations.
    func scan() async {
        isScanning = true
        errorMessage = nil
        apps = []

        var foundApps: [AppInfo] = []

        // In sandbox, we can only reliably scan ~/Applications
        // /Applications requires special entitlements
        let appDirectories = [
            "\(FileManager.default.homeDirectoryForCurrentUser.path)/Applications"
        ]

        for dirPath in appDirectories {
            let dirURL = URL(fileURLWithPath: dirPath)

            // Check if we have access
            let accessible = SandboxHelper.shared.startAccessing(dirURL)
            defer {
                if accessible { SandboxHelper.shared.stopAccessing(dirURL) }
            }

            guard accessible,
                  let contents = try? FileManager.default.contentsOfDirectory(
                    at: dirURL,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                  ) else { continue }

            for url in contents {
                // Only process .app bundles
                guard url.pathExtension == "app" else { continue }

                let appInfo = await loadAppInfo(at: url)
                foundApps.append(appInfo)
            }
        }

        // Sort by name
        apps = foundApps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        isScanning = false

        // Show notice if we couldn't scan system Applications
        if foundApps.isEmpty {
            showSandboxNotice = true
        }
    }

    // MARK: - Load App Info
    /// Extracts metadata from an app bundle.
    private func loadAppInfo(at url: URL) async -> AppInfo {
        let accessible = SandboxHelper.shared.startAccessing(url)
        defer {
            if accessible { SandboxHelper.shared.stopAccessing(url) }
        }

        guard accessible else {
            return AppInfo(
                url: url,
                name: url.deletingPathExtension().lastPathComponent,
                bundleIdentifier: nil,
                version: nil,
                sizeInBytes: 0,
                lastOpened: nil
            )
        }

        // Read the bundle to get metadata
        let bundle = Bundle(url: url)
        let name = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? url.deletingPathExtension().lastPathComponent

        let bundleId = bundle?.bundleIdentifier
        let version = bundle?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

        // Calculate app size
        let size = await calculateAppSize(at: url)

        // Try to get last opened date from macOS metadata
        let lastOpened = getLastOpenedDate(for: url)

        return AppInfo(
            url: url,
            name: name,
            bundleIdentifier: bundleId,
            version: version,
            sizeInBytes: size,
            lastOpened: lastOpened
        )
    }

    // MARK: - Calculate App Size
    /// Recursively calculates the size of an app bundle.
    private func calculateAppSize(at url: URL) async -> Int64 {
        await DiskUsage.shared.measureDirectorySize(at: url.path)
    }

    // MARK: - Get Last Opened Date
    /// Gets the last-opened date from macOS metadata (MDItem).
    private func getLastOpenedDate(for url: URL) -> Date? {
        let mdItem = MDItemCreate(nil, url.path as CFString)
        guard let mdItem else { return nil }

        guard let dateAttribute = MDItemCopyAttribute(mdItem, kMDItemLastUsedDate) else { return nil }

        return dateAttribute as? Date
    }

    // MARK: - Find Related Files
    /// Searches ~/Library for files related to the selected app.
    /// Limited in sandbox mode.
    func findRelatedFiles(for app: AppInfo) async {
        guard let bundleId = app.bundleIdentifier else {
            relatedFiles = []
            return
        }

        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let searchPaths = [
            "\(homeDir)/Library/Application Support",
            "\(homeDir)/Library/Caches",
            "\(homeDir)/Library/Preferences",
            "\(homeDir)/Library/Logs",
        ]

        var found: [URL] = []
        let fileManager = FileManager.default

        for searchPath in searchPaths {
            let searchURL = URL(fileURLWithPath: searchPath)
            let accessible = SandboxHelper.shared.startAccessing(searchURL)
            defer {
                if accessible { SandboxHelper.shared.stopAccessing(searchURL) }
            }

            guard accessible,
                  let contents = try? fileManager.contentsOfDirectory(
                    at: searchURL,
                    includingPropertiesForKeys: [.isDirectoryKey]
                  ) else { continue }

            for itemURL in contents {
                let itemName = itemURL.lastPathComponent.lowercased()
                let bundleIdLower = bundleId.lowercased()

                // Match by bundle identifier (exact or partial)
                if itemName.contains(bundleIdLower) ||
                    itemName.contains(bundleIdLower.replacingOccurrences(of: ".", with: "-")) ||
                    itemName.contains(bundleIdLower.components(separatedBy: ".").last ?? "") {
                    found.append(itemURL)
                }
            }
        }

        relatedFiles = found
    }

    // MARK: - Uninstall App
    /// In sandbox mode, we can only reveal in Finder for the user to manually uninstall.
    func uninstallSelected() async {
        // In sandbox, we cannot directly move apps to trash
        // Instead, reveal the selected app in Finder
        if let app = selectedApp {
            revealInFinder(app)
        }
        isUninstalling = false
    }

    // MARK: - Open in Finder
    /// Opens the selected app in Finder
    func revealInFinder(_ app: AppInfo) {
        SandboxHelper.shared.revealInFinder(app.url.path)
    }

    // MARK: - Open Applications Folder
    /// Opens the Applications folder in Finder
    func openApplicationsFolder() {
        let url = URL(fileURLWithPath: "/Applications")
        NSWorkspace.shared.open(url)
    }

    /// Opens the user's Applications folder
    func openUserApplicationsFolder() {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications")
        NSWorkspace.shared.open(url)
    }
}
