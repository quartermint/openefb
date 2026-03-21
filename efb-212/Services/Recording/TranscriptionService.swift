//
//  TranscriptionService.swift
//  efb-212
//
//  Real-time speech transcription using SpeechAnalyzer (iOS 26) as primary
//  engine with SFSpeechRecognizer on-device fallback.
//  Only isFinal transcript segments are stored to GRDB.
//  Volatile results are displayed in UI via callback.
//
//  Design source: SFR CockpitTranscriptionEngine (680 lines), adapted for iOS 26.
//

import Foundation
import AVFoundation
import Speech
import os

// MARK: - Audio Buffer Input

struct AudioBufferInput: Sendable {
    let buffer: AVAudioPCMBuffer
    let time: AVAudioTime
}

// MARK: - Transcription Service

actor TranscriptionService: TranscriptionServiceProtocol {

    private let recordingDB: RecordingDatabase
    private let vocabularyProcessor = AviationVocabularyProcessor()
    private var _isTranscribing = false
    private var flightID: UUID?
    private var transcriptionTask: Task<Void, Never>?

    /// Callback for UI updates (volatile + final segments).
    var onTranscriptUpdate: (@Sendable (TranscriptDisplayItem) -> Void)?

    /// Provider for current flight phase (set by coordinator).
    var currentPhaseProvider: (@Sendable () async -> FlightPhaseType)?

    private let logger = Logger(subsystem: "quartermint.efb-212", category: "TranscriptionService")

    // MARK: - Init

    init(recordingDB: RecordingDatabase) {
        self.recordingDB = recordingDB
    }

    // MARK: - TranscriptionServiceProtocol

    var isTranscribing: Bool {
        _isTranscribing
    }

    func startTranscription(flightID: UUID) async throws {
        self.flightID = flightID
        _isTranscribing = true
        // TDD RED stub -- actual implementation in GREEN phase
        logger.info("Transcription started for flight \(flightID.uuidString)")
    }

    func stopTranscription() async {
        transcriptionTask?.cancel()
        transcriptionTask = nil
        _isTranscribing = false
        flightID = nil
        logger.info("Transcription stopped")
    }

    // MARK: - Buffer Feed

    /// Feed audio buffer from AudioRecorder for real-time transcription.
    func feedBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        // TDD RED stub -- will stream to SpeechAnalyzer/SFSpeechRecognizer in GREEN
    }
}
