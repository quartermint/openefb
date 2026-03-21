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

/// Audio buffer wrapper for streaming from AudioRecorder to TranscriptionService.
struct AudioBufferInput: Sendable {
    let buffer: AVAudioPCMBuffer
    let time: AVAudioTime
}

// MARK: - Transcription Engine Selection

/// Which speech recognition engine is active.
enum TranscriptionEngine: Sendable {
    case speechAnalyzer   // iOS 26 SpeechAnalyzer (primary)
    case sfSpeechRecognizer  // Fallback
}

// MARK: - Transcription Service

actor TranscriptionService: TranscriptionServiceProtocol {

    private let recordingDB: RecordingDatabase
    private let vocabularyProcessor = AviationVocabularyProcessor()
    private var _isTranscribing = false
    private var flightID: UUID?
    private var transcriptionTask: Task<Void, Never>?
    private var activeEngine: TranscriptionEngine?

    // Buffer streaming via AsyncStream
    private var bufferContinuation: AsyncStream<AudioBufferInput>.Continuation?

    // SFSpeechRecognizer fallback components
    private var sfRecognizer: SFSpeechRecognizer?
    private var sfRecognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var sfRecognitionTask: SFSpeechRecognitionTask?

    /// Callback for UI updates (volatile + final segments).
    var onTranscriptUpdate: (@Sendable (TranscriptDisplayItem) -> Void)?

    /// Provider for current flight phase (set by coordinator).
    var currentPhaseProvider: (@Sendable () async -> FlightPhaseType)?

    /// Aviation contextual strings for SFSpeechRecognizer to improve accuracy.
    private let aviationContextualStrings = [
        "november", "niner", "squawk", "atis", "metar", "pirep",
        "runway", "taxiway", "cleared", "roger", "wilco", "unable",
        "approach", "departure", "tower", "ground", "center", "unicom",
        "altitude", "heading", "flight level", "maintain", "descend", "climb",
    ]

    private let logger = Logger(subsystem: "quartermint.efb-212", category: "TranscriptionService")

    // MARK: - Init

    init(recordingDB: RecordingDatabase) {
        self.recordingDB = recordingDB
    }

    // MARK: - TranscriptionServiceProtocol

    var isTranscribing: Bool {
        _isTranscribing
    }

    /// Start real-time transcription for a flight.
    /// Checks SpeechAnalyzer availability first, falls back to SFSpeechRecognizer.
    func startTranscription(flightID: UUID) async throws {
        self.flightID = flightID

        // Try SpeechAnalyzer first (iOS 26+)
        let locale = Locale(identifier: "en-US")

        if await checkSpeechAnalyzerAvailability(locale: locale) {
            try await startSpeechAnalyzerTranscription(locale: locale)
            activeEngine = .speechAnalyzer
        } else {
            // Fallback to SFSpeechRecognizer with on-device recognition
            try startSFSpeechRecognizerTranscription(locale: locale)
            activeEngine = .sfSpeechRecognizer
        }

        _isTranscribing = true
        logger.info("Transcription started for flight \(flightID.uuidString) using \(String(describing: self.activeEngine))")
    }

    /// Stop transcription and clean up all resources.
    func stopTranscription() async {
        transcriptionTask?.cancel()
        transcriptionTask = nil
        bufferContinuation?.finish()
        bufferContinuation = nil

        // Clean up SFSpeechRecognizer resources
        sfRecognitionTask?.cancel()
        sfRecognitionTask = nil
        sfRecognitionRequest?.endAudio()
        sfRecognitionRequest = nil
        sfRecognizer = nil

        _isTranscribing = false
        flightID = nil
        activeEngine = nil
        logger.info("Transcription stopped")
    }

    // MARK: - Buffer Feed

    /// Feed audio buffer from AudioRecorder for real-time transcription.
    /// Routes to the active transcription engine.
    func feedBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        guard _isTranscribing else { return }

        switch activeEngine {
        case .speechAnalyzer:
            // Stream to SpeechAnalyzer via AsyncStream
            bufferContinuation?.yield(AudioBufferInput(buffer: buffer, time: time))

        case .sfSpeechRecognizer:
            // Append to SFSpeechAudioBufferRecognitionRequest
            sfRecognitionRequest?.append(buffer)

        case .none:
            break
        }
    }

    // MARK: - SpeechAnalyzer (iOS 26)

    /// Check if SpeechAnalyzer is available for the given locale.
    private func checkSpeechAnalyzerAvailability(locale: Locale) async -> Bool {
        // SpeechTranscriber.installedLocales contains locales with downloaded models
        if #available(iOS 26.0, *) {
            let installedLocales = await SpeechTranscriber.installedLocales
            return installedLocales.contains(locale)
        }
        return false
    }

    /// Start transcription using SpeechAnalyzer (iOS 26+).
    /// Uses SpeechAnalyzer.process(input:) with an AsyncStream of AnalyzerInput buffers.
    @available(iOS 26.0, *)
    private func startSpeechAnalyzerTranscription(locale: Locale) async throws {
        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: [.audioTimeRange]
        )

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [transcriber]
        )

        // Create buffer stream for feeding audio from AudioRecorder
        let (bufferStream, bufferContinuation) = AsyncStream<AudioBufferInput>.makeStream()
        self.bufferContinuation = bufferContinuation

        // Map AudioBufferInput stream to AnalyzerInput stream
        let inputStream = bufferStream.map { bufferInput -> AnalyzerInput in
            AnalyzerInput(buffer: bufferInput.buffer)
        }

        let recordingDB = self.recordingDB
        let vocabularyProcessor = self.vocabularyProcessor
        let onTranscriptUpdate = self.onTranscriptUpdate
        let currentPhaseProvider = self.currentPhaseProvider
        let flightID = self.flightID!
        let logger = self.logger

        transcriptionTask = Task {
            // Process transcription results in a child task
            let resultsTask = Task {
                do {
                    for try await result in transcriber.results {
                        guard !Task.isCancelled else { break }
                        let text = String(result.text.characters)
                        let processed = vocabularyProcessor.process(text)

                        if result.isFinal {
                            // Get current flight phase
                            let phase = await currentPhaseProvider?() ?? .cruise

                            // Create and store segment to GRDB
                            let segment = TranscriptSegmentRecord(
                                flightID: flightID,
                                text: processed,
                                confidence: 0.9,
                                audioStartTime: 0,
                                audioEndTime: 0,
                                flightPhase: phase.rawValue
                            )

                            do {
                                try recordingDB.insertTranscript(segment)
                            } catch {
                                logger.error("Failed to store transcript: \(error.localizedDescription)")
                            }

                            // Notify UI with final segment
                            let displayItem = TranscriptDisplayItem(
                                id: UUID(),
                                text: processed,
                                timestamp: Date(),
                                isVolatile: false
                            )
                            onTranscriptUpdate?(displayItem)
                        } else {
                            // Volatile result -- UI only, not stored
                            let displayItem = TranscriptDisplayItem(
                                id: UUID(),
                                text: processed,
                                timestamp: Date(),
                                isVolatile: true
                            )
                            onTranscriptUpdate?(displayItem)
                        }
                    }
                } catch {
                    if !Task.isCancelled {
                        logger.error("SpeechAnalyzer results error: \(error.localizedDescription)")
                    }
                }
            }

            // Feed audio to analyzer using analyzeSequence(_:)
            do {
                try await analyzer.analyzeSequence(inputStream)
            } catch {
                if !Task.isCancelled {
                    logger.error("SpeechAnalyzer analyze error: \(error.localizedDescription)")
                }
            }

            resultsTask.cancel()
        }
    }

    // MARK: - SFSpeechRecognizer Fallback

    /// Start transcription using SFSpeechRecognizer with on-device recognition.
    private func startSFSpeechRecognizerTranscription(locale: Locale) throws {
        guard let recognizer = SFSpeechRecognizer(locale: locale),
              recognizer.isAvailable else {
            throw EFBError.transcriptionUnavailable
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true  // No time limit
        request.contextualStrings = aviationContextualStrings
        request.addsPunctuation = true

        self.sfRecognizer = recognizer
        self.sfRecognitionRequest = request

        let recordingDB = self.recordingDB
        let vocabularyProcessor = self.vocabularyProcessor
        let onTranscriptUpdate = self.onTranscriptUpdate
        let currentPhaseProvider = self.currentPhaseProvider
        let flightID = self.flightID!
        let logger = self.logger

        sfRecognitionTask = recognizer.recognitionTask(with: request) { result, error in
            if let error = error {
                if (error as NSError).code != 1 {  // Code 1 = cancelled, expected on stop
                    logger.error("SFSpeechRecognizer error: \(error.localizedDescription)")
                }
                return
            }

            guard let result = result else { return }

            let text = result.bestTranscription.formattedString
            let processed = vocabularyProcessor.process(text)

            if result.isFinal {
                // Get confidence from best transcription segments
                let confidence = result.bestTranscription.segments.last?.confidence ?? 0.0

                let segment = TranscriptSegmentRecord(
                    flightID: flightID,
                    text: processed,
                    confidence: Double(confidence),
                    audioStartTime: result.bestTranscription.segments.first?.timestamp ?? 0,
                    audioEndTime: result.bestTranscription.segments.last.map {
                        $0.timestamp + $0.duration
                    } ?? 0,
                    flightPhase: "cruise"  // Will be updated by phase provider
                )

                do {
                    try recordingDB.insertTranscript(segment)
                } catch {
                    logger.error("Failed to store transcript: \(error.localizedDescription)")
                }

                // Notify UI with final segment
                let displayItem = TranscriptDisplayItem(
                    id: UUID(),
                    text: processed,
                    timestamp: Date(),
                    isVolatile: false
                )
                onTranscriptUpdate?(displayItem)
            } else {
                // Volatile result -- UI only
                let displayItem = TranscriptDisplayItem(
                    id: UUID(),
                    text: processed,
                    timestamp: Date(),
                    isVolatile: true
                )
                onTranscriptUpdate?(displayItem)
            }
        }
    }
}
