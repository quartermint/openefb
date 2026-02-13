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

    // MARK: - Init

    init(
        locationManager: any LocationManagerProtocol,
        databaseManager: any DatabaseManagerProtocol,
        weatherService: any WeatherServiceProtocol
    ) {
        self.locationManager = locationManager
        self.databaseManager = databaseManager
        self.weatherService = weatherService
    }
}
