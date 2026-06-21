//
//  DiskUsage.swift
//  SpaceSaver
//
//  Queries disk space information using FileManager.
//  This is the data source for the Dashboard view.
//

import Foundation

// MARK: - DiskUsage
// A utility that reads disk capacity and usage information.
// Uses FileManager.attributesOfFileSystem() which works outside
// the App Sandbox (we don't sandbox this app).
final class DiskUsage {

    // MARK: - Shared Instance
    // Singleton pattern — we only need one DiskUsage object.
    // Use DiskUsage.shared from anywhere in the app.
    static let shared = DiskUsage()

    private init() {}  // Prevent external creation

    // MARK: - Get Disk Info
    /// Returns DiskInfo for the boot volume (the main drive).
    /// This is the volume macOS is installed on.
    func getBootVolumeInfo() -> DiskInfo {
        // The root path "/" represents the boot volume
        return getDiskInfo(for: "/")
    }

    /// Returns DiskInfo for a specific volume path.
    /// - Parameter path: The mount point path (e.g., "/Volumes/External")
    func getDiskInfo(for path: String) -> DiskInfo {
        let fileManager = FileManager.default

        do {
            // Query the filesystem attributes for this path
            let attributes = try fileManager.attributesOfFileSystem(
                forPath: path
            )

            // Extract values with proper type casting
            // FileManager returns these as NSNumber objects
            let totalCapacity = (attributes[.systemSize] as? NSNumber)?.int64Value ?? 0
            let availableSpace = (attributes[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
            let usedSpace = totalCapacity - availableSpace

            // Get the volume name
            let url = URL(fileURLWithPath: path)
            let volumeName = url.lastPathComponent
                == "/" ? getBootVolumeName() : url.lastPathComponent

            return DiskInfo(
                volumePath: path,
                volumeName: volumeName,
                totalCapacity: totalCapacity,
                usedSpace: usedSpace,
                availableSpace: availableSpace
            )
        } catch {
            // If we can't read disk info, return zeros
            // This shouldn't happen on a properly configured system
            print("Error reading disk info for \(path): \(error)")
            return DiskInfo(
                volumePath: path,
                volumeName: "Unknown",
                totalCapacity: 0,
                usedSpace: 0,
                availableSpace: 0
            )
        }
    }

    // MARK: - Category Breakdown
    /// Returns an estimate of disk usage by category.
    /// Note: These are approximate — macOS doesn't expose exact
    /// per-category sizes, so we calculate what we can and estimate the rest.
    func getCategoryBreakdown() async -> [DiskCategory] {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path

        // Measure cache-related directories
        let cachesSize = await measureDirectorySize(
            at: "\(homeDir)/Library/Caches"
        )
        let logsSize = await measureDirectorySize(
            at: "\(homeDir)/Library/Logs"
        )
        let downloadsSize = await measureDirectorySize(
            at: "\(homeDir)/Downloads"
        )
        let applicationsSize = await measureDirectorySize(
            at: "/Applications"
        )
        let xcodeDerivedDataSize = await measureDirectorySize(
            at: "\(homeDir)/Library/Developer/Xcode/DerivedData"
        )

        // Get overall disk info for the "Other" calculation
        let diskInfo = getBootVolumeInfo()

        let knownSize = cachesSize + logsSize + downloadsSize
            + applicationsSize + xcodeDerivedDataSize
        let otherSize = max(0, diskInfo.usedSpace - knownSize)

        return [
            DiskCategory(
                name: "Applications",
                icon: "app",
                sizeInBytes: applicationsSize,
                color: "blue"
            ),
            DiskCategory(
                name: "Caches",
                icon: "internaldrive",
                sizeInBytes: cachesSize,
                color: "orange"
            ),
            DiskCategory(
                name: "Downloads",
                icon: "arrow.down.circle",
                sizeInBytes: downloadsSize,
                color: "purple"
            ),
            DiskCategory(
                name: "Xcode Data",
                icon: "hammer",
                sizeInBytes: xcodeDerivedDataSize,
                color: "cyan"
            ),
            DiskCategory(
                name: "Logs",
                icon: "doc.text",
                sizeInBytes: logsSize,
                color: "yellow"
            ),
            DiskCategory(
                name: "Other",
                icon: "folder",
                sizeInBytes: otherSize,
                color: "gray"
            ),
        ]
    }

    // MARK: - Directory Size Measurement
    /// Recursively measures the total size of a directory in bytes.
    /// Runs asynchronously to avoid blocking the main thread.
    func measureDirectorySize(at path: String) async -> Int64 {
        await Task.detached(priority: .utility) {
            let fileManager = FileManager.default
            var totalSize: Int64 = 0

            // FileManager.enumerator walks the directory tree recursively.
            // We request only the file size key to minimize I/O.
            guard let enumerator = fileManager.enumerator(
                at: URL(fileURLWithPath: path),
                includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else {
                return 0
            }

            for case let url as URL in enumerator {
                guard let resourceValues = try? url.resourceValues(
                    forKeys: [.fileSizeKey, .isDirectoryKey]
                ) else { continue }

                // Skip directories — we only want file sizes
                if resourceValues.isDirectory == true {
                    continue
                }

                totalSize += Int64(resourceValues.fileSize ?? 0)
            }

            return totalSize
        }.value
    }

    // MARK: - Helpers

    /// Gets the display name of the boot volume.
    private func getBootVolumeName() -> String {
        // Try to get the volume name from the root URL
        let rootURL = URL(fileURLWithPath: "/")
        if let name = try? rootURL.resourceValues(
            forKeys: [.volumeNameKey]
        ).volumeName {
            return name
        }
        return "Macintosh HD"
    }
}