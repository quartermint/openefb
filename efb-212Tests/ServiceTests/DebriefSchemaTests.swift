//
//  DebriefSchemaTests.swift
//  efb-212Tests
//
//  Unit tests for @Generable FlightDebrief schema and DebriefRecord GRDB model.
//  Tests schema compilation, DebriefRecord persistence round-trips, and JSON encoding.
//

import Testing
import Foundation
import GRDB
@testable import efb_212

@Suite("Debrief Schema Tests")
struct DebriefSchemaTests {

    // MARK: - Test Helpers

    /// Create a temporary RecordingDatabase for test isolation.
    /// Uses a unique temp file since DatabasePool requires a real file (not :memory:).
    private func makeTestDatabase() throws -> RecordingDatabase {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_debrief_\(UUID().uuidString).sqlite").path
        let pool = try DatabasePool(path: dbPath)
        return try RecordingDatabase(dbPool: pool)
    }

    // MARK: - FlightDebrief Schema Tests

    @Test("FlightDebrief struct can be manually instantiated (compilation proof)")
    func flightDebriefCompiles() {
        let debrief = FlightDebrief(
            narrativeSummary: "A smooth VFR flight from KSFO to KSJC with good weather conditions.",
            phaseObservations: [
                PhaseObservation(
                    phase: "cruise",
                    observations: ["Maintained altitude well", "Smooth turns"],
                    executedWell: true
                )
            ],
            improvements: ["Consider wider pattern on approach"],
            overallRating: 4
        )

        #expect(debrief.narrativeSummary.contains("KSFO"))
        #expect(debrief.phaseObservations.count == 1)
        #expect(debrief.improvements.count == 1)
        #expect(debrief.overallRating == 4)
    }

    @Test("PhaseObservation struct compiles with phase, observations, executedWell fields")
    func phaseObservationCompiles() {
        let obs = PhaseObservation(
            phase: "takeoff",
            observations: ["Good rotation speed", "Centerline maintained"],
            executedWell: true
        )

        #expect(obs.phase == "takeoff")
        #expect(obs.observations.count == 2)
        #expect(obs.executedWell == true)
    }

    // MARK: - DebriefRecord Persistence Tests

    @Test("DebriefRecord can be inserted into and fetched from a test GRDB database with v2_debrief migration")
    func debriefRecordRoundTrip() throws {
        let db = try makeTestDatabase()
        let flightID = UUID()

        let record = DebriefRecord(
            flightID: flightID,
            narrativeSummary: "Test flight summary",
            phaseObservationsJSON: "[{\"phase\":\"cruise\",\"observations\":[\"Good altitude\"],\"executedWell\":true}]",
            improvementsJSON: "[\"Practice crosswind landings\"]",
            overallRating: 4,
            generatedAt: Date(),
            promptTokensEstimate: 2500,
            responseTokensEstimate: 800
        )

        try db.insertDebrief(record)

        let fetched = try db.debrief(forFlight: flightID)
        #expect(fetched != nil)
        #expect(fetched?.flightID == flightID)
        #expect(fetched?.narrativeSummary == "Test flight summary")
        #expect(fetched?.overallRating == 4)
        #expect(fetched?.promptTokensEstimate == 2500)
        #expect(fetched?.responseTokensEstimate == 800)
    }

    @Test("DebriefRecord.fromFlightDebrief converts FlightDebrief into JSON-encoded columns")
    func debriefRecordFromFlightDebrief() throws {
        let flightID = UUID()
        let debrief = FlightDebrief(
            narrativeSummary: "A well-executed practice flight.",
            phaseObservations: [
                PhaseObservation(phase: "takeoff", observations: ["Good rotation"], executedWell: true),
                PhaseObservation(phase: "cruise", observations: ["Altitude stable"], executedWell: true)
            ],
            improvements: ["Check ATIS before taxi", "Improve radio phraseology"],
            overallRating: 3
        )

        let record = DebriefRecord.fromFlightDebrief(
            debrief,
            flightID: flightID,
            promptTokensEstimate: 2000,
            responseTokensEstimate: 500
        )

        #expect(record.flightID == flightID)
        #expect(record.narrativeSummary == "A well-executed practice flight.")
        #expect(record.overallRating == 3)

        // Verify JSON encoding of phaseObservations
        let decodedPhases = record.decodedPhaseObservations
        #expect(decodedPhases.count == 2)
        #expect(decodedPhases[0].phase == "takeoff")
        #expect(decodedPhases[1].phase == "cruise")

        // Verify JSON encoding of improvements
        let decodedImprovements = record.decodedImprovements
        #expect(decodedImprovements.count == 2)
        #expect(decodedImprovements[0] == "Check ATIS before taxi")
        #expect(decodedImprovements[1] == "Improve radio phraseology")

        // Verify it can be persisted to database
        let db = try makeTestDatabase()
        try db.insertDebrief(record)
        let fetched = try db.debrief(forFlight: flightID)
        #expect(fetched != nil)
        #expect(fetched?.decodedPhaseObservations.count == 2)
    }

    @Test("DebriefRecord delete removes debrief for a flight")
    func debriefRecordDelete() throws {
        let db = try makeTestDatabase()
        let flightID = UUID()

        let record = DebriefRecord(
            flightID: flightID,
            narrativeSummary: "Test",
            phaseObservationsJSON: "[]",
            improvementsJSON: "[]",
            overallRating: 3
        )

        try db.insertDebrief(record)
        #expect(try db.debrief(forFlight: flightID) != nil)

        try db.deleteDebrief(forFlight: flightID)
        #expect(try db.debrief(forFlight: flightID) == nil)
    }

    @Test("DebriefRecord INSERT OR REPLACE overwrites on same flightID")
    func debriefRecordOverwrite() throws {
        let db = try makeTestDatabase()
        let flightID = UUID()

        let record1 = DebriefRecord(
            flightID: flightID,
            narrativeSummary: "First debrief",
            phaseObservationsJSON: "[]",
            improvementsJSON: "[]",
            overallRating: 3
        )
        try db.insertDebrief(record1)

        // Insert a second debrief for the same flight (regeneration)
        let record2 = DebriefRecord(
            flightID: flightID,
            narrativeSummary: "Regenerated debrief",
            phaseObservationsJSON: "[]",
            improvementsJSON: "[]",
            overallRating: 4
        )
        try db.insertDebrief(record2)

        let fetched = try db.debrief(forFlight: flightID)
        #expect(fetched?.narrativeSummary == "Regenerated debrief")
        #expect(fetched?.overallRating == 4)
    }
}
