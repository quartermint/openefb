//
//  SettingsViewModel.swift
//  efb-212
//
//  Manages settings state and chart download operations.
//  Loads chart regions from ChartManager.availableRegions with
//  live download status, and delegates download/delete to ChartManager.
//

import Foundation
import Combine

final class SettingsViewModel: ObservableObject {
    @Published var chartRegions: [ChartRegion] = []
    @Published var downloadProgress: [String: Double] = [:]
    @Published var storageUsed: String = "0 MB"
    @Published var sectionalOpacity: Double = 0.85  // 0.0–1.0, user-adjustable overlay transparency

    private let chartManager = ChartManager()

    // MARK: - Chart Regions

    /// Expired regions from the current list.
    var expiredRegions: [ChartRegion] {
        chartRegions.filter { $0.isExpired }
    }

    /// Loads available FAA VFR sectional chart regions from ChartManager,
    /// resolving download status against files on disk.
    func loadAvailableRegions() {
        Task {
            let regions = await chartManager.regionsWithStatus()
            chartRegions = regions
        }
    }

    // MARK: - Download / Delete

    /// Downloads a chart region via ChartManager with progress updates.
    /// Progress is simulated in steps while the actual download proceeds;
    /// in production, URLSession delegate would provide real progress.
    func downloadRegion(_ region: ChartRegion) async {
        guard downloadProgress[region.id] == nil else { return }

        downloadProgress[region.id] = 0.0

        do {
            // Start the real download in ChartManager
            let downloadTask = Task {
                try await chartManager.downloadChart(for: region)
            }

            // Simulate incremental progress while download runs.
            // A production implementation would use URLSessionDownloadDelegate
            // for byte-level progress. This provides UX feedback in the interim.
            for step in 1...9 {
                try? await Task.sleep(for: .milliseconds(400))
                if downloadTask.isCancelled { break }
                downloadProgress[region.id] = Double(step) / 10.0
            }

            let localURL = try await downloadTask.value
            downloadProgress[region.id] = 1.0

            // Update region status
            if let index = chartRegions.firstIndex(where: { $0.id == region.id }) {
                chartRegions[index].isDownloaded = true
                chartRegions[index].localPath = localURL
            }
        } catch {
            // Download failed — clear progress, leave region as not downloaded
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
