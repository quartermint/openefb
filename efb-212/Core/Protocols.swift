//
//  Protocols.swift
//  efb-212
//
//  All service protocols for dependency injection and testability.
//  Each protocol defines a contract; placeholder implementations
//  provide no-op/empty defaults for previews and initial launch.
//

import Foundation
import CoreLocation

// MARK: - Database Service Protocol

protocol DatabaseServiceProtocol: Sendable {
    /// Fetch a single airport by ICAO identifier.
    func airport(byICAO icao: String) throws -> Airport?

    /// Fetch airports within a radius of a coordinate.
    func airports(near coordinate: CLLocationCoordinate2D, radiusNM: Double) throws -> [Airport]

    /// Fetch the N nearest airports to a coordinate, sorted by distance.
    func nearestAirports(to coordinate: CLLocationCoordinate2D, count: Int) throws -> [Airport]

    /// Search airports by identifier, name, or city.
    func searchAirports(query: String, limit: Int) throws -> [Airport]

    /// Fetch airspaces within a radius of a coordinate.
    func airspaces(near coordinate: CLLocationCoordinate2D, radiusNM: Double) throws -> [Airspace]

    /// Fetch navaids within a radius of a coordinate.
    func navaids(near coordinate: CLLocationCoordinate2D, radiusNM: Double) throws -> [Navaid]
}

// MARK: - Location Service Protocol

protocol LocationServiceProtocol: Sendable {
    /// Whether the service is actively tracking location.
    var isTracking: Bool { get }

    /// Start GPS tracking and location updates.
    func startTracking() async

    /// Stop GPS tracking.
    func stopTracking()
}

// MARK: - Weather Service Protocol

protocol WeatherServiceProtocol: Sendable {
    /// Fetch METAR weather for a station.
    func fetchMETAR(for stationID: String) async throws -> WeatherCache

    /// Fetch TAF forecast for a station.
    func fetchTAF(for stationID: String) async throws -> String

    /// Fetch weather for multiple stations in batch.
    func fetchWeatherForStations(_ stationIDs: [String]) async throws -> [WeatherCache]

    /// Return cached weather if available (no network fetch).
    func cachedWeather(for stationID: String) -> WeatherCache?
}

// MARK: - TFR Service Protocol

protocol TFRServiceProtocol: Sendable {
    /// Fetch TFRs near a coordinate within the given radius.
    func fetchTFRs(near coordinate: CLLocationCoordinate2D, radiusNM: Double) async throws -> [TFR]

    /// Fetch all currently active TFRs.
    func activeTFRs() async throws -> [TFR]
}

// MARK: - Reachability Service Protocol

protocol ReachabilityServiceProtocol: Sendable {
    /// Whether the device has a network connection.
    var isConnected: Bool { get }

    /// Whether the connection is expensive (cellular).
    var isExpensive: Bool { get }

    /// Start monitoring network status.
    func start()

    /// Stop monitoring network status.
    func stop()
}

// MARK: - Chart Service Protocol

protocol ChartServiceProtocol: Sendable {
    /// Download a chart region's tiles.
    func downloadChart(region: ChartRegion) async throws

    /// Return all available chart regions (from server manifest).
    func availableRegions() -> [ChartRegion]

    /// Return chart regions that have been downloaded to device.
    func downloadedRegions() -> [ChartRegion]
}

// MARK: - Placeholder Implementations

/// Placeholder database service -- returns empty results for all queries.
/// Used for SwiftUI previews and initial app launch before real services are wired.
final class PlaceholderDatabaseService: DatabaseServiceProtocol, @unchecked Sendable {
    func airport(byICAO icao: String) throws -> Airport? { nil }
    func airports(near coordinate: CLLocationCoordinate2D, radiusNM: Double) throws -> [Airport] { [] }
    func nearestAirports(to coordinate: CLLocationCoordinate2D, count: Int) throws -> [Airport] { [] }
    func searchAirports(query: String, limit: Int) throws -> [Airport] { [] }
    func airspaces(near coordinate: CLLocationCoordinate2D, radiusNM: Double) throws -> [Airspace] { [] }
    func navaids(near coordinate: CLLocationCoordinate2D, radiusNM: Double) throws -> [Navaid] { [] }
}

/// Placeholder location service -- no-op tracking.
final class PlaceholderLocationService: LocationServiceProtocol, @unchecked Sendable {
    var isTracking: Bool { false }
    func startTracking() async { /* no-op */ }
    func stopTracking() { /* no-op */ }
}

/// Placeholder weather service -- returns empty/error for all fetches.
final class PlaceholderWeatherService: WeatherServiceProtocol, @unchecked Sendable {
    func fetchMETAR(for stationID: String) async throws -> WeatherCache {
        throw EFBError.weatherFetchFailed(underlying: PlaceholderError.notImplemented)
    }
    func fetchTAF(for stationID: String) async throws -> String {
        throw EFBError.weatherFetchFailed(underlying: PlaceholderError.notImplemented)
    }
    func fetchWeatherForStations(_ stationIDs: [String]) async throws -> [WeatherCache] {
        throw EFBError.weatherFetchFailed(underlying: PlaceholderError.notImplemented)
    }
    func cachedWeather(for stationID: String) -> WeatherCache? { nil }
}

/// Placeholder TFR service -- returns empty results.
final class PlaceholderTFRService: TFRServiceProtocol, @unchecked Sendable {
    func fetchTFRs(near coordinate: CLLocationCoordinate2D, radiusNM: Double) async throws -> [TFR] { [] }
    func activeTFRs() async throws -> [TFR] { [] }
}

/// Placeholder reachability service -- reports no connection.
final class PlaceholderReachabilityService: ReachabilityServiceProtocol, @unchecked Sendable {
    var isConnected: Bool { false }
    var isExpensive: Bool { false }
    func start() { /* no-op */ }
    func stop() { /* no-op */ }
}

// MARK: - Placeholder Error

/// Simple error for placeholder "not implemented" cases.
nonisolated enum PlaceholderError: LocalizedError {
    case notImplemented

    var errorDescription: String? {
        "This feature is not yet implemented."
    }
}
