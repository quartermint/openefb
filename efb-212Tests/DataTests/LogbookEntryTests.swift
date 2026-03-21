//
//  LogbookEntryTests.swift
//  efb-212Tests
//
//  Unit tests for LogbookEntry SwiftData model, duration formatting,
//  auto-population from recording summary, and confirm workflow.
//

import Testing
import Foundation
import SwiftData
@testable import efb_212

@Suite("LogbookEntry Tests")
struct LogbookEntryTests {

    // MARK: - Default Values

    @Test func defaultValues() {
        let entry = SchemaV1.LogbookEntry()
        #expect(entry.isConfirmed == false)
        #expect(entry.nightLandingCount == 0)
        #expect(entry.dayLandingCount == 0)
        #expect(entry.durationSeconds == 0)
        #expect(entry.flightID == nil)
        #expect(entry.departureICAO == nil)
        #expect(entry.arrivalICAO == nil)
        #expect(entry.hasDebrief == false)
        #expect(entry.notes == nil)
    }

    // MARK: - Duration Formatting: Decimal Hours

    @Test func formatDurationDecimal1Hour() {
        let result = LogbookViewModel.formatDurationDecimal(3600)
        #expect(result == "1.0")
    }

    @Test func formatDurationDecimal1Point5() {
        let result = LogbookViewModel.formatDurationDecimal(5400)
        #expect(result == "1.5")
    }

    @Test func formatDurationDecimalZero() {
        let result = LogbookViewModel.formatDurationDecimal(0)
        #expect(result == "0.0")
    }

    // MARK: - Duration Formatting: Hours and Minutes

    @Test func formatDurationHM1Hour30Min() {
        let result = LogbookViewModel.formatDurationHM(5400)
        #expect(result == "1h 30m")
    }

    @Test func formatDurationHMZero() {
        let result = LogbookViewModel.formatDurationHM(0)
        #expect(result == "0h 0m")
    }

    @Test func formatDurationHM2Hours() {
        let result = LogbookViewModel.formatDurationHM(7200)
        #expect(result == "2h 0m")
    }

    // MARK: - Create From Recording (field mapping)

    @Test @MainActor func createFromRecordingSetsFields() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SchemaV1.LogbookEntry.self,
            configurations: config
        )
        let context = container.mainContext

        let flightID = UUID()
        let startDate = Date(timeIntervalSince1970: 1_700_000_000)
        let endDate = Date(timeIntervalSince1970: 1_700_003_600)  // +1 hour
        let aircraftID = UUID()
        let pilotID = UUID()

        let summary = FlightRecordingSummary(
            flightID: flightID,
            startDate: startDate,
            endDate: endDate,
            trackPointCount: 3600,
            transcriptSegmentCount: 42,
            departureICAO: nil,
            arrivalICAO: nil,
            phases: [],
            audioFileURL: nil
        )

        let vm = LogbookViewModel()
        let entry = vm.createFromRecording(
            summary: summary,
            departureICAO: "KPAO",
            departureName: "Palo Alto",
            arrivalICAO: "KSQL",
            arrivalName: "San Carlos",
            aircraftProfileID: aircraftID,
            aircraftType: "C172",
            pilotProfileID: pilotID,
            modelContext: context
        )

        #expect(entry.flightID == flightID)
        #expect(entry.date == startDate)
        #expect(entry.departureICAO == "KPAO")
        #expect(entry.departureName == "Palo Alto")
        #expect(entry.arrivalICAO == "KSQL")
        #expect(entry.arrivalName == "San Carlos")
        #expect(entry.durationSeconds == 3600)
        #expect(entry.aircraftProfileID == aircraftID.uuidString)
        #expect(entry.aircraftType == "C172")
        #expect(entry.pilotProfileID == pilotID.uuidString)
        #expect(entry.isConfirmed == false)
    }

    @Test @MainActor func createFromRecordingWithNilAirports() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SchemaV1.LogbookEntry.self,
            configurations: config
        )
        let context = container.mainContext

        let summary = FlightRecordingSummary(
            flightID: UUID(),
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            trackPointCount: 100,
            transcriptSegmentCount: 0,
            departureICAO: nil,
            arrivalICAO: nil,
            phases: [],
            audioFileURL: nil
        )

        let vm = LogbookViewModel()
        let entry = vm.createFromRecording(
            summary: summary,
            departureICAO: nil,
            departureName: nil,
            arrivalICAO: nil,
            arrivalName: nil,
            aircraftProfileID: nil,
            aircraftType: nil,
            pilotProfileID: nil,
            modelContext: context
        )

        #expect(entry.departureICAO == nil)
        #expect(entry.arrivalICAO == nil)
        #expect(entry.aircraftProfileID == nil)
        #expect(entry.aircraftType == nil)
    }

    // MARK: - Confirm Entry

    @Test @MainActor func confirmedEntryIsLocked() {
        let entry = SchemaV1.LogbookEntry()
        #expect(entry.isConfirmed == false)

        let vm = LogbookViewModel()
        vm.confirmEntry(entry)

        #expect(entry.isConfirmed == true)
    }
}
