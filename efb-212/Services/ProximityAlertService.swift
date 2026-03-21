//
//  ProximityAlertService.swift
//  efb-212
//
//  Airspace and TFR proximity detection with distance-based alerts.
//  Checks pilot position against nearby airspaces and TFRs,
//  firing alerts at configurable distance thresholds per airspace class.
//
//  Alert thresholds:
//  - Class B: 5 NM
//  - Class C: 3 NM
//  - Class D: 2 NM
//  - TFR: 3 NM
//

import Foundation
import CoreLocation
import os

// MARK: - ProximityAlert

struct ProximityAlert: Identifiable, Sendable {
    let id: String
    let type: AlertType
    let name: String
    let distance: Double      // nautical miles
    let altitude: String      // floor/ceiling info (e.g., "SFC-10000")

    enum AlertType: Sendable {
        case airspace
        case tfr
    }
}

// MARK: - ProximityAlertService

@Observable
@MainActor
final class ProximityAlertService {

    // MARK: - Dependencies

    let databaseService: any DatabaseServiceProtocol

    // MARK: - State

    var activeAlerts: [ProximityAlert] = []
    var isInAirspace: Bool = false
    var nearestAirspaceDistance: Double?  // nautical miles

    // MARK: - Configuration

    /// Alert thresholds per airspace class in nautical miles.
    static let alertThresholds: [AirspaceClass: Double] = [
        .bravo: 5.0,
        .charlie: 3.0,
        .delta: 2.0
    ]
    static let tfrAlertThresholdNM: Double = 3.0

    // MARK: - Throttling

    private var lastCheckTime: Date?
    private let checkIntervalSeconds: TimeInterval = 10  // Throttle to once per 10 seconds

    private let logger = Logger(subsystem: "quartermint.efb-212", category: "ProximityAlert")

    // MARK: - Init

    init(databaseService: any DatabaseServiceProtocol) {
        self.databaseService = databaseService
    }

    // MARK: - Proximity Check

    /// Check airspace and TFR proximity for the given position.
    /// Throttled to once per 10 seconds to avoid excessive DB queries.
    func checkProximity(position: CLLocation, altitude: Double) {
        // Throttle checks
        if let lastCheck = lastCheckTime,
           Date().timeIntervalSince(lastCheck) < checkIntervalSeconds {
            return
        }
        lastCheckTime = Date()

        var newAlerts: [ProximityAlert] = []
        var foundInAirspace = false
        var closestDistance: Double?

        // 1. Check airspaces containing current position
        do {
            let containingAirspaces = try databaseService.airspaces(near: position.coordinate, radiusNM: 5.0)

            for airspace in containingAirspaces {
                let distance = distanceToAirspace(from: position.coordinate, airspace: airspace)

                // Check if we're inside this airspace
                if distance <= 0.0 {
                    foundInAirspace = true
                    let alert = ProximityAlert(
                        id: "airspace-\(airspace.id)",
                        type: .airspace,
                        name: airspace.name,
                        distance: 0,
                        altitude: formatAltitude(floor: airspace.floor, ceiling: airspace.ceiling)
                    )
                    newAlerts.append(alert)
                    continue
                }

                // Check against threshold for this airspace class
                let threshold = Self.alertThresholds[airspace.classification]
                if let threshold, distance <= threshold {
                    let alert = ProximityAlert(
                        id: "airspace-\(airspace.id)",
                        type: .airspace,
                        name: airspace.name,
                        distance: distance,
                        altitude: formatAltitude(floor: airspace.floor, ceiling: airspace.ceiling)
                    )
                    newAlerts.append(alert)
                }

                // Track closest distance
                if closestDistance == nil || distance < closestDistance! {
                    closestDistance = distance
                }
            }
        } catch {
            logger.warning("Airspace proximity check failed: \(error.localizedDescription)")
        }

        // 2. Update state
        activeAlerts = newAlerts
        isInAirspace = foundInAirspace
        nearestAirspaceDistance = closestDistance
    }

    /// Check TFR proximity separately (called when TFR data is available).
    func checkTFRProximity(position: CLLocation, tfrs: [TFR]) {
        var tfrAlerts: [ProximityAlert] = []

        for tfr in tfrs {
            let tfrCenter = CLLocation(latitude: tfr.latitude, longitude: tfr.longitude)
            let distanceNM = position.distance(from: tfrCenter) / 1852.0  // meters to NM

            let tfrRadius = tfr.radiusNM ?? 0
            let effectiveDistance = max(0, distanceNM - tfrRadius)

            if effectiveDistance <= Self.tfrAlertThresholdNM {
                let alert = ProximityAlert(
                    id: "tfr-\(tfr.id)",
                    type: .tfr,
                    name: tfr.description,
                    distance: effectiveDistance,
                    altitude: formatAltitude(floor: tfr.floorAltitude, ceiling: tfr.ceilingAltitude)
                )
                tfrAlerts.append(alert)
            }
        }

        // Merge TFR alerts with existing airspace alerts
        let airspaceAlerts = activeAlerts.filter { $0.type == .airspace }
        activeAlerts = airspaceAlerts + tfrAlerts
    }

    // MARK: - Helpers

    /// Approximate distance from position to airspace boundary in nautical miles.
    /// Returns 0 if inside, positive distance if outside.
    private func distanceToAirspace(from coordinate: CLLocationCoordinate2D, airspace: Airspace) -> Double {
        switch airspace.geometry {
        case .circle(let center, let radiusNM):
            guard center.count >= 2 else { return .greatestFiniteMagnitude }
            let centerCoord = CLLocationCoordinate2D(latitude: center[0], longitude: center[1])
            let distanceNM = haversineDistanceNM(from: coordinate, to: centerCoord)
            return max(0, distanceNM - radiusNM)

        case .polygon(let coordinates):
            // Approximate: compute distance to nearest polygon vertex
            var minDistance: Double = .greatestFiniteMagnitude
            for coord in coordinates {
                guard coord.count >= 2 else { continue }
                let vertex = CLLocationCoordinate2D(latitude: coord[0], longitude: coord[1])
                let dist = haversineDistanceNM(from: coordinate, to: vertex)
                minDistance = min(minDistance, dist)
            }
            return max(0, minDistance)
        }
    }

    /// Format altitude range string for display (e.g., "SFC-10000'" or "1200'-10000'").
    private func formatAltitude(floor: Int, ceiling: Int) -> String {
        let floorStr = floor == 0 ? "SFC" : "\(floor)'"
        let ceilingStr = ceiling >= 99999 ? "UNL" : "\(ceiling)'"
        return "\(floorStr)-\(ceilingStr)"
    }

    /// Haversine great-circle distance in nautical miles.
    private func haversineDistanceNM(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> Double {
        let earthRadiusNM = 3440.065  // nautical miles
        let dLat = (to.latitude - from.latitude) * .pi / 180.0
        let dLon = (to.longitude - from.longitude) * .pi / 180.0
        let lat1 = from.latitude * .pi / 180.0
        let lat2 = to.latitude * .pi / 180.0

        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadiusNM * c
    }
}
