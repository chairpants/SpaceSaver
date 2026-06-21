//
//  SandboxHelper.swift
//  SpaceSaver (App Store Version)
//
//  Helper utilities for handling App Sandbox restrictions.
//  Provides methods to request user access to files and directories
//  that are outside the sandbox container.
//

import SwiftUI

/// SandboxHelper provides methods for working within the macOS App Sandbox.
/// In the sandboxed App Store version, the app cannot directly access most
/// file system locations. Instead, we use security-scoped bookmarks and
/// file pickers to request user permission.
@MainActor
final class SandboxHelper: ObservableObject {

    static let shared = SandboxHelper()

    // MARK: - Security-Scoped Bookmarks
    // Store bookmarks to files/folders the user has granted access to
    @AppStorage("downloadsBookmark") private var downloadsBookmark: Data?
    @AppStorage("documentsBookmark") private var documentsBookmark: Data?

    // MARK: - Request Access to Folder
    /// Shows a file picker to request access to a specific folder.
    /// Returns the URL if granted, nil if cancelled.
    func requestAccessToFolder(prompt: String, defaultDirectory: URL? = nil) async -> URL? {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let openPanel = NSOpenPanel()
                openPanel.message = prompt
                openPanel.prompt = "Grant Access"
                openPanel.canChooseFiles = false
                openPanel.canChooseDirectories = true
                openPanel.allowsMultipleSelection = false

                if let defaultDir = defaultDirectory {
                    openPanel.directoryURL = defaultDir
                }

                openPanel.begin { result in
                    if result == .OK, let url = openPanel.url {
                        // Create a security-scoped bookmark
                        if let bookmarkData = try? url.bookmarkData(
                            options: .withSecurityScope,
                            includingResourceValuesForKeys: nil,
                            relativeTo: nil
                        ) {
                            // Store the bookmark
                            if url.path.contains("Downloads") {
                                self.downloadsBookmark = bookmarkData
                            } else if url.path.contains("Documents") {
                                self.documentsBookmark = bookmarkData
                            }
                        }
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }

    // MARK: - Access Downloads Folder
    /// Returns the Downloads folder URL if accessible, or requests access.
    /// In the sandboxed version, we use the downloads entitlement which
    /// grants automatic access to ~/Downloads.
    func accessibleDownloadsURL() -> URL? {
        let downloadsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Downloads")

        // Check if we can access it
        if FileManager.default.isReadableFile(atPath: downloadsURL.path) {
            return downloadsURL
        }

        return nil
    }

    // MARK: - Start Accessing Security-Scoped Resource
    /// Begins accessing a security-scoped resource.
    /// Must be paired with stopAccessingSecurityScopedResource.
    func startAccessing(_ url: URL) -> Bool {
        return url.startAccessingSecurityScopedResource()
    }

    /// Stops accessing a security-scoped resource.
    func stopAccessing(_ url: URL) {
        url.stopAccessingSecurityScopedResource()
    }

    // MARK: - With Security Scope
    /// Executes a closure with access to a security-scoped resource.
    /// Automatically handles start/stop access.
    func withSecurityScope<T>(url: URL, perform: () throws -> T) rethrows -> T? {
        guard startAccessing(url) else { return nil }
        defer { stopAccessing(url) }
        return try perform()
    }

    // MARK: - Sandbox Limitation Messages
    /// Returns a user-friendly message explaining why a feature is limited.
    func limitationMessage(for feature: SandboxFeature) -> String {
        switch feature {
        case .trash:
            return "Due to App Sandbox restrictions, direct Trash management requires Full Disk Access. You can still open the Trash in Finder to manage items manually."
        case .systemCaches:
            return "Due to App Sandbox restrictions, system cache cleaning is limited. You can clean user-level caches in ~/Library/Caches."
        case .appUninstaller:
            return "Due to App Sandbox restrictions, the App Uninstaller can only show installed apps. To uninstall, open Finder and drag apps to Trash."
        case .systemFiles:
            return "This feature requires access to system files that are protected by the App Sandbox."
        }
    }

    // MARK: - Open in Finder
    /// Opens a file or folder in Finder.
    func openInFinder(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    /// Selects a file in Finder.
    func revealInFinder(_ path: String) {
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }
}

// MARK: - SandboxFeature
/// Features that may have limitations in the App Sandbox.
enum SandboxFeature {
    case trash
    case systemCaches
    case appUninstaller
    case systemFiles
}

// MARK: - App Store Compliance Check
extension SandboxHelper {

    /// Checks if the app is running in a sandbox.
    var isSandboxed: Bool {
        // Check for the app sandbox container
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
        let containerURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .deletingLastPathComponent()
            .appendingPathComponent("Containers")
            .appendingPathComponent(bundleIdentifier)

        return containerURL != nil && FileManager.default.fileExists(atPath: containerURL?.path ?? "")
    }

    /// Returns a description of sandbox status for debugging.
    var sandboxStatusDescription: String {
        if isSandboxed {
            return "Running in App Sandbox (App Store compliant)"
        } else {
            return "Running without sandbox (not App Store compliant)"
        }
    }
}
