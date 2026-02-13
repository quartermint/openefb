//
//  LogbookViewModel.swift
//  efb-212
//
//  ViewModel for the logbook view. Computes aggregate totals (flights,
//  total time, total distance) and provides duration formatting helpers.
//  MainActor by default (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor).
//

import Foundation
import Combine

final class LogbookViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var totalFlights: Int = 0
    @Published var totalFlightTime: TimeInterval = 0        // seconds
    @Published var totalDistance: Double = 0                 // nautical miles

    // MARK: - Aggregate Computation

    /// Computes totals from an array of flight records.
    /// Call this when the @Query result changes.
    func computeTotals(from records: [FlightRecordModel]) {
        totalFlights = records.count

        totalFlightTime = records.reduce(0) { sum, record in
            sum + record.duration                            // seconds
        }

        totalDistance = records.reduce(0) { sum, record in
            sum + (record.totalDistance ?? 0)                 // nautical miles
        }
    }

    // MARK: - Duration Formatting

    /// Formats a duration in seconds as decimal hours for logbook display.
    /// Example: 5400 seconds → "1.5"
    func formatDurationDecimal(_ duration: TimeInterval) -> String {
        let hours = duration / 3600.0
        return String(format: "%.1f", hours)
    }

    /// Formats a duration in seconds as hours and minutes.
    /// Example: 5400 seconds → "1h 30m"
    func formatDurationHM(_ duration: TimeInterval) -> String {
        let totalMinutes = Int(duration) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }

    // MARK: - Flight Record Creation

    /// Creates a new FlightRecordModel with the given parameters.
    /// The caller is responsible for inserting the record into the model context.
    func createFlightRecord(
        departure: String,
        arrival: String,
        duration: TimeInterval,                              // seconds
        distance: Double? = nil,                             // nautical miles
        remarks: String? = nil
    ) -> FlightRecordModel {
        let record = FlightRecordModel(
            date: Date(),
            departure: departure.uppercased(),
            arrival: arrival.uppercased(),
            duration: duration
        )
        record.totalDistance = distance
        record.remarks = remarks
        return record
    }
}
