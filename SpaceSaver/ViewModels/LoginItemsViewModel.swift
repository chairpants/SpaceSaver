//
//  LoginItemsViewModel.swift
//  SpaceSaver
//
//  ViewModel for the Login Items Manager.
//  Uses the ServiceManagement framework (macOS 13+) to manage
//  login items and launch agents.
//

import SwiftUI
import ServiceManagement

// MARK: - LoginItem
// Represents an app or service that starts at login.
struct LoginItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    let url: URL?
    let kind: Kind
    var isEnabled: Bool

    enum Kind: String, Codable {
        case app = "App"
        case launchAgent = "Launch Agent"
        case launchDaemon = "Launch Daemon"
    }
}

@MainActor
final class LoginItemsViewModel: ObservableObject {

    // MARK: - Published State
    @Published var loginItems: [LoginItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Cache
    @Published var cacheAge: String? = nil

    // MARK: - Load Login Items
    /// Loads the list of login items with cache support.
    func loadLoginItems() async {
        // Check cache first
        if let cached: [LoginItem] = ScanCache.shared.get(for: ScanCache.Keys.loginItems, as: [LoginItem].self) {
            loginItems = cached
            cacheAge = ScanCache.shared.ageDescription(for: ScanCache.Keys.loginItems)

            // Refresh in background if cache is older than 2 minutes
            if let age = ScanCache.shared.age(for: ScanCache.Keys.loginItems), age > 120 {
                await refreshInBackground()
            }
            return
        }

        // No cache - do full load
        await performFullLoad()
    }

    /// Performs a full load and updates cache
    private func performFullLoad() async {
        isLoading = true
        errorMessage = nil

        var items: [LoginItem] = []

        // Get login items from the ServiceManagement framework
        let serviceTypes: [(SMAppService, LoginItem.Kind)] = [
            (SMAppService.mainApp, .app),
        ]

        // Get launch agents and daemons from ~/Library/LaunchAgents
        items.append(contentsOf: loadLaunchAgents())

        // Get current SMAppService status
        for (service, kind) in serviceTypes {
            let status = service.status
            let isEnabled = status == .enabled

            items.append(LoginItem(
                name: "SpaceSaver Login Item",
                bundleIdentifier: Bundle.main.bundleIdentifier ?? "com.spacesaver.app",
                url: nil,
                kind: kind,
                isEnabled: isEnabled
            ))
        }

        // Also load system login items from System Preferences
        items.append(contentsOf: loadSystemLoginItems())

        loginItems = items

        // Store in cache
        ScanCache.shared.set(items, for: ScanCache.Keys.loginItems, ttl: .medium)
        cacheAge = nil

        isLoading = false
    }

    /// Refreshes data in background without showing loading state
    private func refreshInBackground() async {
        var items: [LoginItem] = []
        items.append(contentsOf: loadLaunchAgents())

        if ScanCache.shared.hasChanged(items, for: ScanCache.Keys.loginItems, as: [LoginItem].self) {
            loginItems = items
            ScanCache.shared.set(items, for: ScanCache.Keys.loginItems, ttl: .medium)
            cacheAge = nil
        }
    }

    /// Forces a fresh load
    func forceRefresh() async {
        ScanCache.shared.invalidate(ScanCache.Keys.loginItems)
        await performFullLoad()
    }

    // MARK: - Toggle Login Item
    /// Enables or disables a login item.
    func toggleItem(_ item: LoginItem) async {
        guard let index = loginItems.firstIndex(where: { $0.id == item.id }) else { return }

        let shouldEnable = !loginItems[index].isEnabled

        // For SMAppService-managed items
        if item.bundleIdentifier == Bundle.main.bundleIdentifier {
            do {
                let service = SMAppService.mainApp
                if shouldEnable {
                    try service.register()
                } else {
                    try await service.unregister()
                }
                loginItems[index].isEnabled = shouldEnable
            } catch {
                errorMessage = "Could not \(shouldEnable ? "enable" : "disable") login item: \(error.localizedDescription)"
            }
            return
        }

        // For Launch Agents, toggle the file (rename with .disabled suffix)
        if let url = item.url {
            let fileManager = FileManager.default
            let disabledPath = item.url!.path + ".disabled"

            if shouldEnable {
                // Rename from .disabled to active
                if fileManager.fileExists(atPath: disabledPath) {
                    try? fileManager.moveItem(at: url, to: URL(fileURLWithPath: item.url!.path.replacingOccurrences(of: ".disabled", with: "")))
                    loginItems[index].isEnabled = true
                }
            } else {
                // Rename to .disabled
                let disabledURL = URL(fileURLWithPath: disabledPath)
                try? fileManager.moveItem(at: url, to: disabledURL)
                loginItems[index].isEnabled = false
            }
        }
    }

    // MARK: - Load Launch Agents
    /// Loads launch agents from ~/Library/LaunchAgents
    private func loadLaunchAgents() -> [LoginItem] {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let launchAgentsPath = "\(homeDir)/Library/LaunchAgents"
        var items: [LoginItem] = []

        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(
            at: URL(fileURLWithPath: launchAgentsPath),
            includingPropertiesForKeys: nil
        ) else { return items }

        for url in contents {
            guard url.pathExtension == "plist" else { continue }
            let name = url.deletingPathExtension().lastPathComponent

            items.append(LoginItem(
                name: name,
                bundleIdentifier: name,
                url: url,
                kind: .launchAgent,
                isEnabled: true
            ))
        }

        return items
    }

    // MARK: - Load System Login Items
    /// Attempts to read system-level login items.
    /// Note: macOS restricts access to these, so we show what we can.
    private func loadSystemLoginItems() -> [LoginItem] {
        // System login items are managed by macOS and not directly accessible
        // via public APIs. We return an empty list and show a message
        // directing users to System Settings > General > Login Items.
        return []
    }
}