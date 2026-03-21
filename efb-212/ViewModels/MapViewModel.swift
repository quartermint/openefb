//
//  MapViewModel.swift
//  efb-212
//
//  Map coordination -- airport loading, region change handling, layer state,
//  chart expiration state (INFRA-03). Debounces region changes by 500ms
//  and skips queries when center moves less than 5 NM.
//

import Foundation
import Observation
import CoreLocation
import MapLibre

@Observable
@MainActor
final class MapViewModel {

    // MARK: - Dependencies

    let appState: AppState
    let mapService: MapService
    let databaseService: any DatabaseServiceProtocol

    // MARK: - Plan 04 Dependencies (Weather, TFR, Proximity)

    /// Optional weather service -- set by MapContainerView after creation.
    var weatherService: (any WeatherServiceProtocol)?
    /// Optional TFR service -- set by MapContainerView after creation.
    var tfrService: TFRServiceProtocol?
    /// Optional proximity alert service -- set by MapContainerView after creation.
    var proximityAlertService: ProximityAlertService?

    // MARK: - State

    var visibleAirports: [Airport] = []
    var visibleNavaids: [Navaid] = []
    var visibleAirspaces: [Airspace] = []
    var isLoadingAirports: Bool = false
    var lastError: EFBError?

    // MARK: - Chart Expiration (INFRA-03)

    /// Chart expiration date from MapService's MBTiles metadata read.
    var chartExpirationDate: Date? { mapService.chartExpirationDate }

    /// Days remaining until chart expiration. Nil if no chart loaded. Negative if expired.
    var chartDaysRemaining: Int? {
        guard let expirationDate = mapService.chartExpirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day
    }

    // MARK: - Private

    private var lastQueryCenter: CLLocationCoordinate2D?
    private var regionChangeDebounceTask: Task<Void, Never>?
    private var hasAnimatedToFirstLocation: Bool = false

    // MARK: - Init

    init(appState: AppState, mapService: MapService, databaseService: any DatabaseServiceProtocol) {
        self.appState = appState
        self.mapService = mapService
        self.databaseService = databaseService
    }

    // MARK: - Style Loaded

    /// Called when map style finishes loading. Configures layers and loads initial data.
    func onMapStyleLoaded(style: MLNStyle) {
        mapService.onStyleLoaded(style: style)

        // Load initial data for CONUS view
        let conusCenter = CLLocationCoordinate2D(latitude: 39.0, longitude: -98.0)
        loadDataForRegion(center: conusCenter, zoom: 5.0)

        // Sync current layer visibility
        for layer in MapLayer.allCases {
            let visible = appState.visibleLayers.contains(layer)
            mapService.setLayerVisibility(layer, visible: visible)
        }
    }

    // MARK: - Region Changed

