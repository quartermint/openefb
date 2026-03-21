//
//  MockRecordingDatabase.swift
//  efb-212Tests
//
//  Mock that provides canned flight data without requiring a real GRDB database.
//  Used by FlightSummaryBuilder tests for deterministic data compression verification.
//

import Foundation
@testable import efb_212

/// Mock recording database for FlightSummaryBuilder tests.
/// Stores canned data in arrays for test injection.
final class MockRecordingDatabase: @unchecked Sendable {
    var mockTrackPoints: [TrackPointRecord] = []
    var mockTranscripts: [TranscriptSegmentRecord] = []
    var mockPhaseMarkers: [PhaseMarkerRecord] = []
    var mockDebriefRecords: [UUID: DebriefRecord] = [:]

    func trackPoints(forFlight flightID: UUID) -> [TrackPointRecord] {
        mockTrackPoints.filter { $0.flightID == flightID }
    }

    func transcriptSegments(forFlight flightID: UUID) -> [TranscriptSegmentRecord] {
        mockTranscripts.filter { $0.flightID == flightID }
    }

    func phaseMarkers(forFlight flightID: UUID) -> [PhaseMarkerRecord] {
        mockPhaseMarkers.filter { $0.flightID == flightID }
    }

    func insertDebrief(_ record: DebriefRecord) {
        mockDebriefRecords[record.flightID] = record
    }

    func debrief(forFlight flightID: UUID) -> DebriefRecord? {
        mockDebriefRecords[flightID]
    }

    func deleteDebrief(forFlight flightID: UUID) {
        mockDebriefRecords.removeValue(forKey: flightID)
    }
}
