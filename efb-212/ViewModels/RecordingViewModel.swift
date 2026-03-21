//
//  RecordingViewModel.swift
//  efb-212
//
//  Recording UI state management. Bridges RecordingCoordinator.State
//  to SwiftUI via @Observable. Handles start/stop/countdown actions,
//  formatted elapsed time, transcript panel toggle, and stop confirmation.
//
//  Periodically syncs from coordinator state (every 0.5s) for flight phase
//  and audio level updates.
//

import CoreLocation
import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class RecordingViewModel {

    // MARK: - Observed State

    var recordingStatus: RecordingStatus = .idle
    var elapsedTime: TimeInterval = 0
    var currentPhase: FlightPhaseType = .preflight
    var recentTranscripts: [TranscriptDisplayItem] = []
    var audioLevel: Float = -160  // dBFS
    var countdownRemaining: Int = 0
    var showStopConfirmation: Bool = false
    var isTranscriptPanelExpanded: Bool = false
    var lastError: EFBError?

    // MARK: - Dependencies

    private let coordinator: RecordingCoordinator
    private weak var appState: AppState?
    private var syncTask: Task<Void, Never>?

    /// Optional logbook integration -- set from view layer to enable auto-population.
    var logbookViewModel: LogbookViewModel?

    /// SwiftData model context for logbook entry creation (injected from view layer).
    var modelContext: ModelContext?

    // MARK: - Init

    init(coordinator: RecordingCoordinator, appState: AppState) {
        self.coordinator = coordinator
        self.appState = appState
        startSyncLoop()
    }

    // syncTask is cancelled when the ViewModel goes out of scope
    // since it uses [weak self] pattern.

    // MARK: - Actions

    /// Start a new flight recording.
    func startRecording() async {
        do {
            let flightID = try await coordinator.startRecording()
            appState?.activeFlightRecordID = flightID
        } catch {
            lastError = .recordingFailed(underlying: error)
        }
    }

    /// Request stop -- shows confirmation dialog per user decision.
    func requestStop() {
        showStopConfirmation = true
    }

    /// Confirm stop after dialog approval.
    /// After stopping the recording, auto-creates a logbook entry (LOG-01) if
    /// logbookViewModel and modelContext are available.
    func confirmStop() async {
        showStopConfirmation = false
        let summary = await coordinator.stopRecording()
        appState?.activeFlightRecordID = nil

        // LOG-01: Auto-create logbook entry from recording data
        if let summary, let logbookVM = logbookViewModel, let ctx = modelContext {
            // Resolve departure airport from first track point via R-tree nearest lookup
            var depICAO: String?
            var depName: String?
            var arrICAO: String?
            var arrName: String?

            if let dbService = appState?.sharedDatabaseService {
                // Use summary departure/arrival if coordinator resolved them
                if let icao = summary.departureICAO {
                    depICAO = icao
                    depName = (try? dbService.airport(byICAO: icao))?.name
                }
                if let icao = summary.arrivalICAO {
                    arrICAO = icao
                    arrName = (try? dbService.airport(byICAO: icao))?.name
                }
            }

            let aircraftID = appState?.activeAircraftProfileID
            let pilotID = appState?.activePilotProfileID

            logbookVM.createFromRecording(
                summary: summary,
                departureICAO: depICAO,
                departureName: depName,
                arrivalICAO: arrICAO,
                arrivalName: arrName,
                aircraftProfileID: aircraftID,
                aircraftType: nil,  // Will be populated from aircraft profile in edit view
                pilotProfileID: pilotID,
                modelContext: ctx
            )
        }
    }

    /// Cancel an active auto-start countdown.
    func cancelCountdown() async {
        await coordinator.cancelCountdown()
    }

    /// Toggle the live transcript panel expanded/collapsed.
    func toggleTranscriptPanel() {
        isTranscriptPanelExpanded.toggle()
    }

    // MARK: - Formatted Output

    /// Formatted elapsed time as "HH:MM:SS".
    var formattedElapsedTime: String {
        let totalSeconds = Int(elapsedTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    /// Whether the recorder is actively recording (not idle/stopping).
    var isRecording: Bool {
        if case .recording = recordingStatus { return true }
        return false
    }

    /// Whether a countdown is active.
    var isCountingDown: Bool {
        if case .countdown = recordingStatus { return true }
        return false
    }

    // MARK: - State Sync

    /// Periodically sync from RecordingCoordinator.State to update UI.
    private func startSyncLoop() {
        syncTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self else { break }

                let state = await self.coordinator.state
                self.recordingStatus = state.recordingStatus
                self.elapsedTime = state.elapsedTime
                self.currentPhase = state.currentPhase
                self.recentTranscripts = state.recentTranscripts
                self.audioLevel = state.audioLevel
                self.countdownRemaining = state.countdownRemaining

                // Sync key state to AppState for cross-tab visibility
                if let appState = self.appState {
                    appState.recordingStatus = state.recordingStatus
                    appState.currentFlightPhase = state.currentPhase
                    appState.recordingElapsedTime = state.elapsedTime
                    appState.recentTranscripts = state.recentTranscripts
                    appState.audioLevel = state.audioLevel
                }
            }
        }
    }
}
