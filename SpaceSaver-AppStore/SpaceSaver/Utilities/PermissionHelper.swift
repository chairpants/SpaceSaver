//
//  PermissionHelper.swift
//  SpaceSaver (App Store Version)
//
//  Prompts users to grant access to folders that require permission
//  due to App Sandbox restrictions.
//

import SwiftUI

/// Helper to request user permission for folder access in the sandbox
@MainActor
final class PermissionHelper {

    static let shared = PermissionHelper()
    private init() {}

    /// Requests access to the Home folder for scanning
    /// Returns true if granted, false if cancelled
    func requestHomeAccess() async -> Bool {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        return await requestAccessToFolder(
            at: homeURL,
            message: "SpaceSaver needs access to your Home folder to scan for large files and duplicates.",
            prompt: "Grant Access"
        )
    }

    /// Requests access to a specific folder
    func requestAccessToFolder(at url: URL, message: String, prompt: String) async -> Bool {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let openPanel = NSOpenPanel()
                openPanel.message = message
                openPanel.prompt = prompt
                openPanel.canChooseFiles = false
                openPanel.canChooseDirectories = true
                openPanel.allowsMultipleSelection = false
                openPanel.directoryURL = url

                // Pre-select the folder we want
                openPanel.begin { result in
                    if result == .OK {
                        // User clicked "Grant Access" - save bookmark for future use
                        if let selectedURL = openPanel.url,
                           selectedURL.path == url.path {
                            _ = self.saveBookmark(for: selectedURL)
                            continuation.resume(returning: true)
                        } else {
                            // User selected a different folder
                            continuation.resume(returning: false)
                        }
                    } else {
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }

    /// Checks if we have access to a folder by trying to read it
    func checkAccess(to folder: URL) -> Bool {
        // Try to list contents to verify access
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil,
            options: []
        ) else {
            return false
        }
        // If we can read (even empty), we have access
        _ = contents
        return true
    }

    /// Saves a security-scoped bookmark for a folder
    private func saveBookmark(for url: URL) -> Data? {
        try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }
}

// MARK: - Permission Request View
/// A view that shows when permission is needed
struct PermissionRequestView: View {
    let icon: String
    let title: String
    let description: String
    let folderName: String
    let onGrant: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)

                HStack(spacing: 8) {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.blue)
                    Text(folderName)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.blue.opacity(0.1))
                .cornerRadius(8)
            }

            VStack(spacing: 12) {
                Button {
                    onGrant()
                } label: {
                    Label("Grant Access", systemImage: "lock.open")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    onCancel()
                } label: {
                    Text("Skip for Now")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

// MARK: - Permission State Enum
enum PermissionState {
    case unknown
    case checking
    case granted
    case denied
}
