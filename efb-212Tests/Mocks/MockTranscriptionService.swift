//
//  MockTranscriptionService.swift
//  efb-212Tests
//
//  Mock transcription service for testing RecordingCoordinator without Speech framework.
//  Tracks call counts and supports configurable behavior.
//

import Foundation
@testable import efb_212

final class MockTranscriptionService: TranscriptionServiceProtocol, @unchecked Sendable {

    // MARK: - Call Tracking

    var startTranscriptionCalled = false
    var stopTranscriptionCalled = false

    var startTranscriptionCallCount = 0
    var stopTranscriptionCallCount = 0

    // MARK: - Configurable State

    var _isTranscribing = false

    /// If set, startTranscription will throw this error.
    var startTranscriptionError: Error?

    // MARK: - TranscriptionServiceProtocol

    func startTranscription(flightID: UUID) async throws {
        startTranscriptionCalled = true
        startTranscriptionCallCount += 1
        if let error = startTranscriptionError {
            throw error
        }
        _isTranscribing = true
    }

    func stopTranscription() async {
        stopTranscriptionCalled = true
        stopTranscriptionCallCount += 1
        _isTranscribing = false
    }

    var isTranscribing: Bool { _isTranscribing }
}
