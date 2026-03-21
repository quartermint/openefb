//
//  DebriefTypes.swift
//  efb-212
//
//  @Generable FlightDebrief schema for Apple Foundation Models structured output,
//  DebriefRecord GRDB model for persistence, and FlightMetadata for prompt context.
//
//  FlightDebrief uses @Generable for compile-time constrained decoding:
//  the on-device model is guaranteed to produce a valid FlightDebrief instance.
//
//  DebriefRecord stores the generated debrief in GRDB's debrief_results table
//  alongside the flight recording data (same database, separate table).
//

import Foundation
import FoundationModels
import GRDB

// MARK: - @Generable FlightDebrief Schema

/// Structured output schema for on-device AI flight debrief generation.
/// Used with LanguageModelSession.streamResponse(to:generating:) for constrained decoding.
@Generable
struct FlightDebrief {
    @Guide(description: "A concise narrative summary of the entire flight in 2-3 sentences.")
    let narrativeSummary: String

    @Guide(description: "Observations grouped by detected flight phase.")
    let phaseObservations: [PhaseObservation]

    @Guide(description: "Specific, actionable improvement suggestions for the pilot.")
    let improvements: [String]

    @Guide(description: "Overall flight rating.", .range(1...5))
    let overallRating: Int
}

/// Per-phase observation within a flight debrief.
@Generable
struct PhaseObservation: Codable {
    @Guide(description: "Flight phase name: preflight, taxi, takeoff, departure, cruise, approach, landing, or postflight.")
    let phase: String

    @Guide(description: "Key observations during this phase.")
    let observations: [String]

    @Guide(description: "Whether this phase was executed well.")
    let executedWell: Bool
}

// MARK: - DebriefRecord (GRDB Persistence)

/// Persisted debrief result stored in GRDB debrief_results table.
/// JSON-encodes phaseObservations and improvements for storage.
struct DebriefRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "debrief_results"

    let id: UUID
    let flightID: UUID
    let narrativeSummary: String
    let phaseObservationsJSON: String   // JSON-encoded [PhaseObservation]
    let improvementsJSON: String        // JSON-encoded [String]
    let overallRating: Int              // 1-5
    let generatedAt: Date
    let promptTokensEstimate: Int?
    let responseTokensEstimate: Int?

    nonisolated init(
        id: UUID = UUID(),
        flightID: UUID,
        narrativeSummary: String,
        phaseObservationsJSON: String,
        improvementsJSON: String,
        overallRating: Int,
        generatedAt: Date = Date(),
        promptTokensEstimate: Int? = nil,
        responseTokensEstimate: Int? = nil
    ) {
        self.id = id
        self.flightID = flightID
        self.narrativeSummary = narrativeSummary
        self.phaseObservationsJSON = phaseObservationsJSON
        self.improvementsJSON = improvementsJSON
        self.overallRating = overallRating
        self.generatedAt = generatedAt
        self.promptTokensEstimate = promptTokensEstimate
        self.responseTokensEstimate = responseTokensEstimate
    }

    /// Create a DebriefRecord from a generated FlightDebrief.
    /// JSON-encodes phaseObservations and improvements for GRDB storage.
    static func fromFlightDebrief(
        _ debrief: FlightDebrief,
        flightID: UUID,
        promptTokensEstimate: Int? = nil,
        responseTokensEstimate: Int? = nil
    ) -> DebriefRecord {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let phaseJSON = (try? String(data: encoder.encode(debrief.phaseObservations), encoding: .utf8)) ?? "[]"
        let improvementsJSON = (try? String(data: encoder.encode(debrief.improvements), encoding: .utf8)) ?? "[]"

        return DebriefRecord(
            flightID: flightID,
            narrativeSummary: debrief.narrativeSummary,
            phaseObservationsJSON: phaseJSON,
            improvementsJSON: improvementsJSON,
            overallRating: debrief.overallRating,
            promptTokensEstimate: promptTokensEstimate,
            responseTokensEstimate: responseTokensEstimate
        )
    }

    /// Decoded phase observations from JSON storage.
    var decodedPhaseObservations: [PhaseObservation] {
        guard let data = phaseObservationsJSON.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([PhaseObservation].self, from: data)) ?? []
    }

    /// Decoded improvements from JSON storage.
    var decodedImprovements: [String] {
        guard let data = improvementsJSON.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }
}

// MARK: - Flight Metadata

/// Metadata about a flight for debrief prompt context.
struct FlightMetadata: Sendable {
    let aircraftType: String?
    let pilotName: String?
    let departureICAO: String?
    let arrivalICAO: String?
    let date: Date
    let durationSeconds: Double

    /// Human-readable description for prompt inclusion.
    var description: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let dateStr = formatter.string(from: date)
        let aircraft = aircraftType ?? "Unknown"
        let dep = departureICAO ?? "Unknown"
        let arr = arrivalICAO ?? "Unknown"

        let hours = Int(durationSeconds) / 3600
        let minutes = (Int(durationSeconds) % 3600) / 60

        return "Date: \(dateStr), Aircraft: \(aircraft), From: \(dep) To: \(arr), Duration: \(hours)h\(minutes)m"
    }
}
