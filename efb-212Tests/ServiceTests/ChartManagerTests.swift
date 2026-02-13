//
//  ChartManagerTests.swift
//  efb-212Tests
//
//  Tests for ChartManager: available regions, region bounds,
//  download URL generation, and chart cycle computation.
//

import Testing
import Foundation
@testable import efb_212

@Suite("ChartManager Tests")
struct ChartManagerTests {

    // MARK: - Available Regions

    @Test func availableRegionsCount() {
        let regions = ChartManager.availableRegions
        #expect(regions.count == 15, "Should have 15 FAA VFR sectional chart regions")
    }

    @Test func allRegionsHaveUniqueIDs() {
        let regions = ChartManager.availableRegions
        let ids = regions.map(\.id)
        let uniqueIDs = Set(ids)
        #expect(uniqueIDs.count == ids.count, "All region IDs should be unique")
    }

    @Test func allRegionsHaveNonEmptyNames() {
        for region in ChartManager.availableRegions {
            #expect(!region.name.isEmpty, "Region \(region.id) should have a non-empty name")
        }
    }

    @Test func allRegionsHavePositiveFileSize() {
        for region in ChartManager.availableRegions {
            #expect(region.fileSizeMB > 0, "Region \(region.id) should have positive file size")
        }
    }

    @Test func allRegionsNotDownloadedByDefault() {
        for region in ChartManager.availableRegions {
            #expect(!region.isDownloaded, "Region \(region.id) should not be downloaded by default")
            #expect(region.localPath == nil, "Region \(region.id) should have nil localPath by default")
        }
    }

    // MARK: - Region Bounds Validity

