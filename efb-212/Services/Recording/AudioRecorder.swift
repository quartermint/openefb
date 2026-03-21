//
//  AudioRecorder.swift
//  efb-212
//
//  AVAudioEngine-based cockpit audio recorder with dual output:
//  1. AAC file write for archival recording
//  2. PCM buffer streaming to transcription service via callback
//
//  Handles audio session configuration for background recording,
//  interruption recovery (phone call, Siri), and headphone disconnect.
//
//  Design source: SFR CockpitAudioEngine pattern, adapted for iOS 26.
//

import AVFoundation
import Foundation
import os
#if canImport(UIKit)
import UIKit
#endif

// MARK: - AudioRecorder Actor

actor AudioRecorder: AudioRecorderProtocol {

    // MARK: - Properties

    private var audioEngine: AVAudioEngine?
    private var outputFile: AVAudioFile?
    private var _isRecording = false
    private var _audioLevel: Float = -160  // dBFS silence floor
    private var flightID: UUID?

    /// Callback for streaming PCM buffers to transcription service (Plan 03 wiring point).
    var onBufferAvailable: (@Sendable (AVAudioPCMBuffer, AVAudioTime) -> Void)?

    /// Callback for gap markers on interruptions.
    var onInterruptionGap: (@Sendable (InterruptionGapReason) -> Void)?

    // Notification observers
    private var interruptionObserver: (any NSObjectProtocol)?
    private var routeChangeObserver: (any NSObjectProtocol)?
    private var didBecomeActiveObserver: (any NSObjectProtocol)?
    private var isPausedByInterruption = false

    private let logger = Logger(subsystem: "quartermint.efb-212", category: "AudioRecorder")

    // MARK: - AudioRecorderProtocol

    var isRecording: Bool { _isRecording }
    var audioLevel: Float { _audioLevel }

    // MARK: - Start Recording

    func startRecording(flightID: UUID, profile: AudioQualityProfile, outputURL: URL) async throws {
        self.flightID = flightID

        // Create recordings directory if needed
        let recordingDir = outputURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: recordingDir, withIntermediateDirectories: true)

        // Configure audio session for background recording
        try configureAudioSession(profile: profile)

        // Create audio engine
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Guard channel count > 0 to prevent crash on simulator (SFR pattern)
        guard recordingFormat.channelCount > 0 else {
            logger.warning("No audio input available (channelCount == 0). Skipping audio recording.")
            throw EFBError.audioSessionFailed(underlying: AudioRecorderError.noAudioInput)
        }

        // Create AAC output file
        let outputSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: profile.sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: profile.bitRate
        ]
        let file = try AVAudioFile(forWriting: outputURL, settings: outputSettings)
        outputFile = file

        // Install tap: write to file AND stream to transcription callback
        let bufferCallback = onBufferAvailable
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, time in
            // Write to AAC file
            do {
                try file.write(from: buffer)
            } catch {
                // Log but don't crash -- audio file write errors are recoverable
            }

            // Stream PCM buffer to transcription service
            bufferCallback?(buffer, time)

            // Compute RMS for audio level meter
            guard let channelData = buffer.floatChannelData else { return }
            let channelDataValue = channelData.pointee
            let frameLength = Int(buffer.frameLength)
            guard frameLength > 0 else { return }

            var sum: Float = 0
            for i in 0..<frameLength {
                let sample = channelDataValue[i]
                sum += sample * sample
            }
            let rms = sqrtf(sum / Float(frameLength))
            let dBFS = rms > 0 ? 20 * log10f(rms) : -160

            // Update audio level (actor-isolated property updated from nonisolated context)
            // Use a Task to hop back to actor isolation
            Task { [weak self] in
                await self?.updateAudioLevel(dBFS)
            }
        }

        // Prepare and start engine
        engine.prepare()
        try engine.start()
        audioEngine = engine

        _isRecording = true

        // Register interruption and route change observers
        registerNotificationObservers()

        logger.info("Audio recording started for flight \(flightID.uuidString)")
    }

    // MARK: - Stop Recording

    func stopRecording() async -> URL? {
        guard _isRecording else { return nil }

        // Remove tap and stop engine
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil

        _isRecording = false
        isPausedByInterruption = false

        // Remove notification observers
        removeNotificationObservers()

        // Close output file and capture URL
        let fileURL = outputFile?.url
        outputFile = nil

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        logger.info("Audio recording stopped")
        return fileURL
    }

    // MARK: - Pause / Resume

    func pauseRecording() async {
        guard _isRecording else { return }
        audioEngine?.stop()
        logger.info("Audio recording paused")
    }

    func resumeRecording() async throws {
        guard _isRecording, let engine = audioEngine else { return }

        // Reconfigure audio session before restarting
        try AVAudioSession.sharedInstance().setActive(true)

        try engine.start()
        isPausedByInterruption = false
        logger.info("Audio recording resumed")
    }

    // MARK: - Audio Session Configuration

    private func configureAudioSession(profile: AudioQualityProfile) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [
                .allowBluetooth,
                .allowBluetoothA2DP,
                .defaultToSpeaker,
                .mixWithOthers
            ]
        )
        try session.setPreferredSampleRate(profile.sampleRate)
        try session.setPreferredIOBufferDuration(0.05)  // 50ms buffer
        try session.setPreferredInputNumberOfChannels(1)  // mono
        try session.setActive(true)
    }

    // MARK: - Audio Level Update

    private func updateAudioLevel(_ level: Float) {
        _audioLevel = level
    }

    // MARK: - Notification Observers

    private func registerNotificationObservers() {
        let center = NotificationCenter.default

        // Interruption handling (phone call, Siri)
        interruptionObserver = center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: nil
        ) { [weak self] notification in
            Task { [weak self] in
                await self?.handleInterruption(notification)
            }
        }

        // Route change handling (headphone disconnect)
        routeChangeObserver = center.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: nil
        ) { [weak self] notification in
            Task { [weak self] in
                await self?.handleRouteChange(notification)
            }
        }

        #if canImport(UIKit)
        // Fallback resume on app becoming active (per SFR pattern: not all interruptions
        // have a matching end notification)
        didBecomeActiveObserver = center.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.handleDidBecomeActive()
            }
        }
        #endif
    }

    private func removeNotificationObservers() {
        let center = NotificationCenter.default
        if let observer = interruptionObserver {
            center.removeObserver(observer)
            interruptionObserver = nil
        }
        if let observer = routeChangeObserver {
            center.removeObserver(observer)
            routeChangeObserver = nil
        }
        if let observer = didBecomeActiveObserver {
            center.removeObserver(observer)
            didBecomeActiveObserver = nil
        }
    }

    // MARK: - Interruption Handling

    private func handleInterruption(_ notification: Notification) async {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            // Phone call, Siri -- pause recording, insert gap marker
            logger.info("Audio interruption began")
            await pauseRecording()
            isPausedByInterruption = true
            onInterruptionGap?(.phoneCall)

        case .ended:
            // Auto-resume if system says it's safe
            logger.info("Audio interruption ended")
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    try? await resumeRecording()
                }
            }

        @unknown default:
            break
        }
    }

    // MARK: - Route Change Handling

    private func handleRouteChange(_ notification: Notification) async {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        if reason == .oldDeviceUnavailable {
            // Headphone disconnect -- audio continues via built-in mic per .defaultToSpeaker
            logger.info("Audio route change: headphone disconnected")
            onInterruptionGap?(.headphoneDisconnect)
        }
    }

    // MARK: - Did Become Active Fallback

    private func handleDidBecomeActive() async {
        // Fallback: if recording was paused by interruption and the end notification
        // never arrived (Apple docs: "there is no guarantee"), attempt resume when
        // app returns to foreground
        guard isPausedByInterruption else { return }
        logger.info("App became active with paused recording -- attempting resume")
        try? await resumeRecording()
    }
}

// MARK: - AudioRecorder Errors

enum AudioRecorderError: LocalizedError, Sendable {
    case noAudioInput

    var errorDescription: String? {
        switch self {
        case .noAudioInput:
            return "No audio input available. Audio recording requires a microphone."
        }
    }
}
