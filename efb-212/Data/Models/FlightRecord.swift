//
//  FlightRecord.swift
//  efb-212
//
//  SwiftData model for flight recording metadata.
//  Stored in SchemaV1 for versioned migration support.
//  GRDB stores the high-frequency data (track points, transcripts);
//  this SwiftData model stores the flight-level metadata and summary.
//

import Foundation
import SwiftData

extension SchemaV1 {

    @Model
    final class FlightRecord {
        /// Unique identifier for this flight recording.
        var id: UUID = UUID()

        /// When the recording started.
        var startDate: Date = Date()

        /// When the recording ended (nil if still recording).
        var endDate: Date?

        /// Departure airport ICAO identifier (detected from nearest airport at start).
        var departureICAO: String?

        /// Arrival airport ICAO identifier (detected from nearest airport at end).
        var arrivalICAO: String?

        /// Departure airport display name.
        var departureName: String?

        /// Arrival airport display name.
        var arrivalName: String?

        /// Total recording duration -- seconds.
        var durationSeconds: Double = 0

        /// Relative path to the recorded audio file (within app's documents directory).
        var audioFileURL: String?

        /// Audio quality profile used for this recording ("standard" or "high").
        var audioQuality: String = "standard"  // AudioQualityProfile raw value

        /// Total number of GPS track points recorded.
        var trackPointCount: Int = 0

        /// Total number of transcript segments recorded.
        var transcriptSegmentCount: Int = 0

        /// UUID string of the aircraft profile used during this flight.
        var aircraftProfileID: String?

        /// UUID string of the pilot profile used during this flight.
        var pilotProfileID: String?

        /// Whether an AI debrief has been generated for this flight (Phase 4).
        var hasDebrief: Bool = false

        /// Free-text pilot notes about this flight.
        var notes: String?

        /// Date this record was created.
        var createdAt: Date = Date()

        init() {}
    }
}
