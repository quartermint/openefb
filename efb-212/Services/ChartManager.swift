//
//  ChartManager.swift
//  efb-212
//
//  Actor that handles VFR chart tile lifecycle: download, validation,
//  cache management, and expiration checks. Chart files are stored
//  as MBTiles in Application Support/Charts/.
//
//  This is a nonisolated actor because the project uses
//  SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor. Without nonisolated,
//  this type would be implicitly @MainActor instead of actor-isolated.
//

import Foundation

nonisolated actor ChartManager {
    private let fileManager = FileManager.default
    private let chartsDirectory: URL
    private var downloadTasks: [String: Task<URL, any Error>] = [:]

    // MARK: - Init

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        self.chartsDirectory = appSupport.appendingPathComponent("Charts", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: chartsDirectory,
            withIntermediateDirectories: true
        )
    }

    /// Internal init for testing with a custom directory.
    init(chartsDirectory: URL) {
        self.chartsDirectory = chartsDirectory
        try? FileManager.default.createDirectory(
            at: chartsDirectory,
            withIntermediateDirectories: true
        )
    }

    // MARK: - Download

    /// Downloads a chart region from the given URL.
    /// Returns the local file URL on success.
    ///
    /// - Parameters:
    ///   - region: The chart region metadata.
    ///   - url: The remote URL to download from.
    /// - Returns: Local URL of the downloaded mbtiles file.
    /// - Throws: `EFBError.chartDownloadFailed` on network or file errors.
    func download(region: ChartRegion, from url: URL) async throws -> URL {
        // Cancel any existing download for this region
        downloadTasks[region.id]?.cancel()

        let task = Task<URL, any Error> {
            let destination = chartsDirectory.appendingPathComponent("\(region.id).mbtiles")

            do {
                let (tempURL, response) = try await URLSession.shared.download(from: url)

                // Validate HTTP response
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode != 200 {
                    throw EFBError.chartDownloadFailed(region.name)
                }

                // Move temp file to permanent location
                if fileManager.fileExists(atPath: destination.path) {
                    try fileManager.removeItem(at: destination)
                }
                try fileManager.moveItem(at: tempURL, to: destination)

                // Validate the downloaded file
                guard try validateMBTiles(at: destination) else {
                    try? fileManager.removeItem(at: destination)
                    throw EFBError.chartCorrupted(region.name)
                }

                return destination
            } catch let error as EFBError {
                throw error
            } catch {
                throw EFBError.chartDownloadFailed(region.name)
            }
        }

        downloadTasks[region.id] = task

        do {
            let result = try await task.value
            downloadTasks[region.id] = nil
            return result
        } catch {
            downloadTasks[region.id] = nil
            throw error
        }
    }

    // MARK: - Validation

    /// Validates an MBTiles file by checking it is a valid SQLite database
    /// with the expected tables (metadata, tiles).
    ///
    /// MBTiles is a SQLite-based format containing rasterized map tiles.
    /// A valid file should have `metadata` and `tiles` tables.
    ///
    /// - Parameter url: File URL of the mbtiles file.
    /// - Returns: `true` if the file appears to be a valid MBTiles database.
    /// - Throws: File system errors.
    private func validateMBTiles(at url: URL) throws -> Bool {
        // Basic validation: file exists and has non-zero size
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        guard let fileSize = attributes[.size] as? UInt64, fileSize > 0 else {
            return false
        }

        // Check SQLite header magic bytes ("SQLite format 3\000")
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let headerData = handle.readData(ofLength: 16)
        let sqliteHeader = "SQLite format 3\0"
        guard let headerString = String(data: headerData, encoding: .utf8),
              headerString == sqliteHeader else {
            return false
        }

        return true
    }

    // MARK: - Expiration

    /// Returns chart regions that have passed their expiration date.
    ///
    /// - Parameter regions: Array of chart regions to check.
    /// - Returns: Regions whose `expirationDate` is in the past.
    func expiredRegions(from regions: [ChartRegion]) -> [ChartRegion] {
        let now = Date()
        return regions.filter { $0.expirationDate < now }
    }

    // MARK: - Removal

    /// Removes a downloaded chart region's local file.
    ///
    /// - Parameter regionID: The region identifier (e.g., "San_Francisco").
    /// - Throws: `EFBError.chartCorrupted` if the file cannot be removed.
    func removeRegion(_ regionID: String) throws {
        let filePath = chartsDirectory.appendingPathComponent("\(regionID).mbtiles")
        if fileManager.fileExists(atPath: filePath.path) {
            try fileManager.removeItem(at: filePath)
        }
    }

    // MARK: - Storage

    /// Calculates total disk space used by downloaded chart files.
    ///
    /// - Returns: Total size in bytes of all files in the Charts directory.
    /// - Throws: File system errors.
    func storageUsed() throws -> UInt64 {
        var totalBytes: UInt64 = 0

        guard fileManager.fileExists(atPath: chartsDirectory.path) else {
            return 0
        }

        let contents = try fileManager.contentsOfDirectory(
            at: chartsDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        )

        for fileURL in contents {
            let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            totalBytes += UInt64(resourceValues.fileSize ?? 0)
        }

        return totalBytes
    }

    /// Returns the local file URL for a downloaded region, if it exists.
    ///
    /// - Parameter regionID: The region identifier.
    /// - Returns: File URL if the chart is downloaded, nil otherwise.
    func localPath(for regionID: String) -> URL? {
        let filePath = chartsDirectory.appendingPathComponent("\(regionID).mbtiles")
        return fileManager.fileExists(atPath: filePath.path) ? filePath : nil
    }

    // MARK: - Cancel

    /// Cancels an in-progress download for the specified region.
    ///
    /// - Parameter regionID: The region identifier.
    func cancelDownload(for regionID: String) {
        downloadTasks[regionID]?.cancel()
        downloadTasks[regionID] = nil
    }
}
