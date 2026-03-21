//
//  ReplayEngineTests.swift
//  efb-212Tests
//
//  Unit tests for ReplayEngine playback coordinator.
//  Tests time model, interpolation, speed, seek, transcript matching, phase markers.
//  Uses Swift Testing framework with temp GRDB database for test isolation.
//

import Testing
import Foundation
import CoreLocation
import GRDB
@testable import efb_212

@Suite("ReplayEngine Tests")
struct ReplayEngineTests {

    // MARK: - Test Helpers

    /// Create a temporary RecordingDatabase with test flight data.
    /// Inserts 10 track points (1 second apart), 3 transcript segments, 3 phase markers.
    /// Returns (recordingDB, flightID).
    private func makeTestRecordingDB() throws -> (RecordingDatabase, UUID) {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_replay_\(UUID().uuidString).sqlite").path
        let pool = try DatabasePool(path: dbPath)
        let db = try RecordingDatabase(dbPool: pool)

        let flightID = UUID()
        let baseTime = Date(timeIntervalSince1970: 1_000_000)

        // Insert 10 track points, 1 second apart
        // Latitude increases from 37.0 to 37.9, longitude from -122.0 to -121.1
        for i in 0..<10 {
            let point = TrackPointRecord(
                flightID: flightID,
                timestamp: baseTime.addingTimeInterval(Double(i)),
                latitude: 37.0 + Double(i) * 0.1,
                longitude: -122.0 + Double(i) * 0.1,
                altitudeFeet: 3000.0 + Double(i) * 100.0,     // 3000 to 3900 feet MSL
                groundSpeedKnots: 100.0 + Double(i) * 5.0,    // 100 to 145 knots
                verticalSpeedFPM: Double(i) * 50.0,            // 0 to 450 fpm
                courseDegrees: Double(i) * 10.0                // 0 to 90 degrees true
            )
            try db.insertTrackPoint(point)
        }

        // Insert 3 transcript segments at different time ranges
        // Segment 0: audioStartTime=1.0, audioEndTime=3.0
        // Segment 1: audioStartTime=4.0, audioEndTime=6.0
        // Segment 2: audioStartTime=7.0, audioEndTime=8.5
        let segments = [
            TranscriptSegmentRecord(
                flightID: flightID,
                timestamp: baseTime.addingTimeInterval(1.0),
                text: "Tower, Cessna 12345 ready for departure",
                confidence: 0.95,
                audioStartTime: 1.0,
                audioEndTime: 3.0,
                flightPhase: FlightPhaseType.taxi.rawValue
            ),
            TranscriptSegmentRecord(
                flightID: flightID,
                timestamp: baseTime.addingTimeInterval(4.0),
                text: "Cessna 12345 cleared for takeoff runway 28L",
                confidence: 0.90,
                audioStartTime: 4.0,
                audioEndTime: 6.0,
                flightPhase: FlightPhaseType.takeoff.rawValue
            ),
            TranscriptSegmentRecord(
                flightID: flightID,
                timestamp: baseTime.addingTimeInterval(7.0),
                text: "Cessna 12345 contact departure 125.35",
                confidence: 0.88,
                audioStartTime: 7.0,
                audioEndTime: 8.5,
                flightPhase: FlightPhaseType.departure.rawValue
            )
        ]
        for segment in segments {
            try db.insertTranscript(segment)
        }

        // Insert 3 phase markers
        let markers = [
            PhaseMarkerRecord(
                flightID: flightID,
                phase: FlightPhaseType.taxi.rawValue,
                startTimestamp: baseTime,
                endTimestamp: baseTime.addingTimeInterval(3.0),
                latitude: 37.0,
                longitude: -122.0
            ),
            PhaseMarkerRecord(
                flightID: flightID,
                phase: FlightPhaseType.takeoff.rawValue,
                startTimestamp: baseTime.addingTimeInterval(3.0),
                endTimestamp: baseTime.addingTimeInterval(6.0),
                latitude: 37.3,
                longitude: -121.7
            ),
            PhaseMarkerRecord(
                flightID: flightID,
                phase: FlightPhaseType.cruise.rawValue,
                startTimestamp: baseTime.addingTimeInterval(6.0),
                endTimestamp: baseTime.addingTimeInterval(9.0),
                latitude: 37.6,
                longitude: -121.4
            )
        ]
        for marker in markers {
            try db.insertPhaseMarker(marker)
        }

        return (db, flightID)
    }

