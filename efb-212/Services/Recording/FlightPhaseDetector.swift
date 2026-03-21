//
//  FlightPhaseDetector.swift
//  efb-212
//
//  Speed + altitude state machine with 30-second hysteresis for flight phase detection.
//  Pure-function struct consuming TrackPointRecord values -- no actor isolation needed.
//  5-point rolling average for smoothing. Thresholds derived from SFR reference implementation.
//
//  Phase transitions:
//    preflight (<5kts) -> taxi (5-15kts) -> takeoff (>15kts + climbing) ->
//    departure (>60kts + >500ft + climbing) -> cruise (level >500ft) ->
//    approach (descending) -> landing (<15kts after descent) -> postflight (<5kts sustained)
//

import Foundation

struct FlightPhaseDetector: Sendable {

    // MARK: - State

    private(set) var currentPhase: FlightPhaseType = .preflight
    private var recentPoints: [TrackPointRecord] = []  // 5-point smoothing window
    private var phaseEnteredAt: Date = Date(timeIntervalSince1970: 0)
    let hysteresisSeconds: TimeInterval = 30  // minimum time in phase before transition

    /// Track the highest cruise altitude for approach detection.
    private var maxCruiseAltitude: Double = 0

    /// Track open phase marker ID for closing.
    private(set) var currentPhaseMarkerID: UUID?

    // MARK: - Phase Markers (accumulated during processing)

    private(set) var phaseMarkers: [PhaseMarkerRecord] = []

    // MARK: - Init

    init() {}

    // MARK: - Processing

    /// Process a new track point and return the current flight phase.
    /// Call this for each GPS update (1Hz).
    mutating func process(_ point: TrackPointRecord) -> FlightPhaseType {
        recentPoints.append(point)
        if recentPoints.count > 5 { recentPoints.removeFirst() }

        // Compute smoothed values from rolling window
        let smoothedSpeed = recentPoints.map(\.groundSpeedKnots).reduce(0, +) / Double(recentPoints.count)
        let smoothedAlt = recentPoints.map(\.altitudeFeet).reduce(0, +) / Double(recentPoints.count)
        let smoothedVSI = recentPoints.map(\.verticalSpeedFPM).reduce(0, +) / Double(recentPoints.count)

        // Detect candidate phase
        let candidatePhase = detectPhase(speed: smoothedSpeed, altitude: smoothedAlt, vsi: smoothedVSI)

        // Track max altitude during cruise for approach detection
        if currentPhase == .cruise {
            maxCruiseAltitude = max(maxCruiseAltitude, smoothedAlt)
        }

        // Enforce hysteresis: only transition if candidate differs AND minimum time has elapsed
        if candidatePhase != currentPhase {
            let elapsed = point.timestamp.timeIntervalSince(phaseEnteredAt)
            guard elapsed >= hysteresisSeconds else { return currentPhase }

            // Close current phase marker
            if let markerID = currentPhaseMarkerID {
                if let idx = phaseMarkers.firstIndex(where: { $0.id == markerID }) {
                    phaseMarkers[idx] = PhaseMarkerRecord(
                        id: phaseMarkers[idx].id,
                        flightID: phaseMarkers[idx].flightID,
                        phase: phaseMarkers[idx].phase,
                        startTimestamp: phaseMarkers[idx].startTimestamp,
                        endTimestamp: point.timestamp,
                        latitude: phaseMarkers[idx].latitude,
                        longitude: phaseMarkers[idx].longitude
                    )
                }
            }

            // Transition
            currentPhase = candidatePhase
            phaseEnteredAt = point.timestamp

            // Open new phase marker
            let newMarker = PhaseMarkerRecord(
                flightID: point.flightID,
                phase: candidatePhase.rawValue,
                startTimestamp: point.timestamp,
                latitude: point.latitude,
                longitude: point.longitude
            )
            phaseMarkers.append(newMarker)
            currentPhaseMarkerID = newMarker.id
        }

        return currentPhase
    }

    // MARK: - Phase Detection Logic

    /// Determine the candidate phase from smoothed sensor data.
    /// Does NOT apply hysteresis -- that is handled by process().
    private func detectPhase(speed: Double, altitude: Double, vsi: Double) -> FlightPhaseType {
        switch currentPhase {
        case .preflight:
            // Transition to taxi when speed 5-15 kts
            if speed >= 5 {
                return .taxi
            }
            return .preflight

        case .taxi:
            // Back to preflight if stopped
            if speed < 5 {
                return .preflight
            }
            // Transition to takeoff when speed > 15 kts AND climbing
            if speed > 15 && vsi > 200 {
                return .takeoff
            }
            return .taxi

        case .takeoff:
            // Transition to departure when > 60 kts, > 500 ft, still climbing
            if speed > 60 && altitude > 500 && vsi > 200 {
                return .departure
            }
            // Fall back to taxi if speed drops
            if speed < 15 {
                return .taxi
            }
            return .takeoff

        case .departure:
            // Transition to cruise when level flight (|VSI| < 200 fpm) at altitude
            if altitude > 500 && abs(vsi) < 200 {
                return .cruise
            }
            return .departure

        case .cruise:
            // Transition to approach when descending (VSI < -200 fpm)
            if vsi < -200 {
                return .approach
            }
            return .cruise

        case .approach:
            // Transition to landing when speed < 15 kts
            if speed < 15 {
                return .landing
            }
            // Back to cruise if climbing again (go-around)
            if vsi > 200 && altitude > 500 {
                return .cruise
            }
            return .approach

        case .landing:
            // Transition to postflight when speed < 5 kts sustained
            if speed < 5 {
                return .postflight
            }
            return .landing

        case .postflight:
            // Stay in postflight (terminal state)
            return .postflight
        }
    }
}