    /// Debounce 500ms. Skip if center moved less than 5 NM from last query center.
    func onRegionChanged(center: CLLocationCoordinate2D, zoom: Double) {
        regionChangeDebounceTask?.cancel()
        regionChangeDebounceTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(500))
            } catch {
                return  // Cancelled
            }

            guard let self else { return }

            // Skip if center moved less than 5 NM
            if let lastCenter = lastQueryCenter {
                let lastLocation = CLLocation(latitude: lastCenter.latitude, longitude: lastCenter.longitude)
                let currentLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
                let distanceNM = lastLocation.distance(from: currentLocation) / 1852.0  // meters to NM
                if distanceNM < 5.0 {
                    // Still update map state for zoom changes
                    appState.mapCenter = center
                    appState.mapZoom = zoom
                    return
                }
            }

            appState.mapCenter = center
            appState.mapZoom = zoom

            loadDataForRegion(center: center, zoom: zoom)
            lastQueryCenter = center
        }
    }

    // MARK: - First Location

    /// Called once when first GPS fix is received. Animates map to user position.
    func onFirstLocationReceived(location: CLLocation) {
        guard !hasAnimatedToFirstLocation else { return }
        hasAnimatedToFirstLocation = true
        mapService.animateToLocation(location.coordinate, zoom: 10.0)
    }

    // MARK: - Airport Tapping

    func onAirportTapped(icao: String) {
        appState.selectedAirportID = icao
        appState.isPresentingAirportInfo = true
    }

    // MARK: - Layer Toggles

    /// Toggle a layer in AppState's visibleLayers set and update MapService visibility.
    func toggleLayer(_ layer: MapLayer) {
        if appState.visibleLayers.contains(layer) {
            appState.visibleLayers.remove(layer)
            mapService.setLayerVisibility(layer, visible: false)
        } else {
            appState.visibleLayers.insert(layer)
            mapService.setLayerVisibility(layer, visible: true)

            // If a data layer is toggled on, trigger data load for current region
            switch layer {
            case .airports, .navaids, .airspace:
                loadDataForRegion(center: appState.mapCenter, zoom: appState.mapZoom)
            case .weatherDots:
                Task { await loadWeatherDots() }
            case .tfrs:
                Task { await loadTFRs() }
            default:
                break
            }
        }
    }

    // MARK: - Map Mode

    /// Update map mode. TrackUp enables heading tracking; NorthUp resets to north.
    func setMapMode(_ mode: MapMode) {
        appState.mapMode = mode
        if mode == .trackUp {
            mapService.mapView?.userTrackingMode = .followWithHeading
        } else {
            mapService.mapView?.setDirection(0, animated: true)
        }
    }

    // MARK: - Data Loading

    private func loadDataForRegion(center: CLLocationCoordinate2D, zoom: Double) {
        // Compute radius from zoom level: wider radius at lower zoom
        let radiusNM = 200.0 / pow(2.0, zoom - 5.0)

        isLoadingAirports = true

        // Load airports
        do {
            let airports = try databaseService.airports(near: center, radiusNM: min(radiusNM, 500))
            visibleAirports = airports
            mapService.updateAirports(airports)
        } catch {
            lastError = EFBError.databaseCorrupted
        }

        // Load navaids if layer is visible
        if appState.visibleLayers.contains(.navaids) {
            do {
                let navaids = try databaseService.navaids(near: center, radiusNM: min(radiusNM, 500))
                visibleNavaids = navaids
                mapService.updateNavaids(navaids)
            } catch {
                // Non-critical -- continue without navaids
            }
        }

        // Load airspaces if layer is visible
        if appState.visibleLayers.contains(.airspace) {
            do {
                let airspaces = try databaseService.airspaces(near: center, radiusNM: min(radiusNM, 300))
                visibleAirspaces = airspaces
                mapService.updateAirspaces(airspaces)
            } catch {
                // Non-critical -- continue without airspaces
            }
        }

        isLoadingAirports = false

        // Load weather dots if layer visible (Plan 04)
        if appState.visibleLayers.contains(.weatherDots) {
            Task { await loadWeatherDots() }
        }

        // Load TFRs if layer visible (Plan 04)
        if appState.visibleLayers.contains(.tfrs) {
            Task { await loadTFRs() }
        }
    }

    // MARK: - Weather Dot Loading (Plan 04)

    /// Fetch weather for visible airports and update map weather dots.
    func loadWeatherDots() async {
        guard let weatherService else { return }
        guard !visibleAirports.isEmpty else { return }

        // Build station ID list and coordinate lookup from visible airports
        let stationIDs = visibleAirports.map { $0.icao }
        var stationCoordinates: [String: CLLocationCoordinate2D] = [:]
        for airport in visibleAirports {
            stationCoordinates[airport.icao] = airport.coordinate
        }

        do {
            let weather = try await weatherService.fetchWeatherForStations(stationIDs)
            mapService.updateWeatherDots(weather, stationCoordinates: stationCoordinates)
        } catch {
            // Weather fetch failure is non-critical -- dots just won't update
        }
    }

    // MARK: - TFR Loading (Plan 04)

    /// Fetch TFRs near current map center and update map TFR layer.
    func loadTFRs() async {
        guard let tfrService else { return }

        do {
            let tfrs = try await tfrService.activeTFRs()
            mapService.updateTFRs(tfrs)
        } catch {
            // TFR fetch failure is non-critical
        }
    }

    // MARK: - Proximity Alert Check (Plan 04)

    /// Check airspace/TFR proximity for current ownship position.
    /// Called from MapContainerView on GPS updates, throttled internally to 10s.
    func checkProximityAlerts() {
        guard let position = appState.ownshipPosition else { return }
        proximityAlertService?.checkProximity(position: position, altitude: appState.altitude)
    }
}
