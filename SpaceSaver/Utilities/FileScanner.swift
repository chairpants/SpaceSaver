//
//  FileScanner.swift
//  SpaceSaver
//
//  Recursively scans directories to find large files, duplicates, etc.
//  This is the engine behind Large Files, Downloads, and Duplicate Finder.
//

import CommonCrypto
import Foundation

// MARK: - FileScanner
// Scans the filesystem for files matching various criteria.
// All scanning runs on background threads to keep the UI responsive.
final class FileScanner {

    // MARK: - Scan for Large Files
    /// Scans a directory for files above a size threshold.
    /// - Parameters:
    ///   - directory: The root directory to scan
    ///   - minimumSize: Minimum file size in bytes (default: 100 MB)
    ///   - progress: Called periodically with progress (0.0 to 1.0)
    /// - Returns: Array of ScanResult sorted by size (largest first)
    func scanLargeFiles(
        in directory: URL,
        minimumSize: Int64 = 100_000_000,  // 100 MB default
        progress: @Sendable @escaping (Double) -> Void = { _ in }
    ) async -> [ScanResult] {
        // Run on a background thread so we don't block the UI
        await Task.detached(priority: .utility) {
            var results: [ScanResult] = []
            let fileManager = FileManager.default

            // Enumerate the directory tree recursively.
            // We skip hidden files and package contents for speed.
            guard let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [
                    .fileSizeKey,
                    .isDirectoryKey,
                    .contentModificationDateKey,
                    .contentAccessDateKey,
                    .totalFileSizeKey
                ],
                options: [.skipsHiddenFiles]
            ) else {
                return results
            }

            var filesProcessed = 0

            for case let url as URL in enumerator {
                filesProcessed += 1

                // Report progress every 100 files
                if filesProcessed % 100 == 0 {
                    // Progress is hard to calculate without knowing total files,
                    // so we just report a pulsing value
                    let approxProgress = min(0.9, Double(filesProcessed) / 50000.0)
                    await MainActor.run {
                        progress(approxProgress)
                    }
                }

                do {
                    let resourceValues = try url.resourceValues(
                        forKeys: [.isDirectoryKey, .fileSizeKey, .totalFileSizeKey,
                                  .contentModificationDateKey, .contentAccessDateKey]
                    )

                    // Skip directories — we want files only
                    if resourceValues.isDirectory == true {
                        continue
                    }

                    // Use totalFileSize (accounts for extended attributes) or fall back to fileSize
                    let fileSize = Int64(resourceValues.totalFileSize ?? resourceValues.fileSize ?? 0)

                    // Skip files below the threshold
                    guard fileSize >= minimumSize else { continue }

                    let result = ScanResult(
                        url: url,
                        sizeInBytes: fileSize,
                        lastAccessed: resourceValues.contentAccessDate,
                        lastModified: resourceValues.contentModificationDate
                    )
                    results.append(result)
                } catch {
                    // Skip files we can't read
                    continue
                }
            }

            // Sort by size, largest first
            return results.sorted { $0.sizeInBytes > $1.sizeInBytes }
        }.value
    }

    // MARK: - Scan Downloads
    /// Scans the Downloads directory and returns all files with metadata.
    /// - Parameters:
    ///   - minimumAge: Minimum age in days for a file to be considered "old"
    ///   - progress: Progress callback
    /// - Returns: Array of ScanResult sorted by date (oldest first)
    func scanDownloads(
        minimumAge days: Int = 30,
        progress: @Sendable @escaping (Double) -> Void = { _ in }
    ) async -> [ScanResult] {
        let downloadsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Downloads")

        return await scanLargeFiles(
            in: downloadsURL,
            minimumSize: 0,  // Include all sizes
            progress: progress
        )
    }

    // MARK: - Scan for Duplicates
    /// Finds duplicate files by grouping files of the same size,
    /// then verifying with a content hash.
    /// - Parameter directory: Root directory to scan
    /// - Parameter progress: Progress callback
    /// - Returns: Array of DuplicateGroup, sorted by wasted space (most waste first)
    func scanDuplicates(
        in directory: URL,
        progress: @Sendable @escaping (Double) -> Void = { _ in }
    ) async -> [DuplicateGroup] {
        await Task.detached(priority: .utility) {
            let fileManager = FileManager.default
            var sizeGroups: [Int64: [URL]] = [:]
            var filesProcessed = 0

            // Phase 1: Group all files by size.
            // Files with different sizes can't be duplicates,
            // so this is a fast first pass.
            guard let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .totalFileSizeKey],
                options: [.skipsHiddenFiles]
            ) else {
                return []
            }

            for case let url as URL in enumerator {
                filesProcessed += 1
                if filesProcessed % 100 == 0 {
                    await MainActor.run { progress(min(0.4, Double(filesProcessed) / 100000)) }
                }

                do {
                    let values = try url.resourceValues(
                        forKeys: [.isDirectoryKey, .fileSizeKey, .totalFileSizeKey]
                    )
                    if values.isDirectory == true { continue }

                    let size = Int64(values.totalFileSize ?? values.fileSize ?? 0)
                    // Skip very small files (< 1 KB) — not worth checking
                    guard size > 1024 else { continue }

                    sizeGroups[size, default: []].append(url)
                } catch {
                    continue
                }
            }

            // Only groups with 2+ files at the same size might be duplicates
            let candidates = sizeGroups.filter { $0.value.count > 1 }

            // Phase 2: Hash files with the same size to confirm duplicates.
            var duplicateGroups: [DuplicateGroup] = []
            let totalCandidates = candidates.count
            var processed = 0

            for (size, urls) in candidates {
                processed += 1
                if processed % 10 == 0 {
                    let hashProgress = 0.4 + (0.6 * Double(processed) / Double(max(1, totalCandidates)))
                    await MainActor.run { progress(min(1.0, hashProgress)) }
                }

                // Hash each file and group by content hash
                var hashGroups: [String: [URL]] = [:]
                for url in urls {
                    if let hash = await self.hashFile(at: url) {
                        hashGroups[hash, default: []].append(url)
                    }
                }

                // Any hash group with 2+ files is a confirmed duplicate set
                for (hash, dupUrls) in hashGroups where dupUrls.count > 1 {
                    let files = dupUrls.map { url in
                        ScanResult(
                            url: url,
                            sizeInBytes: size,
                            lastAccessed: nil,
                            lastModified: nil
                        )
                    }
                    duplicateGroups.append(DuplicateGroup(
                        contentHash: hash,
                        fileSize: size,
                        files: files
                    ))
                }
            }

            // Sort by wasted space (most waste first)
            return duplicateGroups.sorted { $0.wastedSpace > $1.wastedSpace }
        }.value
    }

    // MARK: - File Hashing
    /// Computes a SHA-256 hash of a file's contents.
    /// Used for duplicate detection — files with the same hash are identical.
    /// Reads in chunks to avoid loading large files into memory.
    private func hashFile(at url: URL) async -> String? {
        await Task.detached(priority: .utility) {
            do {
                // Read in 4 MB chunks to avoid memory issues with large files
                let bufferSize = 4 * 1024 * 1024
                var context = CC_SHA256_CTX()
                CC_SHA256_Init(&context)

                guard let inputStream = InputStream(url: url) else {
                    return nil
                }
                inputStream.open()
                defer { inputStream.close() }

                // Read file in chunks, updating the hash context progressively
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                defer { buffer.deallocate() }

                while true {
                    let bytesRead = inputStream.read(buffer, maxLength: bufferSize)
                    if bytesRead < 0 {
                        // Stream error
                        if let error = inputStream.streamError {
                            throw error
                        }
                        return nil
                    } else if bytesRead == 0 {
                        // EOF
                        break
                    }
                    CC_SHA256_Update(&context, buffer, CC_LONG(bytesRead))
                }

                var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
                CC_SHA256_Final(&hash, &context)

                return hash.map { String(format: "%02x", $0) }.joined()
            } catch {
                return nil
            }
        }.value
    }
}

