//
//  LogbookView.swift
//  efb-212
//
//  Traditional pilot logbook format with table-like layout.
//  Uses SwiftData @Query to fetch FlightRecordModel sorted by date descending.
//  Shows columns: Date, From, To, Duration (decimal hours), Distance, Remarks.
//  Summary row at bottom with totals.
//

import SwiftUI
import SwiftData

struct LogbookView: View {
    @Query(sort: \FlightRecordModel.date, order: .reverse)
    private var flights: [FlightRecordModel]

    @StateObject private var viewModel = LogbookViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if flights.isEmpty {
                    emptyState
                } else {
                    logbookContent
                }
            }
            .navigationTitle("Logbook")
            .onChange(of: flights.count) { _, _ in
                viewModel.computeTotals(from: flights)
            }
            .onAppear {
                viewModel.computeTotals(from: flights)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "Your Logbook Is Empty",
            systemImage: "book.closed",
            description: Text("Recorded flights will appear here in logbook format. Add flights from the Flights tab.")
        )
    }

    // MARK: - Logbook Content

    private var logbookContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header row
                logbookHeader

                Divider()

                // Flight rows
                ForEach(flights, id: \.flightID) { flight in
                    logbookRow(for: flight)
                    Divider()
                }

                // Summary / totals row
                summaryRow
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Header

    private var logbookHeader: some View {
        HStack(spacing: 0) {
            headerCell("Date", width: .date)
            headerCell("From", width: .icao)
            headerCell("To", width: .icao)
            headerCell("Hours", width: .duration)
            headerCell("NM", width: .distance)
            headerCell("Remarks", width: .remarks, alignment: .leading)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    // MARK: - Flight Row

    private func logbookRow(for flight: FlightRecordModel) -> some View {
        HStack(spacing: 0) {
            dataCell(formatDate(flight.date), width: .date)
            dataCell(flight.departure, width: .icao, monospaced: true)
            dataCell(flight.arrival, width: .icao, monospaced: true)
            dataCell(viewModel.formatDurationDecimal(flight.duration), width: .duration, monospaced: true)

            if let distance = flight.totalDistance {
                dataCell(String(format: "%.1f", distance), width: .distance, monospaced: true)
            } else {
                dataCell("--", width: .distance)
            }

            dataCell(flight.remarks ?? "", width: .remarks, alignment: .leading, lineLimit: 1)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Summary Row

    private var summaryRow: some View {
        VStack(spacing: 8) {
            Divider()

            HStack(spacing: 0) {
                headerCell("Totals", width: .date)
                headerCell("\(viewModel.totalFlights) flights", width: .icao)
                headerCell("", width: .icao)
                headerCell(viewModel.formatDurationDecimal(viewModel.totalFlightTime), width: .duration)
                headerCell(
                    viewModel.totalDistance > 0
                        ? String(format: "%.1f", viewModel.totalDistance)
                        : "--",
                    width: .distance
                )
                headerCell("", width: .remarks, alignment: .leading)
            }
            .padding(.vertical, 8)
            .background(Color(.systemGray5))
        }
    }

    // MARK: - Cell Helpers

    private func headerCell(
        _ text: String,
        width: ColumnWidth,
        alignment: Alignment = .center
    ) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .frame(width: width.value, alignment: alignment)
    }

    private func dataCell(
        _ text: String,
        width: ColumnWidth,
        monospaced: Bool = false,
        alignment: Alignment = .center,
        lineLimit: Int? = nil
    ) -> some View {
        Text(text)
            .font(.callout)
            .fontDesign(monospaced ? .monospaced : .default)
            .frame(width: width.value, alignment: alignment)
            .lineLimit(lineLimit)
    }

    // MARK: - Date Formatting

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: date)
    }

    // MARK: - Column Widths

    private enum ColumnWidth {
        case date
        case icao
        case duration
        case distance
        case remarks

        var value: CGFloat {
            switch self {
            case .date: return 80
            case .icao: return 60
            case .duration: return 60
            case .distance: return 60
            case .remarks: return 180
            }
        }
    }
}

// MARK: - Previews

#Preview("Logbook") {
    LogbookView()
        .modelContainer(for: FlightRecordModel.self, inMemory: true)
}
