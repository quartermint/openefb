//
//  AppState.swift
//  efb-212
//
//  Root state coordinator -- @Observable macro with @MainActor isolation.
//  Injected into view hierarchy via .environment(appState).
//  All sub-state properties organized by concern.
//

import Observation
import CoreLocation

@Observable
@MainActor
final class AppState {

    // MARK: - Navigation State

    var selectedTab: AppTab = .map
    var isPresentingAirportInfo: Bool = false
    var selectedAirportID: String?
    var isPresentingLayerControls: Bool = false
    var isPresentingNearestList: Bool = false
    var searchQuery: String = ""

    // MARK: - Map State

    var mapCenter: CLLocationCoordinate2D = .init(latitude: 39.0, longitude: -98.0)  // CONUS center
    var mapZoom: Double = 5.0  // CONUS zoom level
    var mapMode: MapMode = .northUp
    var mapStyle: MapStyle = .vfrSectional
    var visibleLayers: Set<MapLayer> = [.sectional, .airports, .ownship]
    var sectionalOpacity: Double = 0.70  // 70% default per user decision

    // MARK: - Location / Ownship State

    var ownshipPosition: CLLocation?
    var groundSpeed: Double = 0        // knots
    var altitude: Double = 0           // feet MSL
    var verticalSpeed: Double = 0      // feet per minute
    var track: Double = 0              // degrees true
    var gpsAvailable: Bool = false
    var firstLocationReceived: Bool = false  // prevents re-animation after initial GPS fix

    // MARK: - Flight Plan State (for instrument strip DTG/ETE)

    var activeFlightPlan: Bool = false
    var distanceToNext: Double?        // nautical miles
    var estimatedTimeEnroute: TimeInterval?  // seconds
    var directToAirport: Airport?
    var activePlanDeparture: String?     // ICAO of departure for summary card
    var activePlanDestination: String?   // ICAO of destination for summary card
    var activePlanFuelGallons: Double?   // Estimated fuel for summary card

    // MARK: - Profile State

    var activeAircraftProfileID: UUID?
    var activePilotProfileID: UUID?

    // MARK: - Shared Services (set by MapContainerView, used by other tabs)

    var sharedDatabaseService: (any DatabaseServiceProtocol)?
    var sharedMapService: MapService?

    // MARK: - System State

    var networkAvailable: Bool = false
    var batteryLevel: Double = 1.0
    var powerState: PowerState = .normal

    // MARK: - Init

    init() {
        // Default init -- services will be wired in later plans
    }
}
