//
//  CacheLocator.swift
//  SpaceSaver (App Store Version)
//
//  Finds and measures the size of known cache directories.
//  Sandbox version: Limited to user-accessible locations.
//

import Foundation

// MARK: - CacheLocator
// Scans known cache locations and reports their sizes.
// Sandbox version only accesses user-writable cache locations.
@MainActor
final class CacheLocator {

    static let shared = CacheLocator()
    private init() {}

    // MARK: - Home Directory
    // Shortcut for the current user's home directory path.
    private var homeDir: String {
        FileManager.default.homeDirectoryForCurrentUser.path
    }

    // MARK: - Measure Cache Category
    /// Measures the total size of all paths in a CacheCategory.
    /// - Parameter category: The cache category to measure
    /// - Returns: The category with its calculatedSize updated
    func measureCategory(_ category: CacheCategory) async -> CacheCategory {
        var totalSize: Int64 = 0

        for path in category.paths {
            let fullPath: String
            if path.hasPrefix("/") {
                // Absolute path - check if accessible in sandbox
                fullPath = path
            } else {
                // Relative to home directory
                fullPath = "\(homeDir)/\(path)"
            }

            // Try to access with security scope
            let url = URL(fileURLWithPath: fullPath)
            let accessible = SandboxHelper.shared.startAccessing(url)

            if accessible {
                let size = await DiskUsage.shared.measureDirectorySize(at: fullPath)
                totalSize += size
                SandboxHelper.shared.stopAccessing(url)
            }
        }

        // Return a copy with the calculated size
        var updated = category
        updated.calculatedSize = totalSize
        return updated
    }

    // MARK: - Measure All Categories
    /// Measures all built-in cache categories concurrently.
    /// - Returns: Array of categories with sizes populated
    func measureAllCategories() async -> [CacheCategory] {
        // Run all measurements in parallel for speed
        await withTaskGroup(of: CacheCategory.self) { group in
            for category in CacheCategory.builtInCategories {
                group.addTask {
                    await self.measureCategory(category)
                }
            }

            var results: [CacheCategory] = []
            for await category in group {
                results.append(category)
            }

            // Maintain original order
            let originalOrder = CacheCategory.builtInCategories.map { $0.name }
            return results.sorted { a, b in
                guard let aIndex = originalOrder.firstIndex(of: a.name),
                      let bIndex = originalOrder.firstIndex(of: b.name) else {
                    return false
                }
                return aIndex < bIndex
            }
        }
    }

    // MARK: - Clean Category
    /// Deletes the contents of all paths in a CacheCategory.
    /// Moves items to Trash rather than permanently deleting.
    /// - Parameter category: The cache category to clean
    /// - Returns: Number of bytes freed
    @discardableResult
    func cleanCategory(_ category: CacheCategory) async throws -> Int64 {
        let fileManager = FileManager.default
        var totalFreed: Int64 = 0

        for path in category.paths {
            let fullPath: String
            if path.hasPrefix("/") {
                fullPath = path
            } else {
                fullPath = "\(homeDir)/\(path)"
            }

            let directoryURL = URL(fileURLWithPath: fullPath)

            // Try to access with security scope
            let accessible = SandboxHelper.shared.startAccessing(directoryURL)
            defer {
                if accessible { SandboxHelper.shared.stopAccessing(directoryURL) }
            }

            guard accessible else { continue }

            // Check if the directory exists
            guard fileManager.fileExists(atPath: fullPath) else { continue }

            // Get the size before cleaning (for reporting)
            let sizeBefore = await DiskUsage.shared.measureDirectorySize(at: fullPath)

            // List contents of the directory
            guard let contents = try? fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil
            ) else { continue }

            // Move each item to Trash
            for itemURL in contents {
                do {
                    try FileManager.default.trashItem(at: itemURL, resultingItemURL: nil)
                } catch {
                    // Skip items that can't be trashed
                    continue
                }
            }

            totalFreed += sizeBefore
        }

        return totalFreed
    }

    // MARK: - Get Path Details
    /// Returns details about what's in a cache path.
    func getContents(of path: String) -> [URL] {
        let fullPath = path.hasPrefix("/") ? path : "\(homeDir)/\(path)"
        let fileManager = FileManager.default

        let url = URL(fileURLWithPath: fullPath)
        let accessible = SandboxHelper.shared.startAccessing(url)
        defer {
            if accessible { SandboxHelper.shared.stopAccessing(url) }
        }

        guard accessible,
              fileManager.fileExists(atPath: fullPath),
              let contents = try? fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]
              ) else {
            return []
        }

        return contents
    }

    // MARK: - Breakdown (drill-down)
    /// Lists the immediate children of a path, each with its measured size.
    func getBreakdown(of path: String) async -> [CacheBreakdownItem] {
        let fullPath = path.hasPrefix("/") ? path : "\(homeDir)/\(path)"
        let fileManager = FileManager.default

        let url = URL(fileURLWithPath: fullPath)
        let accessible = SandboxHelper.shared.startAccessing(url)
        defer {
            if accessible { SandboxHelper.shared.stopAccessing(url) }
        }

        guard accessible,
              let contents = try? fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .totalFileSizeKey]
              ) else {
            return []
        }

        // Measure each child concurrently for speed
        let items = await withTaskGroup(of: CacheBreakdownItem?.self) { group in
            for url in contents {
                group.addTask {
                    guard let values = try? url.resourceValues(
                        forKeys: [.isDirectoryKey, .fileSizeKey, .totalFileSizeKey, .isSymbolicLinkKey]
                    ) else { return nil }

                    let isDir = values.isDirectory == true
                    let isSymlink = values.isSymbolicLink == true

                    let size: Int64
                    if isSymlink {
                        size = 0
                    } else if isDir {
                        size = await DiskUsage.shared.measureDirectorySize(at: url.path)
                    } else {
                        size = Int64(values.totalFileSize ?? values.fileSize ?? 0)
                    }

                    return CacheBreakdownItem(
                        name: url.lastPathComponent,
                        url: url,
                        sizeInBytes: size,
                        isDirectory: isDir,
                        isSymlink: isSymlink
                    )
                }
            }

            var results: [CacheBreakdownItem] = []
            for await item in group {
                if let item { results.append(item) }
            }
            return results
        }

        return items.sorted { $0.sizeInBytes > $1.sizeInBytes }
    }
}

// MARK: - CacheBreakdownItem
// A single top-level item inside a cache path, with its measured size.
struct CacheBreakdownItem: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let sizeInBytes: Int64
    let isDirectory: Bool
    let isSymlink: Bool

    var formattedSize: String {
        FileSizeFormatter.string(fromBytes: sizeInBytes)
    }

    /// SF Symbol matching the item kind (folder / file / symlink)
    var systemImage: String {
        if isSymlink { return "folder.badge.gearshape" }
        return isDirectory ? "folder.fill" : "doc.fill"
    }
}
