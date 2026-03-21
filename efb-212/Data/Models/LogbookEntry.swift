//
//  LogbookEntry.swift
//  efb-212
//
//  SwiftData model for digital logbook entries.
//  Auto-populated from FlightRecordingSummary after recording stops,
//  or created manually for flights not recorded with the app.
//  Stored in SchemaV1 for versioned migration support.
//

import Foundation
import SwiftData

// MARK: - LogbookEntry

extension SchemaV1 {

    @Model
    final class LogbookEntry {
        /// Unique identifier for this logbook entry.
        var id: UUID = UUID()

        /// Links to RecordingDatabase flight (nil for manual entries).
        var flightID: UUID?

        /// Flight date.
        var date: Date = Date()

        /// Departure airport ICAO (auto-detected from R-tree or manually entered).
        var departureICAO: String?

        /// Departure airport display name.
        var departureName: String?

        /// Arrival airport ICAO (auto-detected from R-tree or manually entered).
        var arrivalICAO: String?

        /// Arrival airport display name.
        var arrivalName: String?

        /// Route string (waypoints between departure and arrival).
        var route: String?

        /// Block time -- seconds.
        var durationSeconds: Double = 0

        /// UUID string of aircraft profile used during this flight.
        var aircraftProfileID: String?

        /// Denormalized aircraft type for display without profile lookup.
        var aircraftType: String?

        /// UUID string of pilot profile.
        var pilotProfileID: String?

        /// Number of full-stop night landings (for 61.57 currency).
        var nightLandingCount: Int = 0

        /// Total day landings.
        var dayLandingCount: Int = 0

        /// Pilot remarks/notes.
        var notes: String?

        /// Locked after pilot review -- prevents further edits.
        var isConfirmed: Bool = false

        /// Whether AI debrief has been generated for this flight.
        var hasDebrief: Bool = false

        /// Date this entry was created.
        var createdAt: Date = Date()

        init() {}
    }
}
