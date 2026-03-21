//
//  FlightHistoryListView.swift
//  efb-212
//
//  Chronological flight history list displaying recorded flights.
//  Sorted by date descending (most recent first).
//  Tapping a flight opens FlightDetailView with Replay + Debrief options.
//
//  REPLAY-01: Flight history provides entry point to track replay.
//

import SwiftUI
import SwiftData

struct FlightHistoryListView: View {
    @Query(sort: \SchemaV1.FlightRecord.startDate, order: .reverse)
    private var flightRecords: [SchemaV1.FlightRecord]

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        Group {
            if flightRecords.isEmpty {
                emptyState
            } else {
                flightList
            }
        }
        .navigationTitle("Flight History")
    }

    // MARK: - Flight List

    @ViewBuilder
    private var flightList: some View {
        List {
            ForEach(flightRecords) { record in
                NavigationLink {
                    FlightDetailView(flightRecord: record)
                } label: {
                    FlightHistoryRow(record: record)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "airplane")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No flights recorded yet.")
                .font(.headline)
            Text("Start a recording from the Map tab.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Flight History Row

private struct FlightHistoryRow: View {
    let record: SchemaV1.FlightRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Date
                Text(record.startDate, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Route: departure -> arrival
                HStack(spacing: 4) {
                    Text(record.departureICAO ?? "---")
                        .font(.headline)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(record.arrivalICAO ?? "---")
                        .font(.headline)
                }

                // Duration
                Text(LogbookViewModel.formatDurationHM(record.durationSeconds))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Track point count badge
            if record.trackPointCount > 0 {
                VStack(spacing: 2) {
                    Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("\(record.trackPointCount)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
