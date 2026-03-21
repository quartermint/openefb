//
//  ReplayViewModel.swift
//  efb-212
//
//  UI state wrapper around ReplayEngine for the track replay view.
//  Manages panel visibility, auto-follow toggle, speed picker, loading state.
//  @Observable @MainActor per project conventions.
//

import Foundation
import Observation

@Observable
@MainActor
final class ReplayViewModel {

    // MARK: - Replay Engine (source of truth for playback state)

    let replayEngine = ReplayEngine()

    // MARK: - UI State

    /// Right panel visibility -- transcript panel expanded/collapsed
    var isTranscriptPanelExpanded: Bool = true

    /// Map auto-centers on replay marker; user pan disables, re-center button re-enables
    var autoFollow: Bool = true

    /// Whether the speed picker popover is shown
    var showSpeedPicker: Bool = false

    /// Loading state while flight data is fetched from RecordingDatabase
    var isLoading: Bool = true

    /// Error message if flight data load fails
    var loadError: String?

    // MARK: - Constants

    /// Available playback speeds per user decision
    static let availableSpeeds: [Float] = [1.0, 2.0, 4.0, 8.0]

    // MARK: - Methods

    /// Load flight data from RecordingDatabase and optional audio file.
    /// Resolves audioFileURL relative path under Application Support/efb-212/.
    func loadFlight(flightRecord: SchemaV1.FlightRecord, appState: AppState) {
        isLoading = true
        loadError = nil

        guard let recordingDB = appState.getOrCreateRecordingDatabase() else {
            loadError = "Could not access recording database."
            isLoading = false
            return
        }

        // Resolve audio URL from relative path stored in FlightRecord
        var audioURL: URL?
        if let relativePath = flightRecord.audioFileURL, !relativePath.isEmpty {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first
            if let appSupport = appSupport {
                let fullURL = appSupport.appendingPathComponent(relativePath)
                if FileManager.default.fileExists(atPath: fullURL.path) {
                    audioURL = fullURL
                }
            }
        }

        do {
            try replayEngine.loadFlight(
                flightID: flightRecord.id,
                recordingDB: recordingDB,
                audioURL: audioURL
            )
            isLoading = false
        } catch {
            loadError = "Failed to load flight data: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// Toggle play/pause state.
    func togglePlayPause() {
        if replayEngine.isPlaying {
            replayEngine.pause()
        } else {
            replayEngine.play()
        }
    }

    /// Select a new playback speed and dismiss speed picker.
    func selectSpeed(_ speed: Float) {
        replayEngine.setSpeed(speed)
        showSpeedPicker = false
    }

    /// User panned the map -- disable auto-follow.
    func onUserPan() {
        autoFollow = false
    }

    /// Re-center map on replay marker and re-enable auto-follow.
    func recenter() {
        autoFollow = true
    }

    /// Release resources when leaving replay view.
    func cleanup() {
        replayEngine.cleanup()
    }
}
