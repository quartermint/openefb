//
//  NearestAirportViewModel.swift
//  efb-212
//
//  ViewModel for the Nearest Airport emergency feature.
//  Fetches nearby airports sorted by distance, computes bearing and distance
//  from current position, and auto-refreshes as location changes.
//

import Foundation
import CoreLocation
import Combine

final class NearestAirportViewModel: ObservableObject {

    // MARK: - Published State

    @Published var nearestAirports: [NearbyAirport] = []
    @Published var isLoading: Bool = false
    @Published var lastError: EFBError?
    @Published var hasGPS: Bool = false

    // MARK: - Dependencies

    private let databaseManager: any DatabaseManagerProtocol
    private let locationManager: any LocationManagerProtocol
    private var cancellables = Set<AnyCancellable>()

    /// Number of airports to fetch.
    private let fetchCount: Int = 20

    // MARK: - Init

    init(databaseManager: any DatabaseManagerProtocol,
         locationManager: any LocationManagerProtocol) {
        self.databaseManager = databaseManager
        self.locationManager = locationManager
        subscribeToLocationUpdates()
    }

    // MARK: - Location Subscription

    private func subscribeToLocationUpdates() {
        locationManager.locationPublisher
            .removeDuplicates { prev, next in
                // Only refresh if moved more than ~0.5 NM (≈926 m)
                prev.distance(from: next) < 926
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.hasGPS = true
                Task { [weak self] in
                    await self?.fetchNearestAirports(from: location)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Fetch

    /// Fetch nearest airports from the database relative to the given location.
    func fetchNearestAirports(from location: CLLocation) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let airports = try await databaseManager.nearestAirports(
                to: location.coordinate, count: fetchCount
            )
            nearestAirports = airports.map { airport in
                let airportLocation = CLLocation(
                    latitude: airport.latitude,
                    longitude: airport.longitude
                )
                let distanceNM = location.distanceInNM(to: airportLocation)
                let bearing = location.bearing(to: airportLocation)
                let longestRunway = airport.runways.max(by: { $0.length < $1.length })
                let ctaf = airport.ctafFrequency
                    ?? airport.frequencies.first(where: { $0.type == .ctaf })?.frequency
                let isTowered = airport.frequencies.contains(where: { $0.type == .tower })

                return NearbyAirport(
                    airport: airport,
                    distanceNM: distanceNM,
                    bearingTrue: bearing,
                    longestRunwayLength: longestRunway?.length,
                    longestRunwaySurface: longestRunway?.surface,
                    ctafFrequency: ctaf,
                    isTowered: isTowered
                )
            }
            lastError = nil
        } catch {
            lastError = .airportNotFound("nearest query")
        }
    }

    /// Manual refresh using current location (if available).
    func refresh() async {
        if let location = locationManager.location {
            hasGPS = true
            await fetchNearestAirports(from: location)
        } else {
            hasGPS = false
        }
    }
}

// MARK: - NearbyAirport

/// An airport with precomputed distance and bearing from the user's position.
struct NearbyAirport: Identifiable {
    var id: String { airport.icao }
    let airport: Airport
    let distanceNM: Double               // nautical miles
    let bearingTrue: Double              // degrees true
    let longestRunwayLength: Int?        // feet
    let longestRunwaySurface: SurfaceType?
    let ctafFrequency: Double?           // MHz
    let isTowered: Bool
}
