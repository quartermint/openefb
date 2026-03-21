//
//  FlightSummaryBuilderTests.swift
//  efb-212Tests
//
//  Unit tests for FlightSummaryBuilder token-budgeted flight data compression.
//

import Testing
import Foundation
@testable import efb_212

@Suite("FlightSummaryBuilder Tests")
struct FlightSummaryBuilderTests {

    // MARK: - Test Helpers

    /// Reference date for test data generation.
    private let baseDate = Date(timeIntervalSinceReferenceDate: 0) // 2001-01-01 00:00:00

    /// All 8 flight phase names for a full flight.
    private let allPhases: [String] = FlightPhaseType.allCases.map(\.rawValue)

    /// Create test phase markers for a full 8-phase flight.
    /// Each phase lasts 300 seconds (5 minutes) sequentially.
    private func makeEightPhaseMarkers(flightID: UUID) -> [PhaseMarkerRecord] {
        allPhases.enumerated().map { index, phase in
            let start = baseDate.addingTimeInterval(Double(index) * 300)
            let end = baseDate.addingTimeInterval(Double(index + 1) * 300)
            return PhaseMarkerRecord(
                flightID: flightID,
                phase: phase,
                startTimestamp: start,
                endTimestamp: end,
                latitude: 37.0 + Double(index) * 0.1,
                longitude: -122.0
            )
        }
    }

    /// Create test track points for a phase (10 points per phase).
    private func makeTrackPoints(
        flightID: UUID,
        phase: PhaseMarkerRecord,
        count: Int = 10,
        altitudeFeet: Double = 5000,
        groundSpeedKnots: Double = 120
    ) -> [TrackPointRecord] {
        let duration = phase.endTimestamp?.timeIntervalSince(phase.startTimestamp) ?? 300
        return (0..<count).map { i in
            let t = phase.startTimestamp.addingTimeInterval(duration * Double(i) / Double(count))
            return TrackPointRecord(
                flightID: flightID,
                timestamp: t,
                latitude: phase.latitude,
                longitude: phase.longitude,
                altitudeFeet: altitudeFeet + Double(i) * 10,
                groundSpeedKnots: groundSpeedKnots + Double(i),
                verticalSpeedFPM: Double(i) * 50,
                courseDegrees: 270
            )
        }
    }

    /// Create test transcript segments for a phase.
    private func makeTranscripts(
        flightID: UUID,
        phase: String,
        texts: [String],
        confidences: [Double]
    ) -> [TranscriptSegmentRecord] {
        zip(texts, confidences).enumerated().map { index, pair in
            TranscriptSegmentRecord(
                flightID: flightID,
                timestamp: baseDate.addingTimeInterval(Double(index)),
                text: pair.0,
                confidence: pair.1,
                audioStartTime: Double(index),
                audioEndTime: Double(index) + 1,
                flightPhase: phase
            )
        }
    }

    /// Standard test flight metadata.
    private var testMetadata: FlightMetadata {
        FlightMetadata(
            aircraftType: "C172",
            pilotName: "Test Pilot",
            departureICAO: "KSFO",
            arrivalICAO: "KSJC",
            date: baseDate,
            durationSeconds: 2400 // 40 minutes
        )
    }

    // MARK: - Tests

    @Test("8-phase flight prompt is under 12,600 characters (3,000 token budget)")
    func eightPhasePromptUnderBudget() {
        let flightID = UUID()
        let phases = makeEightPhaseMarkers(flightID: flightID)

        // Generate track points and transcripts for all phases
        var allTrackPoints: [TrackPointRecord] = []
        var allTranscripts: [TranscriptSegmentRecord] = []

        for phase in phases {
            allTrackPoints += makeTrackPoints(flightID: flightID, phase: phase)
            allTranscripts += makeTranscripts(
                flightID: flightID,
                phase: phase.phase,
                texts: [
                    "Cleared for takeoff runway 28L",
                    "Turn left heading 270",
                    "Contact NorCal approach",
                    "Descending to three thousand"
                ],
                confidences: [0.95, 0.88, 0.92, 0.85]
            )
        }

        let prompt = FlightSummaryBuilder.buildPrompt(
            trackPoints: allTrackPoints,
            transcriptSegments: allTranscripts,
            phaseMarkers: phases,
            metadata: testMetadata
        )

        #expect(prompt.count <= FlightSummaryBuilder.maxSummaryChars)
        #expect(prompt.count > 0)
    }

