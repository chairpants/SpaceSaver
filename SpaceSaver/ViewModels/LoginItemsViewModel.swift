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
struct LoginItem: Identifiable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    let url: URL?
    let kind: Kind
    var isEnabled: Bool

    enum Kind: String {
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

    // MARK: - Load Login Items
    /// Loads the list of login items.
    /// Uses SMAppService (macOS 13+) which gives us access to
    /// login items registered through the ServiceManagement framework.
    func loadLoginItems() async {
        isLoading = true
        errorMessage = nil

        var items: [LoginItem] = []

        // Get login items from the ServiceManagement framework
        // SMAppService gives us services registered by apps
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
        isLoading = false
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