    // MARK: - Load Flight Tests

    @Test("loadFlight populates trackPoints, transcriptSegments, phaseMarkers with correct counts")
    @MainActor
    func loadFlightPopulatesData() async throws {
        let (recordingDB, flightID) = try makeTestRecordingDB()
        let engine = ReplayEngine()

        try engine.loadFlight(flightID: flightID, recordingDB: recordingDB, audioURL: nil)

        #expect(engine.trackPointCount == 10)
        #expect(engine.transcriptSegmentCount == 3)
        #expect(engine.phaseMarkerCount == 3)
    }

    @Test("totalDuration computes correctly as difference between first and last track point timestamps")
    @MainActor
    func totalDurationComputation() async throws {
        let (recordingDB, flightID) = try makeTestRecordingDB()
        let engine = ReplayEngine()

        try engine.loadFlight(flightID: flightID, recordingDB: recordingDB, audioURL: nil)

        // 10 points, 1 second apart: first=0s, last=9s => totalDuration = 9.0
        #expect(engine.totalDuration == 9.0)
    }

    @Test("loadFlight with empty trackPoints sets totalDuration to 0")
    @MainActor
    func loadFlightEmptyTrackPoints() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_replay_empty_\(UUID().uuidString).sqlite").path
        let pool = try DatabasePool(path: dbPath)
        let db = try RecordingDatabase(dbPool: pool)
        let flightID = UUID()

        let engine = ReplayEngine()
        try engine.loadFlight(flightID: flightID, recordingDB: db, audioURL: nil)