    @Test("Single cruise phase produces valid prompt containing [CRUISE] header")
    func singleCruisePhaseContainsCruiseHeader() {
        let flightID = UUID()
        let cruisePhase = PhaseMarkerRecord(
            flightID: flightID,
            phase: "cruise",
            startTimestamp: baseDate,
            endTimestamp: baseDate.addingTimeInterval(600),
            latitude: 37.5,
            longitude: -122.0
        )

        let trackPoints = makeTrackPoints(
            flightID: flightID,
            phase: cruisePhase,
            altitudeFeet: 8500,
            groundSpeedKnots: 110
        )

        let prompt = FlightSummaryBuilder.buildPrompt(
            trackPoints: trackPoints,
            transcriptSegments: [],
            phaseMarkers: [cruisePhase],
            metadata: testMetadata
        )

        #expect(prompt.contains("[CRUISE]"))
        #expect(prompt.contains("Avg Alt:"))
        #expect(prompt.contains("Avg GS:"))
    }

    @Test("Phase summary truncates to perPhaseCharBudget when input exceeds budget")
    func phaseSummaryTruncatedAtBudget() {
        let flightID = UUID()
        let phase = PhaseMarkerRecord(
            flightID: flightID,
            phase: "cruise",
            startTimestamp: baseDate,
            endTimestamp: baseDate.addingTimeInterval(600),
            latitude: 37.5,
            longitude: -122.0
        )

        let trackPoints = makeTrackPoints(flightID: flightID, phase: phase)

        // Create very long transcripts to exceed the budget
        let longText = String(repeating: "Alpha Bravo Charlie Delta Echo Foxtrot Golf Hotel ", count: 30)
        let transcripts = makeTranscripts(
            flightID: flightID,
            phase: "cruise",
            texts: [longText, longText, longText],
            confidences: [0.95, 0.90, 0.85]
        )

        let summary = FlightSummaryBuilder.summarizePhase(
            phase: phase,
            trackPoints: trackPoints,
            transcripts: transcripts
        )

        #expect(summary.count <= FlightSummaryBuilder.perPhaseCharBudget)
        #expect(summary.hasSuffix("..."))
    }

    @Test("Interruption segments excluded from top-3 transcript selection")
    func interruptionSegmentsExcluded() {
        let flightID = UUID()
        let phase = PhaseMarkerRecord(
            flightID: flightID,
            phase: "cruise",
            startTimestamp: baseDate,
            endTimestamp: baseDate.addingTimeInterval(600),
            latitude: 37.5,
            longitude: -122.0
        )

        let trackPoints = makeTrackPoints(flightID: flightID, phase: phase)

        // Interruption has highest confidence but should be excluded
        let transcripts = makeTranscripts(
            flightID: flightID,
            phase: "cruise",
            texts: [
                "[INTERRUPTION: phoneCall]",
                "Traffic 12 o'clock 3 miles",
                "Roger, looking for traffic",
                "Traffic in sight"
            ],
            confidences: [1.0, 0.95, 0.88, 0.82]
        )

        let summary = FlightSummaryBuilder.summarizePhase(
            phase: phase,
            trackPoints: trackPoints,
            transcripts: transcripts
        )

        #expect(!summary.contains("[INTERRUPTION:"))
        #expect(summary.contains("Traffic 12 o'clock 3 miles"))
        #expect(summary.contains("Roger, looking for traffic"))
        #expect(summary.contains("Traffic in sight"))
    }

    @Test("Empty track points and transcripts produces valid prompt without crash")
    func emptyDataProducesValidPrompt() {
        let prompt = FlightSummaryBuilder.buildPrompt(
            trackPoints: [],
            transcriptSegments: [],
            phaseMarkers: [],
            metadata: testMetadata
        )

        #expect(prompt.contains("Analyze this flight"))
        #expect(prompt.contains("Flight:"))
        #expect(prompt.count > 0)
    }
}
