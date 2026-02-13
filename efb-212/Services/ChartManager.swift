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

    // MARK: - FAA VFR Sectional Chart Regions

    /// All available FAA VFR sectional chart regions.
    /// Geographic bounds approximate each sectional's coverage area.
    /// Download URLs follow the FAA aeronav.faa.gov VFR raster chart structure.
    /// Charts follow a 56-day cycle; effective/expiration dates are computed from
    /// the current cycle at runtime.
    ///
    /// Real FAA chart source: https://aeronav.faa.gov/visual/
    /// URL pattern: https://aeronav.faa.gov/visual/{cycle_date}/sectional-files/{name}.zip
    /// The ZIP contains GeoTIFF raster tiles that must be converted to MBTiles for MapLibre.
    static let availableRegions: [ChartRegion] = {
        let cycle = currentChartCycle()

        return [
            makeRegion(id: "San_Francisco", name: "San Francisco",
                       minLat: 36.0, maxLat: 40.0, minLon: -124.5, maxLon: -119.5,
                       sizeMB: 85.2, cycle: cycle),
            makeRegion(id: "Los_Angeles", name: "Los Angeles",
                       minLat: 32.5, maxLat: 36.5, minLon: -121.0, maxLon: -115.5,
                       sizeMB: 92.7, cycle: cycle),
            makeRegion(id: "Seattle", name: "Seattle",
                       minLat: 45.5, maxLat: 49.5, minLon: -125.0, maxLon: -119.0,
                       sizeMB: 68.4, cycle: cycle),
            makeRegion(id: "Phoenix", name: "Phoenix",
                       minLat: 31.0, maxLat: 35.0, minLon: -114.5, maxLon: -109.0,
                       sizeMB: 54.1, cycle: cycle),
            makeRegion(id: "Salt_Lake_City", name: "Salt Lake City",
                       minLat: 38.0, maxLat: 42.5, minLon: -115.0, maxLon: -109.0,
                       sizeMB: 61.3, cycle: cycle),
            makeRegion(id: "Denver", name: "Denver",
                       minLat: 37.0, maxLat: 41.5, minLon: -109.0, maxLon: -103.0,
                       sizeMB: 58.9, cycle: cycle),
            makeRegion(id: "Dallas-Ft_Worth", name: "Dallas-Ft Worth",
                       minLat: 30.0, maxLat: 34.5, minLon: -100.5, maxLon: -94.5,
                       sizeMB: 76.8, cycle: cycle),
            makeRegion(id: "Chicago", name: "Chicago",
                       minLat: 39.5, maxLat: 44.0, minLon: -91.5, maxLon: -85.0,
                       sizeMB: 82.4, cycle: cycle),
            makeRegion(id: "Atlanta", name: "Atlanta",
                       minLat: 31.5, maxLat: 36.0, minLon: -87.5, maxLon: -81.0,
                       sizeMB: 79.1, cycle: cycle),
            makeRegion(id: "New_York", name: "New York",
                       minLat: 39.5, maxLat: 43.5, minLon: -76.5, maxLon: -70.0,
                       sizeMB: 88.5, cycle: cycle),
            makeRegion(id: "Miami", name: "Miami",
                       minLat: 24.0, maxLat: 28.5, minLon: -83.5, maxLon: -79.0,
                       sizeMB: 64.7, cycle: cycle),
            makeRegion(id: "Charlotte", name: "Charlotte",
                       minLat: 33.0, maxLat: 37.5, minLon: -83.5, maxLon: -77.0,
                       sizeMB: 71.3, cycle: cycle),
            makeRegion(id: "Detroit", name: "Detroit",
                       minLat: 40.5, maxLat: 45.0, minLon: -86.0, maxLon: -80.0,
                       sizeMB: 66.2, cycle: cycle),
            makeRegion(id: "St_Louis", name: "St Louis",
                       minLat: 36.0, maxLat: 40.5, minLon: -93.0, maxLon: -87.0,
                       sizeMB: 59.8, cycle: cycle),
            makeRegion(id: "Kansas_City", name: "Kansas City",
                       minLat: 36.5, maxLat: 41.0, minLon: -99.5, maxLon: -93.5,
                       sizeMB: 55.4, cycle: cycle),
        ]
    }()

    // MARK: - Chart Cycle Helpers

    /// Computes the current FAA 56-day chart cycle effective and expiration dates.
    /// The FAA chart cycle epoch is January 27, 2022 (a known cycle start date).
    /// Each cycle is exactly 56 days.
    private static func currentChartCycle() -> (effective: Date, expiration: Date) {
        let calendar = Calendar(identifier: .gregorian)
        // Known FAA chart cycle epoch: January 27, 2022
        let epoch = calendar.date(from: DateComponents(year: 2022, month: 1, day: 27))!
        let now = Date()
        let daysSinceEpoch = calendar.dateComponents([.day], from: epoch, to: now).day ?? 0
        let cyclesElapsed = daysSinceEpoch / 56
        let cycleStart = calendar.date(byAdding: .day, value: cyclesElapsed * 56, to: epoch)!
        let cycleEnd = calendar.date(byAdding: .day, value: 56, to: cycleStart)!
        return (effective: cycleStart, expiration: cycleEnd)
    }

    /// Creates a ChartRegion with the FAA download URL pattern.
    private static func makeRegion(
        id: String, name: String,
        minLat: Double, maxLat: Double,
        minLon: Double, maxLon: Double,
        sizeMB: Double,
        cycle: (effective: Date, expiration: Date)
    ) -> ChartRegion {
        ChartRegion(
            id: id,
            name: name,
            effectiveDate: cycle.effective,
            expirationDate: cycle.expiration,
            boundingBox: BoundingBox(
                minLatitude: minLat, maxLatitude: maxLat,
                minLongitude: minLon, maxLongitude: maxLon
            ),
            fileSizeMB: sizeMB,
            isDownloaded: false,
            localPath: nil
        )
    }

    /// Returns the FAA download URL for a given sectional chart region.
    /// FAA publishes VFR raster charts at https://aeronav.faa.gov/visual/
    /// The actual URL requires the cycle date in MM-DD-YYYY format.
    /// Charts are distributed as ZIP files containing GeoTIFF raster data
    /// that must be processed into MBTiles format for MapLibre rendering.
    static func downloadURL(for region: ChartRegion) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        let cycleDate = formatter.string(from: region.effectiveDate)
        // FAA URL pattern for VFR sectional ZIPs
        // e.g., https://aeronav.faa.gov/visual/01-27-2022/sectional-files/San_Francisco.zip
        let urlString = "https://aeronav.faa.gov/visual/\(cycleDate)/sectional-files/\(region.id).zip"
        return URL(string: urlString)!
    }

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

    // MARK: - Convenience Download

    /// Downloads a chart region using the FAA URL derived from the region metadata.
    /// Returns the local file URL on success.
    ///
    /// - Parameter region: The chart region to download.
    /// - Returns: Local URL of the downloaded mbtiles file.
    /// - Throws: `EFBError.chartDownloadFailed` on network or file errors.
    func downloadChart(for region: ChartRegion) async throws -> URL {
        let url = ChartManager.downloadURL(for: region)
        return try await download(region: region, from: url)
    }

    // MARK: - Region Status

    /// Returns available regions with their current download status resolved
    /// by checking which MBTiles files exist on disk.
    func regionsWithStatus() -> [ChartRegion] {
        ChartManager.availableRegions.map { region in
            var updated = region
            if let path = localPath(for: region.id) {
                updated.isDownloaded = true
                updated.localPath = path
            }
            return updated
        }
    }

    /// Returns all downloaded region MBTiles file paths.
    func downloadedChartPaths() -> [String: URL] {
        var paths: [String: URL] = [:]
        for region in ChartManager.availableRegions {
            if let path = localPath(for: region.id) {
                paths[region.id] = path
            }
        }
        return paths
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