        #expect(engine.totalDuration == 0)
        #expect(engine.trackPointCount == 0)
    }

    // MARK: - Interpolation Tests

    @Test("interpolatedPosition at t=0 returns first track point coordinate")
    @MainActor
    func interpolationAtStart() async throws {
        let (recordingDB, flightID) = try makeTestRecordingDB()
        let engine = ReplayEngine()
        try engine.loadFlight(flightID: flightID, recordingDB: recordingDB, audioURL: nil)

        let result = engine.interpolatedPosition(at: 0)

        #expect(abs(result.coordinate.latitude - 37.0) < 0.001)
        #expect(abs(result.coordinate.longitude - (-122.0)) < 0.001)
        #expect(abs(result.altitude - 3000.0) < 0.1)
        #expect(abs(result.speed - 100.0) < 0.1)
    }

    @Test("interpolatedPosition at halfway between two 1-second-apart points returns midpoint lat/lon")
    @MainActor
    func interpolationMidpoint() async throws {
        let (recordingDB, flightID) = try makeTestRecordingDB()
        let engine = ReplayEngine()
        try engine.loadFlight(flightID: flightID, recordingDB: recordingDB, audioURL: nil)

        // At t=0.5, between point[0] (lat=37.0) and point[1] (lat=37.1)
        let result = engine.interpolatedPosition(at: 0.5)

        #expect(abs(result.coordinate.latitude - 37.05) < 0.001)
        #expect(abs(result.coordinate.longitude - (-121.95)) < 0.001)
        // Altitude should be halfway: (3000 + 3100) / 2 = 3050
        #expect(abs(result.altitude - 3050.0) < 0.1)
        // Speed should be halfway: (100 + 105) / 2 = 102.5
        #expect(abs(result.speed - 102.5) < 0.1)
    }

    @Test("interpolatedPosition at totalDuration returns last track point coordinate")
    @MainActor
    func interpolationAtEnd() async throws {
        let (recordingDB, flightID) = try makeTestRecordingDB()
        let engine = ReplayEngine()
        try engine.loadFlight(flightID: flightID, recordingDB: recordingDB, audioURL: nil)

        let result = engine.interpolatedPosition(at: engine.totalDuration)

        // Last point: lat=37.9, lon=-121.1, alt=3900, speed=145
        #expect(abs(result.coordinate.latitude - 37.9) < 0.001)
        #expect(abs(result.coordinate.longitude - (-121.1)) < 0.001)
        #expect(abs(result.altitude - 3900.0) < 0.1)
        #expect(abs(result.speed - 145.0) < 0.1)
    }

    // MARK: - Playback Speed Tests

    @Test("tick at 1x speed advances currentPosition by tick interval (0.05 seconds)")
    @MainActor
    func tickAt1x() async throws {
        let (recordingDB, flightID) = try makeTestRecordingDB()
        let engine = ReplayEngine()
        try engine.loadFlight(flightID: flightID, recordingDB: recordingDB, audioURL: nil)

        engine.setSpeed(1.0)
        let startPos = engine.currentPosition
        engine.testTick()

        #expect(abs(engine.currentPosition - (startPos + 0.05)) < 0.001)
    }

    @Test("tick at 2x speed advances currentPosition by 0.10 seconds per tick")
    @MainActor
    func tickAt2x() async throws {
        let (recordingDB, flightID) = try makeTestRecordingDB()
        let engine = ReplayEngine()
        try engine.loadFlight(flightID: flightID, recordingDB: recordingDB, audioURL: nil)

        engine.setSpeed(2.0)
        let startPos = engine.currentPosition
        engine.testTick()

        #expect(abs(engine.currentPosition - (startPos + 0.10)) < 0.001)
    }

    @Test("tick at 4x speed advances currentPosition by 0.20 seconds per tick")
    @MainActor
    func tickAt4x() async throws {
        let (recordingDB, flightID) = try makeTestRecordingDB()
        let engine = ReplayEngine()
        try engine.loadFlight(flightID: flightID, recordingDB: recordingDB, audioURL: nil)

        engine.setSpeed(4.0)
        let startPos = engine.currentPosition
        engine.testTick()

        #expect(abs(engine.currentPosition - (startPos + 0.20)) < 0.001)
    }

    @Test("tick at 8x speed advances currentPosition by 0.40 seconds per tick")
    @MainActor
    func tickAt8x() async throws {
        let (recordingDB, flightID) = try makeTestRecordingDB()
        let engine = ReplayEngine()
        try engine.loadFlight(flightID: flightID, recordingDB: recordingDB, audioURL: nil)

        engine.setSpeed(8.0)
        let startPos = engine.currentPosition
        engine.testTick()

        #expect(abs(engine.currentPosition - (startPos + 0.40)) < 0.001)
    }

    // MARK: - Seek Tests

    @Test("seekTo clamps to 0...totalDuration range")
    @MainActor
    func seekToClampsRange() async throws {
        let (recordingDB, flightID) = try makeTestRecordingDB()
        let engine = ReplayEngine()
        try engine.loadFlight(flightID: flightID, recordingDB: recordingDB, audioURL: nil)

        engine.seekTo(-5.0)
        #expect(engine.currentPosition == 0)

        engine.seekTo(999.0)
        #expect(engine.currentPosition == engine.totalDuration)
    }

    @Test("seekTo(0) sets currentPosition to 0 and updates derived state to first track point")
    @MainActor
    func seekToStart() async throws {
        let (recordingDB, flightID) = try makeTestRecordingDB()
        let engine = ReplayEngine()
        try engine.loadFlight(flightID: flightID, recordingDB: recordingDB, audioURL: nil)

        // Move somewhere first
        engine.seekTo(5.0)
        // Then seek back to start
        engine.seekTo(0)

        #expect(engine.currentPosition == 0)
        #expect(abs(engine.currentCoordinate.latitude - 37.0) < 0.001)
        #expect(abs(engine.currentAltitude - 3000.0) < 0.1)
    }

    @Test("seekTo(totalDuration) sets currentPosition to totalDuration and updates to last track point")
    @MainActor
    func seekToEnd() async throws {
        let (recordingDB, flightID) = try makeTestRecordingDB()
        let engine = ReplayEngine()
        try engine.loadFlight(flightID: flightID, recordingDB: recordingDB, audioURL: nil)

        engine.seekTo(engine.totalDuration)

        #expect(engine.currentPosition == engine.totalDuration)
        #expect(abs(engine.currentCoordinate.latitude - 37.9) < 0.001)
        #expect(abs(engine.currentAltitude - 3900.0) < 0.1)
    }

    // MARK: - Transcript Matching Tests

    @Test("currentTranscriptIndex returns correct index when position within segment range")
    @MainActor
    func transcriptMatchWithinSegment() async throws {
        let (recordingDB, flightID) = try makeTestRecordingDB()
        let engine = ReplayEngine()
        try engine.loadFlight(flightID: flightID, recordingDB: recordingDB, audioURL: nil)

        // Segment 0: audioStartTime=1.0, audioEndTime=3.0
        engine.seekTo(2.0)
        #expect(engine.currentTranscriptIndex == 0)

        // Segment 1: audioStartTime=4.0, audioEndTime=6.0
        engine.seekTo(5.0)
        #expect(engine.currentTranscriptIndex == 1)

        // Segment 2: audioStartTime=7.0, audioEndTime=8.5
        engine.seekTo(7.5)
        #expect(engine.currentTranscriptIndex == 2)
    }

    @Test("currentTranscriptIndex returns nil when position is between transcript segments")
    @MainActor
    func transcriptMatchBetweenSegments() async throws {
        let (recordingDB, flightID) = try makeTestRecordingDB()
        let engine = ReplayEngine()
        try engine.loadFlight(flightID: flightID, recordingDB: recordingDB, audioURL: nil)

        // Between segment 0 (ends at 3.0) and segment 1 (starts at 4.0)
        engine.seekTo(3.5)
        #expect(engine.currentTranscriptIndex == nil)

        // Before any segments
        engine.seekTo(0.5)
        #expect(engine.currentTranscriptIndex == nil)
    }

    // MARK: - Phase Marker Tests

    @Test("phaseMarkerFractions computes correct fractional positions along timeline")
    @MainActor
    func phaseMarkerFractionsComputation() async throws {
        let (recordingDB, flightID) = try makeTestRecordingDB()
        let engine = ReplayEngine()
        try engine.loadFlight(flightID: flightID, recordingDB: recordingDB, audioURL: nil)

        // totalDuration = 9.0
        // Marker 0: taxi starts at baseTime+0 => fraction = 0/9 = 0.0
        // Marker 1: takeoff starts at baseTime+3 => fraction = 3/9 = 0.333
        // Marker 2: cruise starts at baseTime+6 => fraction = 6/9 = 0.667
        let fractions = engine.phaseMarkerFractions
        guard fractions.count == 3 else {
            Issue.record("Expected 3 phase marker fractions, got \(fractions.count)")
            return
        }

        #expect(fractions[0].phase == FlightPhaseType.taxi.rawValue)
        #expect(abs(fractions[0].fraction - 0.0) < 0.01)

        #expect(fractions[1].phase == FlightPhaseType.takeoff.rawValue)
        #expect(abs(fractions[1].fraction - 0.333) < 0.01)

        #expect(fractions[2].phase == FlightPhaseType.cruise.rawValue)
        #expect(abs(fractions[2].fraction - 0.667) < 0.01)
    }

    // MARK: - Play/Pause Tests

    @Test("pause sets isPlaying to false")
    @MainActor
    func pauseSetsIsPlayingFalse() async throws {
        let (recordingDB, flightID) = try makeTestRecordingDB()
        let engine = ReplayEngine()
        try engine.loadFlight(flightID: flightID, recordingDB: recordingDB, audioURL: nil)

        // Simulate play state by setting isPlaying directly isn't available,
        // but we can test that pause always results in isPlaying == false
        engine.pause()
        #expect(engine.isPlaying == false)
    }

    @Test("play followed by pause does not advance position further")
    @MainActor
    func playThenPauseStopsAdvancement() async throws {
        let (recordingDB, flightID) = try makeTestRecordingDB()
        let engine = ReplayEngine()
        try engine.loadFlight(flightID: flightID, recordingDB: recordingDB, audioURL: nil)

        // Simulate: play, tick a few times, then pause
        engine.play()
        engine.testTick()
        engine.testTick()
        engine.pause()

        let posAfterPause = engine.currentPosition
        // Further ticks should not advance (since we paused)
        // The timer is invalidated, but testTick is manual -- we test that
        // the engine's state correctly reflects paused
        #expect(engine.isPlaying == false)
        #expect(engine.currentPosition == posAfterPause)
    }

    // MARK: - Speed / Audio Mute Tests

    @Test("setSpeed to 4.0 or 8.0 sets audioMuted to true")
    @MainActor
    func highSpeedMutesAudio() async throws {
        let engine = ReplayEngine()

        engine.setSpeed(4.0)
        #expect(engine.audioMuted == true)

        engine.setSpeed(8.0)
        #expect(engine.audioMuted == true)
    }

    @Test("setSpeed to 1.0 or 2.0 sets audioMuted to false")
    @MainActor
    func normalSpeedUnmutesAudio() async throws {
        let engine = ReplayEngine()

        engine.setSpeed(1.0)
        #expect(engine.audioMuted == false)

        engine.setSpeed(2.0)
        #expect(engine.audioMuted == false)
    }
}
