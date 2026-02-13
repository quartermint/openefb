//
//  SettingsViewModel.swift
//  efb-212
//
//  Manages settings state and chart download operations.
//  Provides sample chart regions for demo and delegates actual
//  download/delete operations to ChartManager.
//

import Foundation
import Combine

final class SettingsViewModel: ObservableObject {
    @Published var chartRegions: [ChartRegion] = []
    @Published var downloadProgress: [String: Double] = [:]
    @Published var storageUsed: String = "0 MB"

    private let chartManager = ChartManager()

    // MARK: - Chart Regions

    /// Expired regions from the current list.
    var expiredRegions: [ChartRegion] {
        chartRegions.filter { $0.isExpired }
    }

    /// Loads sample VFR chart regions for demonstration.
    /// In production, these would come from the FAA chart API or a bundled manifest.
    func loadAvailableRegions() {
        let calendar = Calendar.current
        let now = Date()

        // Create sample effective dates (56-day chart cycle)
        let effectiveDate = calendar.date(byAdding: .day, value: -28, to: now) ?? now
        let expirationDate = calendar.date(byAdding: .day, value: 28, to: now) ?? now
        let expiredDate = calendar.date(byAdding: .day, value: -10, to: now) ?? now

        chartRegions = [
            ChartRegion(
                id: "San_Francisco",
                name: "San Francisco",
                effectiveDate: effectiveDate,
                expirationDate: expirationDate,
                boundingBox: BoundingBox(
                    minLatitude: 36.0,
                    maxLatitude: 39.0,
                    minLongitude: -123.5,
                    maxLongitude: -120.5
                ),
                fileSizeMB: 85.2,              // megabytes — mbtiles file
                isDownloaded: false,
                localPath: nil
            ),
            ChartRegion(
                id: "Los_Angeles",
                name: "Los Angeles",
                effectiveDate: effectiveDate,
                expirationDate: expirationDate,
                boundingBox: BoundingBox(
                    minLatitude: 33.0,
                    maxLatitude: 36.0,
                    minLongitude: -120.0,
                    maxLongitude: -117.0
                ),
                fileSizeMB: 92.7,              // megabytes
                isDownloaded: false,
                localPath: nil
            ),
            ChartRegion(
                id: "Seattle",
                name: "Seattle",
                effectiveDate: effectiveDate,
                expirationDate: expirationDate,
                boundingBox: BoundingBox(
                    minLatitude: 46.0,
                    maxLatitude: 49.0,
                    minLongitude: -124.0,
                    maxLongitude: -121.0
                ),
                fileSizeMB: 68.4,              // megabytes
                isDownloaded: true,
                localPath: URL(fileURLWithPath: "/placeholder")
            ),
            ChartRegion(
                id: "Phoenix",
                name: "Phoenix",
                effectiveDate: calendar.date(byAdding: .day, value: -66, to: now) ?? now,
                expirationDate: expiredDate,
                boundingBox: BoundingBox(
                    minLatitude: 31.5,
                    maxLatitude: 34.5,
                    minLongitude: -113.5,
                    maxLongitude: -110.5
                ),
                fileSizeMB: 54.1,              // megabytes
                isDownloaded: true,
                localPath: URL(fileURLWithPath: "/placeholder")
            ),
        ]
    }

    // MARK: - Download / Delete

    /// Simulates downloading a chart region with progress updates.
    func downloadRegion(_ region: ChartRegion) async {
        guard downloadProgress[region.id] == nil else { return }

        downloadProgress[region.id] = 0.0

        // Simulate download progress
        for step in 1...10 {
            try? await Task.sleep(for: .milliseconds(300))
            downloadProgress[region.id] = Double(step) / 10.0
        }

        // Update region status
        if let index = chartRegions.firstIndex(where: { $0.id == region.id }) {
            chartRegions[index].isDownloaded = true
        }

        downloadProgress[region.id] = nil
        await updateStorageInfo()
    }

    /// Removes a downloaded chart region.
    func removeRegion(_ region: ChartRegion) async {
        do {
            try await chartManager.removeRegion(region.id)
        } catch {
            // Non-critical — file may already be removed
        }

        if let index = chartRegions.firstIndex(where: { $0.id == region.id }) {
            chartRegions[index].isDownloaded = false
            chartRegions[index].localPath = nil
        }

        await updateStorageInfo()
    }

    // MARK: - Storage

    /// Updates the displayed storage usage string.
    func updateStorageInfo() async {
        do {
            let bytes = try await chartManager.storageUsed()
            let megabytes = Double(bytes) / 1_048_576.0  // bytes to megabytes
            if megabytes >= 1024 {
                let gigabytes = megabytes / 1024.0
                storageUsed = String(format: "%.2f GB", gigabytes)
            } else {
                storageUsed = String(format: "%.1f MB", megabytes)
            }
        } catch {
            storageUsed = "Unknown"
        }
    }
}
