//
//  ReplayEngine.swift
//  efb-212
//
//  Playback coordinator for track replay -- single source of truth time model.
//  Synchronizes map position, audio playback, and transcript highlighting.
//  Advances at configurable speeds (1x, 2x, 4x, 8x) with GPS interpolation.
//
//  REPLAY-01: Time model drives all synchronized state.
//  REPLAY-02: Interpolation between GPS track points for smooth animation.
//

import Foundation
import CoreLocation
import AVFoundation
import Observation

/// Phase marker position on the scrub bar timeline.
struct PhaseMarkerFraction: Sendable {
    let phase: String
    let fraction: Double
}

@Observable
@MainActor
final class ReplayEngine {

    // MARK: - Public Properties (source of truth)

    /// Current playback position in seconds from recording start (THE source of truth)
    private(set) var currentPosition: TimeInterval = 0

    /// Whether playback is active
    private(set) var isPlaying: Bool = false

    /// Playback speed multiplier: 1x, 2x, 4x, 8x
    private(set) var playbackSpeed: Float = 1.0

    /// Audio muted at 4x/8x because AVAudioPlayer max rate is 2.0
    private(set) var audioMuted: Bool = false

    /// Interpolated GPS coordinate at current position
    private(set) var currentCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)

    /// Altitude at current position -- feet MSL
    private(set) var currentAltitude: Double = 0

    /// Ground speed at current position -- knots
    private(set) var currentSpeed: Double = 0

    /// Heading at current position -- degrees true
    private(set) var currentHeading: Double = 0

    /// Index into transcriptSegments array for the active segment, nil if between segments
    private(set) var currentTranscriptIndex: Int? = nil

    /// Total duration of the flight recording -- seconds
    private(set) var totalDuration: TimeInterval = 0

    /// Phase marker fractional positions along the timeline (for scrub bar markers)
    private(set) var phaseMarkerFractions: [PhaseMarkerFraction] = []

    // MARK: - Diagnostic Properties (for tests)

    /// Number of loaded track points (for test verification)
    var trackPointCount: Int { trackPoints.count }

    /// Number of loaded transcript segments (for test verification)
    var transcriptSegmentCount: Int { transcriptSegments.count }

    /// Number of loaded phase markers (for test verification)
    var phaseMarkerCount: Int { phaseMarkers.count }

    // MARK: - Private Data

    private var trackPoints: [TrackPointRecord] = []
    private var transcriptSegments: [TranscriptSegmentRecord] = []
    private var phaseMarkers: [PhaseMarkerRecord] = []
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private var recordingStartTime: Date = Date()
    private var tickCount: Int = 0

    // MARK: - Init

    init() {}

    // MARK: - Public Methods

    /// Load flight data from RecordingDatabase. Optionally attach audio for synchronized playback.
    func loadFlight(flightID: UUID, recordingDB: RecordingDatabase, audioURL: URL?) throws {
        // Fetch data from GRDB
        trackPoints = try recordingDB.trackPoints(forFlight: flightID)
        transcriptSegments = try recordingDB.transcriptSegments(forFlight: flightID)
        phaseMarkers = try recordingDB.phaseMarkers(forFlight: flightID)

        // Set recording start time from first track point
        recordingStartTime = trackPoints.first?.timestamp ?? Date()

        // Compute total duration from first/last track point timestamps
        if let first = trackPoints.first, let last = trackPoints.last {
            totalDuration = last.timestamp.timeIntervalSince(first.timestamp)
        } else {
            totalDuration = 0
        }

        // Compute phase marker fractions along timeline
        computePhaseMarkerFractions()

        // Set up AVAudioPlayer if audio URL is provided
        if let audioURL = audioURL, FileManager.default.fileExists(atPath: audioURL.path) {
            let player = try AVAudioPlayer(contentsOf: audioURL)
            player.enableRate = true
            player.prepareToPlay()
            audioPlayer = player
        }

        // Reset position and update derived state
        currentPosition = 0
        updateDerivedState()
    }

    /// Start playback at current position and speed.
    func play() {
        isPlaying = true

        // Sync audio to current position
        syncAudioToPosition()
        if !audioMuted {
            audioPlayer?.play()
        }

        // Start 20Hz timer for tick updates
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    /// Pause playback.
    func pause() {
        isPlaying = false
        audioPlayer?.pause()
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    /// Seek to a specific position (clamped to 0...totalDuration).
    func seekTo(_ position: TimeInterval) {
        currentPosition = min(max(position, 0), totalDuration)
        syncAudioToPosition()
        updateDerivedState()
    }

    /// Set playback speed. Mutes audio at 4x/8x (AVAudioPlayer max rate is 2.0).
    func setSpeed(_ speed: Float) {
        playbackSpeed = speed

        if speed <= 2.0 {
            audioMuted = false
            audioPlayer?.rate = speed
            audioPlayer?.volume = 1.0
        } else {
            audioMuted = true
            // Keep audio at 2x so it stays roughly in sync, but muted
            audioPlayer?.rate = 2.0
            audioPlayer?.volume = 0
        }
    }

    /// Interpolate GPS position between track points at a given time offset.
    /// Returns coordinate, heading, altitude, and speed.
    func interpolatedPosition(at time: TimeInterval) -> (coordinate: CLLocationCoordinate2D, heading: Double, altitude: Double, speed: Double) {
        guard !trackPoints.isEmpty else {
            return (CLLocationCoordinate2D(latitude: 0, longitude: 0), 0, 0, 0)
        }

        // Edge case: only one track point
        guard trackPoints.count > 1 else {
            let p = trackPoints[0]
            return (CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude), p.courseDegrees, p.altitudeFeet, p.groundSpeedKnots)
        }

        let targetTime = recordingStartTime.addingTimeInterval(time)

        // Before first point
        if targetTime <= trackPoints.first!.timestamp {
            let p = trackPoints[0]
            return (CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude), p.courseDegrees, p.altitudeFeet, p.groundSpeedKnots)
        }

        // After last point
        if targetTime >= trackPoints.last!.timestamp {
            let p = trackPoints[trackPoints.count - 1]
            return (CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude), p.courseDegrees, p.altitudeFeet, p.groundSpeedKnots)
        }

        // Binary search for bracketing points
        var lo = 0
        var hi = trackPoints.count - 1
        while lo < hi - 1 {
            let mid = (lo + hi) / 2
            if trackPoints[mid].timestamp <= targetTime {
                lo = mid
            } else {
                hi = mid
            }
        }

        let p1 = trackPoints[lo]
        let p2 = trackPoints[hi]

        // Linear interpolation factor
        let interval = p2.timestamp.timeIntervalSince(p1.timestamp)
        let fraction = interval > 0 ? targetTime.timeIntervalSince(p1.timestamp) / interval : 0

        let lat = p1.latitude + (p2.latitude - p1.latitude) * fraction
        let lon = p1.longitude + (p2.longitude - p1.longitude) * fraction
        let alt = p1.altitudeFeet + (p2.altitudeFeet - p1.altitudeFeet) * fraction
        let spd = p1.groundSpeedKnots + (p2.groundSpeedKnots - p1.groundSpeedKnots) * fraction
        let hdg = p1.courseDegrees + (p2.courseDegrees - p1.courseDegrees) * fraction

        return (CLLocationCoordinate2D(latitude: lat, longitude: lon), hdg, alt, spd)
    }

    /// Expose tick for testing. In production, called by Timer at 20Hz.
    /// Bypasses isPlaying guard to allow deterministic unit testing.
    func testTick() {
        currentPosition += 0.05 * Double(playbackSpeed)
        if currentPosition >= totalDuration {
            currentPosition = totalDuration
        }
        updateDerivedState()
    }

    /// Invalidate timer, stop audio, release resources.
    func cleanup() {
        playbackTimer?.invalidate()
        playbackTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }

    // MARK: - Private Methods

    /// Advance playback position by one tick (0.05s * playbackSpeed).
    private func tick() {
        guard isPlaying else { return }

        currentPosition += 0.05 * Double(playbackSpeed)

        // Clamp to end of flight
        if currentPosition >= totalDuration {
            currentPosition = totalDuration
            pause()
        }

        updateDerivedState()

        // Drift correction every ~5 seconds (100 ticks)
        tickCount += 1
        if tickCount % 100 == 0, let player = audioPlayer, player.isPlaying, !audioMuted {
            let drift = abs(currentPosition - player.currentTime)
            if drift > 0.2 {
                player.currentTime = currentPosition
            }
        }
    }

    /// Update all derived state from currentPosition.
    private func updateDerivedState() {
        let result = interpolatedPosition(at: currentPosition)
        currentCoordinate = result.coordinate
        currentHeading = result.heading
        currentAltitude = result.altitude
        currentSpeed = result.speed

        // Find active transcript segment
        currentTranscriptIndex = transcriptSegments.firstIndex { segment in
            currentPosition >= segment.audioStartTime && currentPosition < segment.audioEndTime
        }
    }

    /// Sync AVAudioPlayer currentTime to currentPosition.
    private func syncAudioToPosition() {
        audioPlayer?.currentTime = currentPosition
    }

    /// Compute phase marker fractional positions along the timeline for scrub bar display.
    private func computePhaseMarkerFractions() {
        guard totalDuration > 0 else {
            phaseMarkerFractions = []
            return
        }

        phaseMarkerFractions = phaseMarkers.map { marker in
            let offset = marker.startTimestamp.timeIntervalSince(recordingStartTime)
            let fraction = offset / totalDuration
            return PhaseMarkerFraction(phase: marker.phase, fraction: max(0, min(1, fraction)))
        }
    }
}
