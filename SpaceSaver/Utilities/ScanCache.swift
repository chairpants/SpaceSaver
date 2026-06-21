//
//  ScanCache.swift
//  SpaceSaver
//
//  In-memory cache for scan results.
//  Cleared on app launch. Checks for changes in background.
//

import Foundation

/// Simple in-memory cache for any Codable type.
/// Cleared on app launch. Background refresh with change detection.
@MainActor
final class ScanCache {
    static let shared = ScanCache()

    private var cache: [String: AnyCacheEntry] = [:]

    struct AnyCacheEntry {
        let data: Data
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
    func get<T: Codable>(for key: String, as type: T.Type) -> T? {
        guard let entry = cache[key] else { return nil }

        if entry.isExpired {
            cache.removeValue(forKey: key)
            return nil
        }

        do {
            return try JSONDecoder().decode(type, from: entry.data)
        } catch {
            cache.removeValue(forKey: key)
            return nil
        }
    }

    // MARK: - Set
    /// Stores results in cache with TTL
    func set<T: Codable>(_ value: T, for key: String, ttl: CacheTTL = .medium) {
        do {
            let data = try JSONEncoder().encode(value)
            let checksum = calculateChecksum(data)
            let entry = AnyCacheEntry(
                data: data,
                timestamp: Date(),
                checksum: checksum,
                ttl: ttl.interval
            )
            cache[key] = entry
        } catch {
            // Failed to encode, don't cache
        }
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
    private func calculateChecksum(_ data: Data) -> String {
        // Simple checksum using hash of data
        let hash = data.reduce(0) { $0 &+ Int($1) }
        return String(hash)
    }

    /// Checks if cached data might be stale (for background refresh)
    func hasChanged<T: Codable>(_ value: T, for key: String, as type: T.Type) -> Bool {
        guard let entry = cache[key] else { return true }
        do {
            let data = try JSONEncoder().encode(value)
            let currentChecksum = calculateChecksum(data)
            return entry.checksum != currentChecksum
        } catch {
            return true
        }
    }

    // MARK: - Metadata
    /// Returns cache age in seconds
    func age(for key: String) -> TimeInterval? {
        guard let entry = cache[key] else { return nil }
        return Date().timeIntervalSince(entry.timestamp)
    }

    /// Returns human-readable cache age
    func ageDescription(for key: String) -> String? {
        guard let ageValue = self.age(for: key) else { return nil }

        if ageValue < 60 {
            return "just now"
        } else if ageValue < 3600 {
            let minutes = Int(ageValue / 60)
            return "\(minutes) min ago"
        } else {
            let hours = Int(ageValue / 3600)
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
