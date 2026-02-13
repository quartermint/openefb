//
//  EFBRecordingCoordinator.swift
//  efb-212
//
//  STUB — Phase 2 feature placeholder for flight recording coordination.
//  Provides published state properties so recording UI stubs compile.
//  Actual GPS track recording, audio capture, and debrief will be
//  implemented in Phase 2 using SFR (Sovereign Flight Recorder) packages.
//
//  MainActor by default (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor).
//

import Foundation
import Combine

final class EFBRecordingCoordinator: ObservableObject {

    // MARK: - Published State

    @Published var isRecording: Bool = false
    @Published var recordingDuration: TimeInterval = 0       // seconds
    @Published var currentPhase: String = "Idle"

    // MARK: - Phase 2 Stubs

    /// Arms the recording system for automatic start on takeoff detection.
    /// Phase 2 feature — currently a no-op placeholder.
    func armRecording() {
        currentPhase = "Phase 2 feature"
        print("[EFBRecordingCoordinator] armRecording() — Coming in Phase 2")
    }

    /// Starts active flight recording (GPS track, audio, telemetry).
    /// Phase 2 feature — currently a no-op placeholder.
    func startRecording() {
        print("[EFBRecordingCoordinator] startRecording() — Recording is a Phase 2 feature")
    }

    /// Stops the active recording and finalizes the flight record.
    /// Phase 2 feature — currently a no-op placeholder.
    func stopRecording() {
        print("[EFBRecordingCoordinator] stopRecording() — Recording is a Phase 2 feature")
    }
}
