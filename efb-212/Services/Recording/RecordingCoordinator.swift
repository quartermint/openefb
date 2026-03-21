//
//  RecordingCoordinator.swift
//  efb-212
//
//  Central recording orchestrator actor. Owns TrackRecorder + AudioRecorder + TranscriptionService.
//  Exposes state via @MainActor @Observable State object for SwiftUI binding.
//  Handles auto-start monitoring, countdown, and auto-stop.
//
//  Design source: SFR FlightManager pattern, adapted for iOS 26 + @Observable.
//

import AVFoundation
import Foundation
import os

// MARK: - Flight Recording Summary

/// Summary returned when a recording session ends.
struct FlightRecordingSummary: Sendable {
    let flightID: UUID
    let startDate: Date
    let endDate: Date
    let trackPointCount: Int
    let transcriptSegmentCount: Int
    let departureICAO: String?
    let arrivalICAO: String?
    let phases: [PhaseMarkerRecord]
    let audioFileURL: URL?
}

// MARK: - Recording Coordinator

actor RecordingCoordinator {

    // MARK: - Observable State (MainActor)

    @MainActor @Observable
    final class State: @unchecked Sendable {
        var recordingStatus: RecordingStatus = .idle
        var elapsedTime: TimeInterval = 0
        var currentPhase: FlightPhaseType = .preflight
        var recentTranscripts: [TranscriptDisplayItem] = []
        var audioLevel: Float = -160  // dBFS
        var countdownRemaining: Int = 0

        nonisolated init() {}
    }

    nonisolated let state = State()

    // MARK: - Properties

    private let recordingDB: RecordingDatabase
    private var trackRecorder: TrackRecorder?
    private var audioRecorder: any AudioRecorderProtocol
    private var transcriptionService: any TranscriptionServiceProtocol
    private var timerTask: Task<Void, Never>?
    private var autoStartTask: Task<Void, Never>?
    private var autoStopTask: Task<Void, Never>?
    private var currentFlightID: UUID?
    private var recordingStartDate: Date?
    private var audioOutputURL: URL?

    private let logger = Logger(subsystem: "quartermint.efb-212", category: "RecordingCoordinator")

    // MARK: - Init

    init(
        recordingDB: RecordingDatabase,
        audioRecorder: any AudioRecorderProtocol = PlaceholderAudioRecorder(),
        transcriptionService: any TranscriptionServiceProtocol = PlaceholderTranscriptionService()
    ) {
        self.recordingDB = recordingDB
        self.audioRecorder = audioRecorder
        self.transcriptionService = transcriptionService
    }

    /// Factory: create a production RecordingCoordinator with real AudioRecorder.
    /// Uses real RecordingDatabase, real AudioRecorder, and placeholder TranscriptionService
    /// (TranscriptionService wired in Plan 03).
    static func makeDefault() throws -> RecordingCoordinator {
        let db = try RecordingDatabase()
        let audio = AudioRecorder()
        return RecordingCoordinator(
            recordingDB: db,
            audioRecorder: audio,
            transcriptionService: PlaceholderTranscriptionService()
        )
    }

    // MARK: - Core Lifecycle

    /// Start a new flight recording session.
    /// Returns the flight ID for the new recording.
    func startRecording(profile: AudioQualityProfile = .standard) async throws -> UUID {
        // Guard: don't start if already recording
        let currentStatus = await state.recordingStatus
        guard currentStatus == .idle || currentStatus == .countdown(remaining: 0) else {
            logger.warning("Attempted to start recording while status is not idle")
            if case .recording = currentStatus {
                throw EFBError.recordingFailed(underlying: RecordingError.alreadyRecording)
            }
            throw EFBError.recordingFailed(underlying: RecordingError.invalidState)
        }

        let flightID = UUID()
        currentFlightID = flightID
        recordingStartDate = Date()

        // Update state to recording
        await MainActor.run { [state] in
            state.recordingStatus = .recording
            state.elapsedTime = 0
            state.currentPhase = .preflight
            state.recentTranscripts = []
            state.audioLevel = -160
        }

        // Start track recorder
        let tracker = TrackRecorder(recordingDB: recordingDB, flightID: flightID)
        trackRecorder = tracker
        await tracker.startTracking()

        // Start audio recorder -- wire callbacks if using real AudioRecorder
        let audioURL = Self.audioFileURL(for: flightID)
        audioOutputURL = audioURL

        // Wire buffer streaming and interruption gap callbacks on real AudioRecorder
        if let realRecorder = audioRecorder as? AudioRecorder {
            // Buffer streaming: forward PCM buffers to transcription service (Plan 03 wiring point)
            await realRecorder.setOnBufferAvailable { [weak self] buffer, time in
                // Transcription service will consume these buffers when wired in Plan 03
                _ = self  // Retain reference for future wiring
            }

            // Interruption gap: insert gap marker into recording database
            let capturedDB = recordingDB
            let capturedFlightID = flightID
            await realRecorder.setOnInterruptionGap { reason in
                // Insert interruption gap as a transcript segment marker
                let gapSegment = TranscriptSegmentRecord(
                    flightID: capturedFlightID,
                    text: "[INTERRUPTION: \(reason)]",
                    confidence: 1.0,
                    audioStartTime: 0,
                    audioEndTime: 0,
                    flightPhase: FlightPhaseType.preflight.rawValue
                )
                try? capturedDB.insertTranscript(gapSegment)
            }
        }

        do {
            try await audioRecorder.startRecording(flightID: flightID, profile: profile, outputURL: audioURL)
        } catch {
            logger.error("Audio recording failed to start: \(error.localizedDescription)")
            // Continue without audio -- GPS track is still valuable
        }

        // Start transcription
        do {
            try await transcriptionService.startTranscription(flightID: flightID)
        } catch {
            logger.error("Transcription failed to start: \(error.localizedDescription)")
            // Continue without transcription
        }

        // Start elapsed time timer
        startTimer()

        logger.info("Recording started: \(flightID.uuidString)")
        return flightID
    }

    /// Stop the current recording session and return a summary.
    func stopRecording() async -> FlightRecordingSummary? {
        guard let flightID = currentFlightID, let startDate = recordingStartDate else {
            return nil
        }

        // Update state to stopping
        await MainActor.run { [state] in
            state.recordingStatus = .stopping
        }

        // Stop timer
        timerTask?.cancel()
        timerTask = nil

        // Stop auto-stop monitoring
        autoStopTask?.cancel()
        autoStopTask = nil

        // Stop services
        let audioURL = await audioRecorder.stopRecording()
        await transcriptionService.stopTranscription()

        var trackSummary: TrackRecorderSummary?
        if let tracker = trackRecorder {
            trackSummary = await tracker.stopTracking()
        }
        trackRecorder = nil

        let endDate = Date()

        // Count transcript segments
        let transcriptCount = (try? recordingDB.transcriptSegments(forFlight: flightID).count) ?? 0

        let summary = FlightRecordingSummary(
            flightID: flightID,
            startDate: startDate,
            endDate: endDate,
            trackPointCount: trackSummary?.trackPointCount ?? 0,
            transcriptSegmentCount: transcriptCount,
            departureICAO: nil,  // Will be resolved by caller via nearest airport
            arrivalICAO: nil,    // Will be resolved by caller via nearest airport
            phases: trackSummary?.phaseMarkers ?? [],
            audioFileURL: audioURL
        )

        // Reset state
        currentFlightID = nil
        recordingStartDate = nil
        audioOutputURL = nil

        await MainActor.run { [state] in
            state.recordingStatus = .idle
            state.elapsedTime = 0
        }

        logger.info("Recording stopped: \(flightID.uuidString), \(summary.trackPointCount) track points")
        return summary
    }

    // MARK: - Auto-Start Monitoring

    /// Start monitoring AppState.groundSpeed for auto-start threshold.
    /// When speed exceeds threshold for >1s, begins 3-second countdown.
    func startAutoStartMonitoring(appState: AppState) async {
        autoStartTask?.cancel()

        autoStartTask = Task { [weak self] in
            var speedAboveThresholdSince: Date?
            var countdownStarted = false

            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { break }
                guard let self else { break }

                let currentStatus = await self.state.recordingStatus
                guard currentStatus == .idle || currentStatus == .countdown(remaining: 0) else {
                    // Already recording or in countdown
                    if case .countdown = currentStatus {
                        // Let countdown proceed
                    } else if case .recording = currentStatus {
                        speedAboveThresholdSince = nil
                        countdownStarted = false
                        continue
                    } else {
                        continue
                    }
                    continue
                }

                let speed = await MainActor.run { appState.groundSpeed }
                let threshold = await MainActor.run { appState.autoStartSpeedThresholdKts }
                let isEnabled = await MainActor.run { appState.isAutoStartEnabled }

                guard isEnabled else {
                    speedAboveThresholdSince = nil
                    countdownStarted = false
                    continue
                }

                if speed > threshold {
                    if speedAboveThresholdSince == nil {
                        speedAboveThresholdSince = Date()
                    }

                    let elapsed = Date().timeIntervalSince(speedAboveThresholdSince!)
                    if elapsed >= 1.0 && !countdownStarted {
                        // Begin 3-second countdown
                        countdownStarted = true
                        await self.startCountdown()
                    }
                } else {
                    // Speed dropped below threshold
                    if countdownStarted {
                        await self.cancelCountdown()
                        countdownStarted = false
                    }
                    speedAboveThresholdSince = nil
                }
            }
        }
    }

    /// Stop auto-start monitoring.
    func stopAutoStartMonitoring() async {
        autoStartTask?.cancel()
        autoStartTask = nil
    }

    /// Cancel an active countdown.
    func cancelCountdown() async {
        await MainActor.run { [state] in
            state.recordingStatus = .idle
            state.countdownRemaining = 0
        }
    }

    // MARK: - State Sync

    /// Update state from sub-services. Call periodically from view layer.
    func syncPhaseAndLevel() async {
        if let tracker = trackRecorder {
            let phase = await tracker.currentPhase
            let level = await audioRecorder.audioLevel
            await MainActor.run { [state] in
                state.currentPhase = phase
                state.audioLevel = level
            }
        }
    }

    // MARK: - Private Helpers

    private func startCountdown() async {
        for remaining in stride(from: 3, through: 1, by: -1) {
            await MainActor.run { [state] in
                state.recordingStatus = .countdown(remaining: remaining)
                state.countdownRemaining = remaining
            }

            try? await Task.sleep(for: .seconds(1))

            // Check if cancelled during countdown
            let status = await state.recordingStatus
            if case .idle = status { return }
        }

        // Countdown complete -- start recording
        do {
            _ = try await startRecording()
        } catch {
            logger.error("Auto-start recording failed: \(error.localizedDescription)")
            await MainActor.run { [state] in
                state.recordingStatus = .idle
            }
        }
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { break }
                guard let startDate = await self.recordingStartDate else { break }
                let elapsed = Date().timeIntervalSince(startDate)
                await MainActor.run { [state = await self.state] in
                    state.elapsedTime = elapsed
                }
            }
        }
    }

    /// Generate audio file URL for a flight recording.
    private nonisolated static func audioFileURL(for flightID: UUID) -> URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let recordingDir = appSupport.appendingPathComponent("efb-212/recordings", isDirectory: true)

        try? fileManager.createDirectory(at: recordingDir, withIntermediateDirectories: true)

        return recordingDir.appendingPathComponent("\(flightID.uuidString).m4a")
    }
}

// MARK: - Recording Errors

enum RecordingError: LocalizedError, Sendable {
    case alreadyRecording
    case invalidState
    case notRecording

    var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "A recording is already in progress."
        case .invalidState:
            return "Recording is in an invalid state for this operation."
        case .notRecording:
            return "No recording is currently active."
        }
    }
}
