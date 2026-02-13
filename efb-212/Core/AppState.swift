//
//  AppState.swift
//  efb-212
//
//  Root state coordinator — ObservableObject injected as environmentObject.
//  All types are @MainActor by default (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor).
//

import SwiftUI
import Combine
import CoreLocation

final class AppState: ObservableObject {

    // MARK: - Navigation

    @Published var selectedTab: AppTab = .map
    @Published var isPresentingAirportInfo: Bool = false
    @Published var selectedAirportID: String?

    // MARK: - Map State

    @Published var mapCenter: CLLocationCoordinate2D = .init(latitude: 37.46, longitude: -122.12)
    @Published var mapZoom: Double = 10.0
    @Published var mapMode: MapMode = .northUp
    @Published var visibleLayers: Set<MapLayer> = [.sectional, .airports, .ownship]

    // MARK: - Location / Ownship

    @Published var ownshipPosition: CLLocation?
    @Published var groundSpeed: Double = 0        // knots
    @Published var altitude: Double = 0           // feet MSL
    @Published var verticalSpeed: Double = 0      // feet per minute
    @Published var track: Double = 0              // degrees true

    // MARK: - Recording (Phase 2 stub)

    @Published var isRecording: Bool = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var currentFlightPhase: String = "Idle"

    // MARK: - Flight Plan

    @Published var activeFlightPlan: FlightPlan?
    @Published var distanceToNext: Double?        // nautical miles
    @Published var estimatedTimeEnroute: TimeInterval?

    // MARK: - System

    @Published var batteryLevel: Double = 1.0
    @Published var powerState: PowerState = .normal
    @Published var gpsAvailable: Bool = false
    @Published var networkAvailable: Bool = false

    // MARK: - Injected Services (protocol-based DI)

    // LocationManagerProtocol is AnyObject (not Sendable), so nonisolated is fine
    nonisolated let locationManager: any LocationManagerProtocol
    nonisolated let databaseManager: any DatabaseManagerProtocol
    nonisolated let weatherService: any WeatherServiceProtocol

    /// PowerManager for battery monitoring — created internally.
    let powerManager = PowerManager()

    private var cancellables = Set<AnyCancellable>()

    /// 1 m/s = 1.94384 knots
    private static let metersPerSecondToKnots: Double = 1.94384

    /// 1 meter = 3.28084 feet
    private static let metersToFeet: Double = 3.28084

    // MARK: - Init

    init(
        locationManager: any LocationManagerProtocol,
        databaseManager: any DatabaseManagerProtocol,
        weatherService: any WeatherServiceProtocol
    ) {
        self.locationManager = locationManager
        self.databaseManager = databaseManager
        self.weatherService = weatherService

        // Load seed airports on launch (idempotent)
        databaseManager.loadSeedDataIfNeeded()

        subscribeToLocationUpdates()
        subscribeToPowerManager()
    }

    // MARK: - Location Subscription

    /// Subscribes to location updates and pipes aviation-unit values into published state.
    /// This drives the InstrumentStrip (GS, ALT, VS, TRK) in real-time.
    private func subscribeToLocationUpdates() {
        var previousLocation: CLLocation?

        locationManager.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self else { return }

                self.ownshipPosition = location
                self.gpsAvailable = true

                // Ground speed — knots
                if location.speed >= 0 {
                    self.groundSpeed = location.speed * Self.metersPerSecondToKnots
                }

                // Altitude — feet MSL
                self.altitude = location.altitude * Self.metersToFeet

                // Track — degrees true (CLLocation.course, -1 if invalid)
                if location.course >= 0 {
                    self.track = location.course
                }

                // Vertical speed — feet per minute from successive samples
                if let prev = previousLocation {
                    let timeDelta = location.timestamp.timeIntervalSince(prev.timestamp)
                    if timeDelta > 0.1 {
                        let altDeltaFeet = (location.altitude - prev.altitude) * Self.metersToFeet
                        self.verticalSpeed = (altDeltaFeet / timeDelta) * 60.0  // fpm
                    }
                }

                // Update map center to follow ownship
                self.mapCenter = location.coordinate

                previousLocation = location
            }
            .store(in: &cancellables)
    }

    // MARK: - Power Manager Subscription

    /// Subscribes to PowerManager to keep AppState battery level and power state current.
    private func subscribeToPowerManager() {
        powerManager.$batteryLevel
            .receive(on: DispatchQueue.main)
            .assign(to: &$batteryLevel)

        powerManager.$powerState
            .receive(on: DispatchQueue.main)
            .assign(to: &$powerState)
    }
}
