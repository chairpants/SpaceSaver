//
//  DiskInfo.swift
//  SpaceSaver
//
//  Data model representing disk usage information.
//  Used by the Dashboard to show how much space is used/free.
//

import Foundation

// MARK: - DiskInfo
// Holds overall disk usage statistics for a single volume.
struct DiskInfo {
    /// The volume's mount point (e.g., "/")
    let volumePath: String

    /// The volume's display name (e.g., "Macintosh HD")
    let volumeName: String

    /// Total capacity in bytes
    let totalCapacity: Int64

    /// Used space in bytes
    let usedSpace: Int64

    /// Available (free) space in bytes
    let availableSpace: Int64

    // MARK: - Computed Properties
    // These convert raw bytes into human-friendly values.
    // We compute them on-demand rather than storing them,
    // since the raw bytes are all we need to store.

    /// Percentage of disk currently in use (0.0 to 1.0)
    var usedPercentage: Double {
        guard totalCapacity > 0 else { return 0 }
        return Double(usedSpace) / Double(totalCapacity)
    }

    /// Formatted total capacity (e.g., "500 GB")
    var formattedTotal: String {
        FileSizeFormatter.string(fromBytes: totalCapacity)
    }

    /// Formatted available space (e.g., "125 GB")
    var formattedAvailable: String {
        FileSizeFormatter.string(fromBytes: availableSpace)
    }

    /// Formatted used space (e.g., "375 GB")
    var formattedUsed: String {
        FileSizeFormatter.string(fromBytes: usedSpace)
    }
}

// MARK: - DiskCategory
// Breaks down disk usage into categories for the dashboard chart.
// Each category represents a broad area where space is consumed.
struct DiskCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String          // SF Symbol name
    let sizeInBytes: Int64
    let color: String         // Color name for charts

    var formattedSize: String {
        FileSizeFormatter.string(fromBytes: sizeInBytes)
    }
}