    @Test func allBoundsHaveValidLatitude() {
        for region in ChartManager.availableRegions {
            let box = region.boundingBox
            #expect(box.minLatitude >= -90 && box.minLatitude <= 90,
                    "\(region.id) minLatitude \(box.minLatitude) out of range")
            #expect(box.maxLatitude >= -90 && box.maxLatitude <= 90,
                    "\(region.id) maxLatitude \(box.maxLatitude) out of range")
        }
    }

    @Test func allBoundsHaveValidLongitude() {
        for region in ChartManager.availableRegions {
            let box = region.boundingBox
            #expect(box.minLongitude >= -180 && box.minLongitude <= 180,
                    "\(region.id) minLongitude \(box.minLongitude) out of range")
            #expect(box.maxLongitude >= -180 && box.maxLongitude <= 180,
                    "\(region.id) maxLongitude \(box.maxLongitude) out of range")
        }
    }

    @Test func allBoundsMinLessThanMax() {
        for region in ChartManager.availableRegions {
            let box = region.boundingBox
            #expect(box.minLatitude < box.maxLatitude,
                    "\(region.id) minLatitude should be < maxLatitude")
            #expect(box.minLongitude < box.maxLongitude,
                    "\(region.id) minLongitude should be < maxLongitude")
        }
    }

    @Test func boundsHaveReasonableSize() {
        // Each sectional covers roughly 3-6 degrees of lat/lon
        for region in ChartManager.availableRegions {
            let box = region.boundingBox
            let latSpan = box.maxLatitude - box.minLatitude
            let lonSpan = box.maxLongitude - box.minLongitude

            #expect(latSpan >= 2.0, "\(region.id) latitude span \(latSpan) seems too small")
            #expect(latSpan <= 10.0, "\(region.id) latitude span \(latSpan) seems too large")
            #expect(lonSpan >= 3.0, "\(region.id) longitude span \(lonSpan) seems too small")
            #expect(lonSpan <= 10.0, "\(region.id) longitude span \(lonSpan) seems too large")
        }
    }

    @Test func boundsAreInCONUS() {
        // All 15 regions are CONUS (not Alaska/Hawaii in chart regions)
        for region in ChartManager.availableRegions {
            let box = region.boundingBox
            // CONUS bounds: lat 24..50, lon -125..-65
            #expect(box.minLatitude >= 20.0, "\(region.id) minLat \(box.minLatitude) below CONUS")
            #expect(box.maxLatitude <= 52.0, "\(region.id) maxLat \(box.maxLatitude) above CONUS")
            #expect(box.minLongitude >= -130.0, "\(region.id) minLon \(box.minLongitude) west of CONUS")
            #expect(box.maxLongitude <= -65.0, "\(region.id) maxLon \(box.maxLongitude) east of CONUS")
        }
    }

    // MARK: - Known Regions Present

    @Test func knownRegionsPresent() {
        let ids = Set(ChartManager.availableRegions.map(\.id))
        #expect(ids.contains("San_Francisco"))
        #expect(ids.contains("Los_Angeles"))
        #expect(ids.contains("Seattle"))
        #expect(ids.contains("Chicago"))
        #expect(ids.contains("New_York"))
        #expect(ids.contains("Miami"))
        #expect(ids.contains("Atlanta"))
        #expect(ids.contains("Dallas-Ft_Worth"))
        #expect(ids.contains("Denver"))
    }

    // MARK: - Download URL Generation

    @Test func downloadURLContainsRegionID() {
        let region = ChartManager.availableRegions.first!
        let url = ChartManager.downloadURL(for: region)
        #expect(url.absoluteString.contains(region.id),
                "Download URL should contain the region ID")
    }

    @Test func downloadURLHasCorrectHost() {
        let region = ChartManager.availableRegions.first!
        let url = ChartManager.downloadURL(for: region)
        #expect(url.host == "aeronav.faa.gov",
                "Download URL should use FAA host")
    }

    @Test func downloadURLPathContainsSectionalFiles() {
        let region = ChartManager.availableRegions.first!
        let url = ChartManager.downloadURL(for: region)
        #expect(url.absoluteString.contains("sectional-files"),
                "Download URL should include sectional-files path")
    }

    @Test func downloadURLEndsWithZip() {
        let region = ChartManager.availableRegions.first!
        let url = ChartManager.downloadURL(for: region)
        #expect(url.pathExtension == "zip",
                "Download URL should end with .zip extension")
    }

    @Test func downloadURLContainsDateInCorrectFormat() {
        let region = ChartManager.availableRegions.first!
        let url = ChartManager.downloadURL(for: region)
        let urlString = url.absoluteString

        // Should contain a date in MM-dd-yyyy format in the path
        // e.g., https://aeronav.faa.gov/visual/01-27-2022/sectional-files/San_Francisco.zip
        let datePattern = #"\/\d{2}-\d{2}-\d{4}\/"#
        let hasDate = urlString.range(of: datePattern, options: .regularExpression) != nil
        #expect(hasDate, "URL should contain date in MM-dd-yyyy format: \(urlString)")
    }

    @Test func allRegionsGenerateValidURLs() {
        for region in ChartManager.availableRegions {
            let url = ChartManager.downloadURL(for: region)
            #expect(url.scheme == "https", "\(region.id) URL should use HTTPS")
            #expect(url.absoluteString.contains(region.id),
                    "\(region.id) URL should contain region ID")
        }
    }

    // MARK: - Chart Cycle Dates

    @Test func effectiveDateIsBeforeExpirationDate() {
        for region in ChartManager.availableRegions {
            #expect(region.effectiveDate < region.expirationDate,
                    "\(region.id) effective date should be before expiration date")
        }
    }

    @Test func chartCycleIs56Days() {
        guard let region = ChartManager.availableRegions.first else {
            #expect(Bool(false), "No regions available")
            return
        }
        let interval = region.expirationDate.timeIntervalSince(region.effectiveDate)
        let days = interval / 86400.0
        #expect(abs(days - 56.0) < 1.0, "Chart cycle should be 56 days, got \(days)")
    }

    @Test func allRegionsShareSameCycleDates() {
        let regions = ChartManager.availableRegions
        guard let first = regions.first else { return }

        for region in regions.dropFirst() {
            #expect(region.effectiveDate == first.effectiveDate,
                    "\(region.id) should have same effective date as \(first.id)")
            #expect(region.expirationDate == first.expirationDate,
                    "\(region.id) should have same expiration date as \(first.id)")
        }
    }

    // MARK: - Expired Regions Check

    @Test func expiredRegionsDetection() async {
        let chartManager = ChartManager()

        // Create a region that expired yesterday
        let yesterday = Date(timeIntervalSinceNow: -86400)
        let lastWeek = Date(timeIntervalSinceNow: -86400 * 7)

        let expiredRegion = ChartRegion(
            id: "Test_Expired",
            name: "Test Expired",
            effectiveDate: lastWeek,
            expirationDate: yesterday,
            boundingBox: BoundingBox(minLatitude: 30, maxLatitude: 35, minLongitude: -100, maxLongitude: -95),
            fileSizeMB: 10.0,
            isDownloaded: true,
            localPath: nil
        )

        // Create a region that expires next month
        let nextMonth = Date(timeIntervalSinceNow: 86400 * 30)
        let today = Date()

        let validRegion = ChartRegion(
            id: "Test_Valid",
            name: "Test Valid",
            effectiveDate: today,
            expirationDate: nextMonth,
            boundingBox: BoundingBox(minLatitude: 30, maxLatitude: 35, minLongitude: -100, maxLongitude: -95),
            fileSizeMB: 10.0,
            isDownloaded: true,
            localPath: nil
        )

        let expired = await chartManager.expiredRegions(from: [expiredRegion, validRegion])
        #expect(expired.count == 1)
        #expect(expired.first?.id == "Test_Expired")
    }

    // MARK: - Storage (empty directory)

    @Test func storageUsedForEmptyDirectory() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("chart-test-\(UUID().uuidString)", isDirectory: true)
        let chartManager = ChartManager(chartsDirectory: tempDir)

        let bytes = try await chartManager.storageUsed()
        #expect(bytes == 0, "Empty charts directory should use 0 bytes")

        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }

    @Test func localPathForNonExistentRegion() async {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("chart-test-\(UUID().uuidString)", isDirectory: true)
        let chartManager = ChartManager(chartsDirectory: tempDir)

        let path = await chartManager.localPath(for: "NonExistent")
        #expect(path == nil, "Non-existent region should return nil path")

        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }
}
