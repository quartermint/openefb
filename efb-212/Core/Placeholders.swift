//
//  Placeholders.swift
//  efb-212
//
//  Minimal placeholder implementations of service protocols for DI.
//  These will be replaced by real implementations in later waves.
//  Since SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor, all types here are
//  MainActor by default. Protocols requiring Sendable need @unchecked Sendable.
//

import Foundation
import CoreLocation
import Combine

// MARK: - PlaceholderLocationManager

/// Stub location manager — returns nil location, no-op methods.
/// LocationManagerProtocol is AnyObject (not Sendable), so no @unchecked needed.
final class PlaceholderLocationManager: LocationManagerProtocol {

    var location: CLLocation? { nil }
    var heading: CLHeading? { nil }

    var locationPublisher: AnyPublisher<CLLocation, Never> {
        Empty<CLLocation, Never>().eraseToAnyPublisher()
    }

    func requestAuthorization() { /* no-op */ }
    func startUpdating() { /* no-op */ }
    func stopUpdating() { /* no-op */ }
}

// MARK: - PlaceholderDatabaseManager

/// Stub database manager — returns empty arrays, throws for mutations.
/// DatabaseManagerProtocol requires Sendable; this MainActor class uses @unchecked Sendable.
final class PlaceholderDatabaseManager: DatabaseManagerProtocol, @unchecked Sendable {

    func airport(byICAO icao: String) async throws -> Airport? { nil }

    func airports(near coordinate: CLLocationCoordinate2D, radiusNM: Double) async throws -> [Airport] { [] }

    func searchAirports(query: String, limit: Int) async throws -> [Airport] { [] }

    func airspaces(containing coordinate: CLLocationCoordinate2D, altitude: Double) async throws -> [Airspace] { [] }

    func airspaces(near coordinate: CLLocationCoordinate2D, radiusNM: Double) async throws -> [Airspace] { [] }

    func nearestAirports(to coordinate: CLLocationCoordinate2D, count: Int) async throws -> [Airport] { [] }

    func navaid(byID id: String) async throws -> Navaid? { nil }

    func navaids(near coordinate: CLLocationCoordinate2D, radiusNM: Double) async throws -> [Navaid] { [] }

    func airportCoordinate(forStation stationID: String) async throws -> CLLocationCoordinate2D? { nil }

    func cachedWeather(for stationID: String) async throws -> WeatherCache? { nil }

    func cacheWeather(_ weather: WeatherCache) async throws { /* no-op */ }

    func staleWeatherStations(olderThan interval: TimeInterval) async throws -> [String] { [] }

    func clearWeatherCache() async throws { /* no-op */ }

    func importNASRData(from url: URL, progress: @escaping (Double) -> Void) async throws {
        throw EFBError.nasrImportFailed(underlying: PlaceholderError.notImplemented)
    }

    func loadSeedDataIfNeeded() { /* no-op */ }
}

// MARK: - PlaceholderWeatherService

/// Stub weather service — returns empty data, throws for fetches.
/// WeatherServiceProtocol requires Sendable; this MainActor class uses @unchecked Sendable.
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

// MARK: - PlaceholderTFRService

/// Stub TFR service — returns empty array.
/// TFRServiceProtocol requires Sendable; this MainActor class uses @unchecked Sendable.
final class PlaceholderTFRService: TFRServiceProtocol, @unchecked Sendable {

    func fetchActiveTFRs(near coordinate: CLLocationCoordinate2D, radiusNM: Double) async throws -> [TFR] {
        []
    }
}

// MARK: - PlaceholderError

/// Simple error for placeholder "not implemented" cases.
nonisolated enum PlaceholderError: LocalizedError {
    case notImplemented

    var errorDescription: String? {
        "This feature is not yet implemented."
    }
}
