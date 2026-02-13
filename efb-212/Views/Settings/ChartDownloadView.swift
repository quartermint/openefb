//
//  ChartDownloadView.swift
//  efb-212
//
//  Chart region download management view.
//  Displays available VFR chart regions with download status, progress,
//  effective/expiration dates, file sizes, and expired warnings.
//

import SwiftUI

struct ChartDownloadView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        List {
            // Storage summary
            Section {
                LabeledContent("Storage Used", value: viewModel.storageUsed)
            }

            // Expired charts warning
            if !viewModel.expiredRegions.isEmpty {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("\(viewModel.expiredRegions.count) chart(s) expired. Download updated charts for current navigation data.")
                            .font(.callout)
                            .foregroundStyle(.orange)
                    }
                }
            }

            // Chart regions
            Section("Available Regions") {
                ForEach(viewModel.chartRegions) { region in
                    ChartRegionRow(
                        region: region,
                        progress: viewModel.downloadProgress[region.id],
                        onDownload: {
                            Task {
                                await viewModel.downloadRegion(region)
                            }
                        },
                        onDelete: {
                            Task {
                                await viewModel.removeRegion(region)
                            }
                        }
                    )
                }
            }
        }
        .navigationTitle("Chart Downloads")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.loadAvailableRegions()
            await viewModel.updateStorageInfo()
        }
        .task {
            viewModel.loadAvailableRegions()
            await viewModel.updateStorageInfo()
        }
    }
}

// MARK: - Chart Region Row

struct ChartRegionRow: View {
    let region: ChartRegion
    let progress: Double?
    let onDownload: () -> Void
    let onDelete: () -> Void

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Name and status
            HStack {
                Text(region.name)
                    .font(.headline)

                Spacer()

                if region.isExpired {
                    Label("Expired", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if region.isDownloaded {
                    Label("Downloaded", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            // Dates
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Effective")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(Self.dateFormatter.string(from: region.effectiveDate))
                        .font(.caption)
                }

                VStack(alignment: .leading) {
                    Text("Expires")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(Self.dateFormatter.string(from: region.expirationDate))
                        .font(.caption)
                        .foregroundStyle(region.isExpired ? .red : .primary)
                }
            }

            // File size
            Text(String(format: "%.1f MB", region.fileSizeMB))  // mbtiles file size in megabytes
                .font(.caption)
                .foregroundStyle(.secondary)

            // Progress bar during download
            if let progress, progress < 1.0 {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.linear)
                Text(String(format: "Downloading... %.0f%%", progress * 100))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Action buttons
            HStack {
                Spacer()
                if region.isDownloaded {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)

                    if region.isExpired {
                        Button {
                            onDownload()
                        } label: {
                            Label("Update", systemImage: "arrow.down.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    Button {
                        onDownload()
                    } label: {
                        Label("Download", systemImage: "arrow.down.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(progress != nil)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

#Preview("Chart Downloads") {
    NavigationStack {
        ChartDownloadView()
    }
}
