//
//  MockAudioRecorder.swift
//  efb-212Tests
//
//  Mock audio recorder for testing RecordingCoordinator without real AVAudioEngine.
//  Tracks call counts and supports configurable behavior.
//

import Foundation
@testable import efb_212

final class MockAudioRecorder: AudioRecorderProtocol, @unchecked Sendable {

    // MARK: - Call Tracking

    var startRecordingCalled = false
    var stopRecordingCalled = false
    var pauseRecordingCalled = false
    var resumeRecordingCalled = false

    var startRecordingCallCount = 0
    var stopRecordingCallCount = 0

    // MARK: - Configurable State

    var _isRecording = false
    var _audioLevel: Float = -160  // dBFS silence floor

    /// If set, startRecording will throw this error.
    var startRecordingError: Error?

    /// URL to return from stopRecording.
    var stopRecordingURL: URL? = URL(fileURLWithPath: "/tmp/test.m4a")

    // MARK: - AudioRecorderProtocol

    func startRecording(flightID: UUID, profile: AudioQualityProfile, outputURL: URL) async throws {
        startRecordingCalled = true
        startRecordingCallCount += 1
        if let error = startRecordingError {
            throw error
        }
        _isRecording = true
    }

    func stopRecording() async -> URL? {
        stopRecordingCalled = true
        stopRecordingCallCount += 1
        _isRecording = false
        return stopRecordingURL
    }

    func pauseRecording() async {
        pauseRecordingCalled = true
    }

    func resumeRecording() async throws {
        resumeRecordingCalled = true
    }

    var isRecording: Bool { _isRecording }
    var audioLevel: Float { _audioLevel }
}
