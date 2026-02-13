//
//  MapViewModel.swift
//  efb-212
//
//  Coordinates MapService with AppState. Handles airport loading for
//  the visible map region and airport tap-to-info flow.
//  All ViewModels are @MainActor by default (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor).
//

import Foundation
import CoreLocation
import Combine

final class MapViewModel: ObservableObject {

    // MARK: - Published State

    /// Airports currently visible in the map viewport.
    @Published var visibleAirports: [Airport] = []

    /// Currently selected airport (tapped on map).
    @Published var selectedAirport: Airport?

    /// Loading indicator for airport data fetch.
    @Published var isLoadingAirports: Bool = false

    /// Last error encountered during airport loading.
    @Published var lastError: EFBError?

    // MARK: - Dependencies

    private let databaseManager: any DatabaseManagerProtocol
    private let locationManager: (any LocationManagerProtocol)?
    let mapService: MapService
    private var cancellables = Set<AnyCancellable>()

    /// Debounce interval for region-change airport reloads — seconds.
    private let regionChangeDebounce: TimeInterval = 0.5

    /// Maximum radius for airport queries — nautical miles.
    /// Limits query scope to prevent loading thousands of airports at low zoom.
    private let maxQueryRadiusNM: Double = 100.0

    // MARK: - Init

    init(
        databaseManager: any DatabaseManagerProtocol,
        mapService: MapService,
        locationManager: (any LocationManagerProtocol)? = nil
    ) {
        self.databaseManager = databaseManager
        self.mapService = mapService
        self.locationManager = locationManager
        setupMapServiceDelegate()
        subscribeToLocationUpdates()
        loadInitialAirports()
    }

    // MARK: - Setup

    private func setupMapServiceDelegate() {
        mapService.delegate = self
    }

    /// Subscribe to location updates to render ownship position on the map.
    private func subscribeToLocationUpdates() {
        guard let locationManager else { return }
        locationManager.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self else { return }
                self.mapService.updateOwnship(
                    location: location,
                    heading: locationManager.heading
                )
            }
            .store(in: &cancellables)
    }

    /// Load airports around the default map center on startup.
    private func loadInitialAirports() {
        let center = mapService.currentCenter
        let radiusNM = estimatedRadiusNM(for: mapService.currentZoom)
        Task { [weak self] in
            await self?.loadAirportsForRegion(center: center, radiusNM: radiusNM)
        }
    }

    // MARK: - Airport Loading

    /// Load airports within a radius of the given center coordinate.
    /// Uses the database manager to query airports near the visible region.
    /// - Parameters:
    ///   - center: Center of the visible map region.
    ///   - radiusNM: Search radius in nautical miles.
    func loadAirportsForRegion(center: CLLocationCoordinate2D, radiusNM: Double) async {
        // Clamp radius to prevent excessive queries at low zoom
        let clampedRadius = min(radiusNM, maxQueryRadiusNM)

        isLoadingAirports = true
        defer { isLoadingAirports = false }

        do {
            let airports = try await databaseManager.airports(near: center, radiusNM: clampedRadius)
            visibleAirports = airports
            mapService.addAirportAnnotations(airports)
        } catch {
            lastError = .airportNotFound("region query")
        }
    }

    /// Select an airport by model — triggers info sheet presentation.
    /// - Parameter airport: The airport to select.
    func selectAirport(_ airport: Airport) {
        selectedAirport = airport
    }

    /// Select an airport by ICAO identifier — performs database lookup.
    /// - Parameter icao: ICAO identifier (e.g., "KPAO").
    func selectAirport(byICAO icao: String) async {
        do {
            if let airport = try await databaseManager.airport(byICAO: icao) {
                selectedAirport = airport
            } else {
                lastError = .airportNotFound(icao)
            }
        } catch {
            lastError = .airportNotFound(icao)
        }
    }

    /// Clear the current airport selection.
    func clearSelection() {
        selectedAirport = nil
    }

    // MARK: - Zoom to Radius Conversion

    /// Estimate the visible radius in nautical miles based on map zoom level.
    /// Rough approximation: at zoom 10, roughly 20 NM radius is visible on iPad.
    /// - Parameter zoomLevel: MapLibre zoom level (0-22).
    /// - Returns: Estimated visible radius in nautical miles.
    func estimatedRadiusNM(for zoomLevel: Double) -> Double {
        // At zoom 0, the whole world is visible (~10800 NM radius at equator).
        // Each zoom level halves the visible area (doubles the scale).
        // At zoom 10, roughly 20 NM radius on a typical iPad viewport.
        let baseRadiusNM = 20480.0  // nautical miles at zoom 0
        return min(baseRadiusNM / pow(2.0, zoomLevel), maxQueryRadiusNM)
    }
}

// MARK: - MapServiceDelegate

extension MapViewModel: MapServiceDelegate {

    func mapService(_ service: MapService, didChangeRegion center: CLLocationCoordinate2D, zoom: Double) {
        // Reload airports for the new visible region.
        // Only load if airports layer is enabled (checked by caller if needed).
        let radiusNM = estimatedRadiusNM(for: zoom)

        Task { [weak self] in
            await self?.loadAirportsForRegion(center: center, radiusNM: radiusNM)
        }
    }

    func mapService(_ service: MapService, didSelectAirport icao: String) {
        Task { [weak self] in
            await self?.selectAirport(byICAO: icao)
        }
    }
}
