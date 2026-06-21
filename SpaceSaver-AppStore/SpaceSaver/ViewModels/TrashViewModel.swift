//
//  TrashViewModel.swift
//  SpaceSaver (App Store Version)
//
//  ViewModel for the Trash Manager feature.
//  Shows trash size and lets users empty it.
//  App Store version: Uses NSWorkspace for sandbox compliance.
//

import SwiftUI

@MainActor
final class TrashViewModel: ObservableObject {

    // MARK: - Published State
    @Published var trashSize: Int64 = 0
    @Published var trashItemCount: Int = 0
    @Published var isLoading = false
    @Published var isEmptying = false
    @Published var errorMessage: String?
    @Published var showConfirmation = false
    @Published var showSandboxNotice = false

    // MARK: - Computed Properties

    /// Whether the Trash appears to be empty
    var isTrashEmpty: Bool {
        trashSize == 0 && trashItemCount == 0
    }

    /// Human-readable trash size
    var formattedTrashSize: String {
        FileSizeFormatter.string(fromBytes: trashSize)
    }

    /// Message explaining sandbox limitations
    var sandboxNotice: String {
        "Due to App Sandbox restrictions, SpaceSaver cannot directly access the Trash. " +
        "You can open Trash in Finder to view and empty it manually, " +
        "or grant Full Disk Access in System Settings for full functionality."
    }

    // MARK: - Refresh Trash Info
    /// Queries the size and contents of the Trash folder.
    /// Note: In the sandboxed App Store version, this has limited access.
    func refresh() async {
        isLoading = true
        errorMessage = nil

        let trashURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".Trash")

        let fileManager = FileManager.default

        // Check if we can access the Trash
        guard fileManager.fileExists(atPath: trashURL.path) else {
            trashSize = 0
            trashItemCount = 0
            isLoading = false
            showSandboxNotice = true
            return
        }

        // Try to access (will likely fail in sandbox without special entitlements)
        let accessible = SandboxHelper.shared.startAccessing(trashURL)
        defer {
            if accessible { SandboxHelper.shared.stopAccessing(trashURL) }
        }

        if !accessible {
            // In sandbox mode, show notice instead of error
            showSandboxNotice = true
            trashSize = 0
            trashItemCount = 0
            isLoading = false
            return
        }

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: trashURL,
                includingPropertiesForKeys: nil
            )

            trashItemCount = contents.count

            // Calculate size by measuring each item
            var totalSize: Int64 = 0
            for url in contents {
                totalSize += await measureItemSize(at: url)
            }
            trashSize = totalSize

        } catch {
            // In sandbox, this is expected - show notice
            showSandboxNotice = true
            trashSize = 0
            trashItemCount = 0
        }

        isLoading = false
    }

    /// Measures the size of a file or directory
    private func measureItemSize(at url: URL) async -> Int64 {
        let fileManager = FileManager.default

        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            if let size = attributes[.size] as? Int64 {
                return size
            }
        } catch {
            // Fall through to directory calculation
        }

        // If it's a directory, calculate recursively
        var totalSize: Int64 = 0
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            do {
                let attrs = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let size = attrs[.size] as? Int64 {
                    totalSize += size
                }
            } catch {
                continue
            }
        }

        return totalSize
    }

    // MARK: - Empty Trash
    /// Attempts to empty the Trash using NSWorkspace (sandbox-compatible method).
    func emptyTrash() async {
        isEmptying = true
        errorMessage = nil

        // In sandbox, we use NSWorkspace to open the Trash folder,
        // which respects sandbox boundaries
        let trashURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".Trash")

        // Try to use AppleScript to empty trash (may not work in strict sandbox)
        let script = """
        tell application "Finder"
            empty trash
        end tell
        """

        var errorInfo: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&errorInfo)
        }

        if errorInfo != nil {
            // AppleScript failed - this is expected in sandbox
            // Fall back to opening Trash in Finder
            showSandboxNotice = true
        }

        isEmptying = false
        await refresh()
    }

    // MARK: - Open Trash in Finder
    /// Opens the Trash folder in Finder
    func openInFinder() {
        let trashURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".Trash")
        NSWorkspace.shared.open(trashURL)
    }

    // MARK: - Open System Settings
    /// Opens System Settings to Full Disk Access
    func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}
