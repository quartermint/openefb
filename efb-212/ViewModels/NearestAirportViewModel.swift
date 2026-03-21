//
//  NearestAirportViewModel.swift
//  efb-212
//
//  Nearest airport computation using R-tree spatial queries from AviationDatabase.
//  Updates nearest airport when ownship position changes by >0.5 NM to avoid
//  excessive DB queries. Maintains sorted list of nearest 10 airports for the
//  expanded nearest-airport view.
//

import Foundation
import Observation
import CoreLocation

// MARK: - NearestAirportEntry

/// A single entry in the nearest airports list with precomputed distance and bearing.
struct NearestAirportEntry: Identifiable, Sendable {
    let airport: Airport
    let distance: Double   // nautical miles
    let bearing: Double    // degrees true

    var id: String { airport.icao }
}

// MARK: - NearestAirportViewModel

@Observable
@MainActor
final class NearestAirportViewModel {

    // MARK: - Dependencies

    let databaseService: any DatabaseServiceProtocol
    private let appState: AppState

    // MARK: - Published State

    /// The single closest airport to ownship.
    var nearestAirport: Airport?

    /// Distance to nearest airport in nautical miles.
    var nearestDistance: Double?

    /// Bearing to nearest airport in degrees true.
    var nearestBearing: Double?

    /// Full sorted list of nearest airports (up to 10).
    var nearestAirports: [NearestAirportEntry] = []

    /// Loading indicator for async queries.
    var isLoading: Bool = false

    // MARK: - Private

    /// Last position used for nearest airport query. Prevents re-querying
    /// when ownship moves less than 0.5 NM.
    private var lastQueryPosition: CLLocation?

    // MARK: - Init

    init(appState: AppState, databaseService: any DatabaseServiceProtocol) {
        self.appState = appState
        self.databaseService = databaseService
    }

    // MARK: - Update Nearest

    /// Recompute nearest airports from the given ownship position.
    /// Skips query if position moved less than 0.5 NM from last query.
    func updateNearest(from position: CLLocation) {
        // Skip if position moved less than 0.5 NM from last query
        if let lastPosition = lastQueryPosition {
            let distanceMoved = position.distanceInNM(to: lastPosition)
            if distanceMoved < 0.5 {
                return
            }
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let airports = try databaseService.nearestAirports(
                to: position.coordinate,
                count: 10
            )

            // Compute distance and bearing for each airport
            var entries: [NearestAirportEntry] = []
            for airport in airports {
                let airportLocation = CLLocation(
                    latitude: airport.latitude,
                    longitude: airport.longitude
                )
                let distance = position.distanceInNM(to: airportLocation)  // nautical miles
                let bearing = position.bearing(to: airportLocation)        // degrees true

                entries.append(NearestAirportEntry(
                    airport: airport,
                    distance: distance,
                    bearing: bearing
                ))
            }

            // Sort by distance (ascending)
            entries.sort { $0.distance < $1.distance }

            // Update state
            nearestAirports = entries

            if let closest = entries.first {
                nearestAirport = closest.airport
                nearestDistance = closest.distance
                nearestBearing = closest.bearing
            } else {
                nearestAirport = nil
                nearestDistance = nil
                nearestBearing = nil
            }

            lastQueryPosition = position
        } catch {
            // Non-critical -- nearest airport is informational.
            // Keep stale data rather than clearing it.
        }
    }

    // MARK: - Direct-To

    /// Set direct-to navigation to the specified airport. Updates AppState
    /// with distance and ETE computed from current ownship position and ground speed.
    func setDirectTo(airport: Airport) {
        appState.directToAirport = airport
        appState.activeFlightPlan = true

        // Compute distance from ownship to target airport
        if let ownship = appState.ownshipPosition {
            let targetLocation = CLLocation(
                latitude: airport.latitude,
                longitude: airport.longitude
            )
            let distanceNM = ownship.distanceInNM(to: targetLocation)
            appState.distanceToNext = distanceNM

            // Compute ETE from distance and ground speed
            let gs = appState.groundSpeed  // knots
            if gs > 10 {
                // ETE in seconds = (distance NM / speed knots) * 3600
                appState.estimatedTimeEnroute = (distanceNM / gs) * 3600
            } else {
                appState.estimatedTimeEnroute = nil
            }
        }
    }
}
