//
//  ScanCache.swift
//  SpaceSaver
//
//  In-memory cache for scan results.
//  Cleared on app launch. Checks for changes in background.
//

import Foundation

/// Simple in-memory cache for scan results.
/// Cleared on app launch. Background refresh with change detection.
@MainActor
final class ScanCache {
    static let shared = ScanCache()

    private var cache: [String: CacheEntry] = [:]
    private let queue = DispatchQueue(label: "com.spacesaver.cache", qos: .userInitiated)

    struct CacheEntry {
        let results: [ScanResult]
        let timestamp: Date
        let checksum: String
        let ttl: TimeInterval

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > ttl
        }
    }

    // MARK: - Cache TTL Settings
    enum CacheTTL {
        case short    // 1 minute - for rapidly changing data
        case medium   // 5 minutes - default
        case long     // 30 minutes - for expensive operations

        var interval: TimeInterval {
            switch self {
            case .short: return 60
            case .medium: return 300
            case .long: return 1800
            }
        }
    }

    private init() {
        // Cache starts fresh on each launch
        // No disk persistence for security/simplicity
    }

    // MARK: - Get
    /// Retrieves cached results if valid and not expired
    func get(for key: String) -> [ScanResult]? {
        guard let entry = cache[key] else { return nil }

        if entry.isExpired {
            cache.removeValue(forKey: key)
            return nil
        }

        return entry.results
    }

    // MARK: - Set
    /// Stores results in cache with TTL
    func set(_ results: [ScanResult], for key: String, ttl: CacheTTL = .medium) {
        let checksum = calculateChecksum(results)
        let entry = CacheEntry(
            results: results,
            timestamp: Date(),
            checksum: checksum,
            ttl: ttl.interval
        )
        cache[key] = entry
    }

    // MARK: - Invalidate
    /// Clears specific cache entry
    func invalidate(_ key: String) {
        cache.removeValue(forKey: key)
    }

    /// Clears all cache
    func invalidateAll() {
        cache.removeAll()
    }

    // MARK: - Checksum
    /// Calculates checksum to detect if data changed
    func calculateChecksum(_ results: [ScanResult]) -> String {
        // Simple checksum: combine file count, total size, and recent modification
        let count = results.count
        let totalSize = results.reduce(0) { $0 + $1.sizeInBytes }
        let latestDate = results.map { $0.lastAccessedDate }.max() ?? Date.distantPast

        return "\(count)-\(totalSize)-\(latestDate.timeIntervalSince1970)"
    }

    /// Checks if cached data might be stale (for background refresh)
    func hasChanged(_ results: [ScanResult], for key: String) -> Bool {
        guard let entry = cache[key] else { return true }
        let currentChecksum = calculateChecksum(results)
        return entry.checksum != currentChecksum
    }

    // MARK: - Metadata
    /// Returns cache age in seconds
    func age(for key: String) -> TimeInterval? {
        guard let entry = cache[key] else { return nil }
        return Date().timeIntervalSince(entry.timestamp)
    }

    /// Returns human-readable cache age
    func ageDescription(for key: String) -> String? {
        guard let age = age(for key) else { return nil }

        if age < 60 {
            return "just now"
        } else if age < 3600 {
            let minutes = Int(age / 60)
            return "\(minutes) min ago"
        } else {
            let hours = Int(age / 3600)
            return "\(hours) hour ago"
        }
    }
}

// MARK: - Cache Keys
extension ScanCache {
    enum Keys {
        static let largeFiles = "largeFiles"
        static let duplicates = "duplicates"
        static let cacheCleaner = "cacheCleaner"
        static let downloads = "downloads"
        static let trash = "trash"
        static let apps = "apps"
        static let loginItems = "loginItems"
    }
}
