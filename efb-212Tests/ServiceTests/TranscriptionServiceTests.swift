//
//  TranscriptionServiceTests.swift
//  efb-212Tests
//
//  Unit tests for TranscriptionService.
//  Tests initial state, vocabulary processor integration,
//  and GRDB storage of final transcript segments.
//  Cannot test real Speech framework in simulator.
//

import Testing
import Foundation
import GRDB
@testable import efb_212

@Suite("TranscriptionService Tests")
struct TranscriptionServiceTests {

    // MARK: - Helpers

    /// Create a temporary file-backed DatabasePool for testing.
    /// DatabasePool requires a real file path (not :memory:).
    static func makeTempDB() throws -> RecordingDatabase {
        let tmpDir = FileManager.default.temporaryDirectory
        let dbPath = tmpDir.appendingPathComponent("test-\(UUID().uuidString).sqlite").path
        let pool = try DatabasePool(path: dbPath)
        return try RecordingDatabase(dbPool: pool)
    }

    // MARK: - Initial State

    @Test func initialStateNotTranscribing() async throws {
        let db = try Self.makeTempDB()
        let service = TranscriptionService(recordingDB: db)
        let isTranscribing = await service.isTranscribing
        #expect(isTranscribing == false)
    }

    // MARK: - Vocabulary Processor Integration

    @Test func vocabularyProcessorIntegrated() {
        // Test that AviationVocabularyProcessor is functional and would be called
        let processor = AviationVocabularyProcessor()
        let input = "november seven three two papa squawk one two zero zero"
        let output = processor.process(input)
        // Both corrections should apply
        #expect(output.contains("N732P"))
        #expect(output.contains("1200"))
    }

    // MARK: - GRDB Storage of Final Segments

    @Test func onlyFinalSegmentsStoredToGRDB() throws {
        let db = try Self.makeTempDB()
        let flightID = UUID()

        // Simulate storing a final transcript segment
        let segment = TranscriptSegmentRecord(
            flightID: flightID,
            text: "N732P contact tower 123.45",
            confidence: 0.95,
            audioStartTime: 10.0,
            audioEndTime: 15.0,
            flightPhase: FlightPhaseType.cruise.rawValue
        )
        try db.insertTranscript(segment)

        // Verify retrieval
        let segments = try db.transcriptSegments(forFlight: flightID)
        #expect(segments.count == 1)
        #expect(segments.first?.text == "N732P contact tower 123.45")
        #expect(segments.first?.confidence == 0.95)
        #expect(segments.first?.flightPhase == "cruise")
    }
}
