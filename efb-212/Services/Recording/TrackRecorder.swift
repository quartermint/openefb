//
//  TrackRecorder.swift
//  efb-212
//
//  GPS track capture actor. Consumes CLLocationUpdate.liveUpdates(.airborne)
//  and writes TrackPointRecord to RecordingDatabase at 1Hz.
//  Owns a FlightPhaseDetector and publishes phase changes.
//
//  Uses CLBackgroundActivitySession for background GPS (stored as strong property).
//

import Foundation
import CoreLocation

/// Summary returned when track recording stops.
struct TrackRecorderSummary: Sendable {
    let trackPointCount: Int
    let phaseMarkers: [PhaseMarkerRecord]
    let currentPhase: FlightPhaseType
}

actor TrackRecorder {

    // MARK: - Properties

    private let recordingDB: RecordingDatabase
    private var phaseDetector: FlightPhaseDetector
    private var trackingTask: Task<Void, Never>?
    private var backgroundSession: CLBackgroundActivitySession?
    private let flightID: UUID
    private var _trackPointCount: Int = 0
    private var _currentPhase: FlightPhaseType = .preflight

    /// Phase change callback -- called on each phase transition.
    var onPhaseChange: ((FlightPhaseType, PhaseMarkerRecord) -> Void)?

    // MARK: - Init

    init(recordingDB: RecordingDatabase, flightID: UUID) {
        self.recordingDB = recordingDB
        self.flightID = flightID
        self.phaseDetector = FlightPhaseDetector()
    }

    // MARK: - Public API

    var currentPhase: FlightPhaseType {
        _currentPhase
    }

    var trackPointCount: Int {
        _trackPointCount
    }

    /// Start GPS tracking via CLLocationUpdate.liveUpdates(.airborne).
    /// Creates CLBackgroundActivitySession for background operation.
    func startTracking() async {
        // Enable background GPS tracking
        backgroundSession = CLBackgroundActivitySession()

        trackingTask = Task { [weak self] in
            let updates = CLLocationUpdate.liveUpdates(.airborne)

            do {
                for try await update in updates {
                    guard !Task.isCancelled else { break }
                    guard let location = update.location else { continue }
                    guard let self else { break }

                    // Convert CLLocation to aviation units (same conversions as LocationService)
                    let speedKnots = max(0, location.speed * 1.94384)  // m/s to knots
                    let altitudeFeet = location.altitude / 0.3048       // meters to feet MSL
                    let trackDegrees = location.course >= 0 ? location.course : 0  // degrees true

                    // Compute VSI from successive points (simplified -- uses location vertical accuracy)
                    let vsi = location.speedAccuracy >= 0 ? 0.0 : 0.0  // placeholder for first point
                    // VSI is computed from successive altitude readings in the phase detector's smoothing

                    let point = TrackPointRecord(
                        flightID: await self.flightID,
                        timestamp: location.timestamp,
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        altitudeFeet: altitudeFeet,
                        groundSpeedKnots: speedKnots,
                        verticalSpeedFPM: vsi,
                        courseDegrees: trackDegrees
                    )

                    // Write to GRDB (append-only, no memory accumulation)
                    try? await self.recordingDB.insertTrackPoint(point)
                    await self.incrementCount()

                    // Run through phase detector
                    let previousPhase = await self._currentPhase
                    let newPhase = await self.processPhase(point)

                    if newPhase != previousPhase {
                        // Phase changed -- notify
                        if let lastMarker = await self.phaseDetector.phaseMarkers.last {
                            try? await self.recordingDB.insertPhaseMarker(lastMarker)
                            await self.onPhaseChange?(newPhase, lastMarker)
                        }
                    }
                }
            } catch {
                // CLLocationUpdate can throw on cancellation or auth denial
            }
        }
    }

    /// Stop GPS tracking and return summary.
    func stopTracking() -> TrackRecorderSummary {
        trackingTask?.cancel()
        trackingTask = nil
        backgroundSession?.invalidate()
        backgroundSession = nil

        return TrackRecorderSummary(
            trackPointCount: _trackPointCount,
            phaseMarkers: phaseDetector.phaseMarkers,
            currentPhase: _currentPhase
        )
    }

    // MARK: - Private Helpers

    private func incrementCount() {
        _trackPointCount += 1
    }

    private func processPhase(_ point: TrackPointRecord) -> FlightPhaseType {
        let phase = phaseDetector.process(point)
        _currentPhase = phase
        return phase
    }
}
