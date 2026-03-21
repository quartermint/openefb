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
final class MockRecordingDatabase: @unchecked Sendable {
    var mockTrackPoints: [TrackPointRecord] = []
    var mockTranscripts: [TranscriptSegmentRecord] = []
    var mockPhaseMarkers: [PhaseMarkerRecord] = []

    func trackPoints(forFlight flightID: UUID) -> [TrackPointRecord] { mockTrackPoints }
    func transcriptSegments(forFlight flightID: UUID) -> [TranscriptSegmentRecord] { mockTranscripts }
    func phaseMarkers(forFlight flightID: UUID) -> [PhaseMarkerRecord] { mockPhaseMarkers }
}
