//
//  AppUninstallerViewModel.swift
//  SpaceSaver
//
//  ViewModel for the App Uninstaller feature.
//  Lists installed apps and helps remove them with their related files.
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

    // MARK: - Cache
    @Published var cacheAge: String? = nil

    // MARK: - Scan for Apps
    /// Scans /Applications and ~/Applications for installed apps with cache support.
    func scan() async {
        // Check cache first - convert AppInfo to ScanResult for storage
        if let cached = ScanCache.shared.get(for: ScanCache.Keys.apps),
           let appInfos = decodeAppInfo(from: cached) {
            apps = appInfos
            cacheAge = ScanCache.shared.ageDescription(for: ScanCache.Keys.apps)

            // Refresh in background if cache is older than 5 minutes
            if let age = ScanCache.shared.age(for: ScanCache.Keys.apps), age > 300 {
                await refreshInBackground()
            }
            return
        }

        // No cache - do full scan
        await performFullScan()
    }

    /// Performs a full scan and updates cache
    private func performFullScan() async {
        isScanning = true
        errorMessage = nil

        var foundApps: [AppInfo] = []

        // Scan both /Applications and ~/Applications
        let appDirectories = [
            "/Applications",
            "\(FileManager.default.homeDirectoryForCurrentUser.path)/Applications"
        ]

        for dirPath in appDirectories {
            let dirURL = URL(fileURLWithPath: dirPath)

            guard let contents = try? FileManager.default.contentsOfDirectory(
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

        // Store in cache
        let cachedResults = encodeAppInfo(foundApps)
        ScanCache.shared.set(cachedResults, for: ScanCache.Keys.apps, ttl: .long)
        cacheAge = nil

        isScanning = false
    }

    /// Refreshes data in background without showing loading state
    private func refreshInBackground() async {
        var foundApps: [AppInfo] = []

        let appDirectories = [
            "/Applications",
            "\(FileManager.default.homeDirectoryForCurrentUser.path)/Applications"
        ]

        for dirPath in appDirectories {
            let dirURL = URL(fileURLWithPath: dirPath)
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: dirURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
            ) else { continue }

            for url in contents {
                guard url.pathExtension == "app" else { continue }
                let appInfo = await loadAppInfo(at: url)
                foundApps.append(appInfo)
            }
        }

        foundApps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        // Only update if changed
        let cachedResults = encodeAppInfo(foundApps)
        if ScanCache.shared.hasChanged(cachedResults, for: ScanCache.Keys.apps) {
            apps = foundApps
            ScanCache.shared.set(cachedResults, for: ScanCache.Keys.apps, ttl: .long)
            cacheAge = nil
        }
    }

    /// Forces a fresh scan
    func forceRefresh() async {
        ScanCache.shared.invalidate(ScanCache.Keys.apps)
        await performFullScan()
    }

    // MARK: - Cache Encoding/Decoding
    /// Encodes AppInfo array to ScanResult for cache storage
    private func encodeAppInfo(_ apps: [AppInfo]) -> [ScanResult] {
        return apps.map { app in
            ScanResult(
                url: app.url,
                fileName: app.name,
                sizeInBytes: app.sizeInBytes,
                lastAccessedDate: app.lastOpened ?? .distantPast
            )
        }
    }

    /// Decodes ScanResult array back to AppInfo (partial - loses some data but sufficient for display)
    private func decodeAppInfo(from results: [ScanResult]) -> [AppInfo]? {
        guard !results.isEmpty else { return nil }
        return results.map { result in
            AppInfo(
                url: result.url,
                name: result.fileName,
                bundleIdentifier: nil, // Will be fetched on full refresh
                version: nil,          // Will be fetched on full refresh
                sizeInBytes: result.sizeInBytes,
                lastOpened: result.lastAccessedDate == .distantPast ? nil : result.lastAccessedDate
            )
        }
    }

    // MARK: - Load App Info
    /// Extracts metadata from an app bundle.
    private func loadAppInfo(at url: URL) async -> AppInfo {
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
        // MDItem is part of the Spotlight metadata framework.
        // kMDItemLastUsedDate gives us the last time the app was launched.
        let mdItem = MDItemCreate(nil, url.path as CFString)
        guard let mdItem else { return nil }

        guard let dateAttribute = MDItemCopyAttribute(mdItem, kMDItemLastUsedDate) else { return nil }

        return dateAttribute as? Date
    }

    // MARK: - Find Related Files
    /// Searches ~/Library for files related to the selected app.
    /// This finds caches, preferences, support files, etc.
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
            "\(homeDir)/Library/Saved Application State",
            "\(homeDir)/Library/Containers",
            "\(homeDir)/Library/Group Containers",
        ]

        var found: [URL] = []
        let fileManager = FileManager.default

        for searchPath in searchPaths {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: URL(fileURLWithPath: searchPath),
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
    /// Moves the app and its related files to Trash.
    func uninstallSelected() async {
        isUninstalling = true

        let toUninstall = apps.filter { $0.isSelected }

        for app in toUninstall {
            // Move the app to Trash
            do {
                try FileManager.default.trashItem(at: app.url, resultingItemURL: nil)
            } catch {
                errorMessage = "Could not move \(app.name) to Trash: \(error.localizedDescription)"
            }

            // Move related files to Trash
            for fileURL in relatedFiles {
                try? FileManager.default.trashItem(at: fileURL, resultingItemURL: nil)
            }
        }

        // Remove from list
        apps.removeAll { $0.isSelected }
        relatedFiles = []
        isUninstalling = false

        // Update cache
        let cachedResults = encodeAppInfo(apps)
        ScanCache.shared.set(cachedResults, for: ScanCache.Keys.apps, ttl: .long)
    }

    /// Opens the selected app in Finder
    func revealInFinder(_ app: AppInfo) {
        NSWorkspace.shared.selectFile(app.url.path, inFileViewerRootedAtPath: "")
    }
}