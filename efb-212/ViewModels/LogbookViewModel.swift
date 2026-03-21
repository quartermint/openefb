//
//  LogbookViewModel.swift
//  efb-212
//
//  Logbook CRUD, auto-population from recording data, duration formatting.
//  Uses @Observable (iOS 26 pattern). SwiftData ModelContext for persistence.
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class LogbookViewModel {

    // MARK: - Published State

    /// All logbook entries, sorted by date descending (most recent first).
    var entries: [SchemaV1.LogbookEntry] = []

    /// Currently selected entry for detail/edit view.
    var selectedEntry: SchemaV1.LogbookEntry?

    /// Whether the edit sheet is presented.
    var isShowingEditSheet: Bool = false

    /// Whether the manual entry creation sheet is presented.
    var isShowingManualEntry: Bool = false

    /// Total number of flights in the logbook.
    var totalFlights: Int = 0

    /// Total flight time across all entries -- seconds.
    var totalFlightTimeSeconds: Double = 0

    // MARK: - CRUD Operations

    /// Fetch all LogbookEntry from modelContext, sorted by date descending.
    func loadEntries(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<SchemaV1.LogbookEntry>(
            sortBy: [SortDescriptor(\SchemaV1.LogbookEntry.date, order: .reverse)]
        )

        do {
            entries = try modelContext.fetch(descriptor)
            totalFlights = entries.count
            totalFlightTimeSeconds = entries.reduce(0) { $0 + $1.durationSeconds }
        } catch {
            entries = []
            totalFlights = 0
            totalFlightTimeSeconds = 0
        }
    }

    /// Create a logbook entry auto-populated from a flight recording summary.
    /// Called by RecordingViewModel after recording stops (LOG-01 auto-population trigger).
    ///
    /// - Parameters:
    ///   - summary: The flight recording summary with flightID, times, counts.
    ///   - departureICAO: Nearest airport ICAO at recording start (from R-tree lookup).
    ///   - departureName: Display name of departure airport.
    ///   - arrivalICAO: Nearest airport ICAO at recording end (from R-tree lookup).
    ///   - arrivalName: Display name of arrival airport.
    ///   - aircraftProfileID: UUID of the active aircraft profile.
    ///   - aircraftType: Denormalized aircraft type string for display.
    ///   - pilotProfileID: UUID of the active pilot profile.
    ///   - modelContext: SwiftData model context for insertion.
    /// - Returns: The newly created logbook entry (unconfirmed, ready for pilot review).
    @discardableResult
    func createFromRecording(
        summary: FlightRecordingSummary,
        departureICAO: String?,
        departureName: String?,
        arrivalICAO: String?,
        arrivalName: String?,
        aircraftProfileID: UUID?,
        aircraftType: String?,
        pilotProfileID: UUID?,
        modelContext: ModelContext
    ) -> SchemaV1.LogbookEntry {
        let entry = SchemaV1.LogbookEntry()
        entry.flightID = summary.flightID
        entry.date = summary.startDate
        entry.departureICAO = departureICAO
        entry.departureName = departureName
        entry.arrivalICAO = arrivalICAO
        entry.arrivalName = arrivalName
        entry.durationSeconds = summary.endDate.timeIntervalSince(summary.startDate)
        entry.aircraftProfileID = aircraftProfileID?.uuidString
        entry.aircraftType = aircraftType
        entry.pilotProfileID = pilotProfileID?.uuidString
        entry.isConfirmed = false

        modelContext.insert(entry)
        return entry
    }

    /// Create a blank manual logbook entry (for flights not recorded with the app).
    @discardableResult
    func createManualEntry(modelContext: ModelContext) -> SchemaV1.LogbookEntry {
        let entry = SchemaV1.LogbookEntry()
        entry.flightID = nil
        entry.date = Date()
        entry.isConfirmed = false

        modelContext.insert(entry)
        return entry
    }

    /// Confirm (lock) a logbook entry after pilot review.
    /// Once confirmed, the entry should not be edited further.
    func confirmEntry(_ entry: SchemaV1.LogbookEntry) {
        entry.isConfirmed = true
    }

    /// Delete a logbook entry.
    func deleteEntry(_ entry: SchemaV1.LogbookEntry, modelContext: ModelContext) {
        modelContext.delete(entry)
    }

    // MARK: - Duration Formatting

    /// Format duration in seconds as decimal hours (one decimal place).
    /// Example: 3600 -> "1.0", 5400 -> "1.5"
    /// Pure function -- nonisolated for use from any context.
    nonisolated static func formatDurationDecimal(_ seconds: Double) -> String {
        let hours = seconds / 3600.0
        return String(format: "%.1f", hours)
    }

    /// Format duration in seconds as hours and minutes.
    /// Example: 5400 -> "1h 30m", 0 -> "0h 0m"
    /// Pure function -- nonisolated for use from any context.
    nonisolated static func formatDurationHM(_ seconds: Double) -> String {
        let totalMinutes = Int(seconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }
}
