//
//  RecordingCoordinatorTests.swift
//  efb-212Tests
//
//  Unit tests for RecordingCoordinator lifecycle using mock audio/transcription.
//  Uses temporary GRDB RecordingDatabase for isolation.
//

import Testing
import Foundation
import GRDB
@testable import efb_212

@Suite("RecordingCoordinator Tests", .serialized)
struct RecordingCoordinatorTests {

    // MARK: - Helpers

    /// Create a temporary RecordingDatabase for testing.
    static func makeTempDB() throws -> RecordingDatabase {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("recording-test-\(UUID().uuidString).sqlite").path
        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA journal_mode = WAL")
        }
        let pool = try DatabasePool(path: dbPath, configuration: config)
        return try RecordingDatabase(dbPool: pool)
    }

    // MARK: - Start/Stop Lifecycle

    @Test func startRecordingTransitionsToRecording() async throws {
        let db = try Self.makeTempDB()
        let mockAudio = MockAudioRecorder()
        let mockTranscription = MockTranscriptionService()
        let coordinator = RecordingCoordinator(
            recordingDB: db,
            audioRecorder: mockAudio,
            transcriptionService: mockTranscription
        )

        _ = try await coordinator.startRecording()

        let status = await coordinator.state.recordingStatus
        #expect(status == .recording)
    }

    @Test func stopRecordingReturnsToIdle() async throws {
        let db = try Self.makeTempDB()
        let mockAudio = MockAudioRecorder()
        let mockTranscription = MockTranscriptionService()
        let coordinator = RecordingCoordinator(
            recordingDB: db,
            audioRecorder: mockAudio,
            transcriptionService: mockTranscription
        )

        _ = try await coordinator.startRecording()
        let summary = await coordinator.stopRecording()

        let status = await coordinator.state.recordingStatus
        #expect(status == .idle)
        #expect(summary != nil)
        #expect(summary?.flightID != nil)
    }

    @Test func startCallsAudioAndTranscription() async throws {
        let db = try Self.makeTempDB()
        let mockAudio = MockAudioRecorder()
        let mockTranscription = MockTranscriptionService()
        let coordinator = RecordingCoordinator(
            recordingDB: db,
            audioRecorder: mockAudio,
            transcriptionService: mockTranscription
        )

        _ = try await coordinator.startRecording()

        #expect(mockAudio.startRecordingCalled == true)
        #expect(mockTranscription.startTranscriptionCalled == true)
    }

    @Test func stopCallsAudioAndTranscription() async throws {
        let db = try Self.makeTempDB()
        let mockAudio = MockAudioRecorder()
        let mockTranscription = MockTranscriptionService()
        let coordinator = RecordingCoordinator(
            recordingDB: db,
            audioRecorder: mockAudio,
            transcriptionService: mockTranscription
        )

        _ = try await coordinator.startRecording()
        _ = await coordinator.stopRecording()

        #expect(mockAudio.stopRecordingCalled == true)
        #expect(mockTranscription.stopTranscriptionCalled == true)
    }

    @Test func stopRecordingWhenIdleReturnsNil() async throws {
        let db = try Self.makeTempDB()
        let coordinator = RecordingCoordinator(recordingDB: db)

        let summary = await coordinator.stopRecording()
        #expect(summary == nil)
    }

    @Test func startRecordingReturnsFlightID() async throws {
        let db = try Self.makeTempDB()
        let coordinator = RecordingCoordinator(recordingDB: db)

        let flightID = try await coordinator.startRecording()
        #expect(flightID != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))

        // Cleanup
        _ = await coordinator.stopRecording()
    }
}
