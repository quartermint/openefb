//
//  MockDatabaseManager.swift
//  efb-212Tests
//
//  Mock database manager for testing components that depend on DatabaseManagerProtocol.
//

import Foundation
import CoreLocation
@testable import efb_212

final class MockDatabaseManager: DatabaseManagerProtocol, @unchecked Sendable {
    var airports: [Airport] = []
    var weatherCache: [String: WeatherCache] = [:]

    func airport(byICAO icao: String) async throws -> Airport? {
        airports.first { $0.icao == icao }
    }

    func airports(near coordinate: CLLocationCoordinate2D, radiusNM: Double) async throws -> [Airport] {
        airports
    }

    func searchAirports(query: String, limit: Int) async throws -> [Airport] {
        airports.filter {
            $0.icao.contains(query.uppercased()) ||
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    func airspaces(containing coordinate: CLLocationCoordinate2D, altitude: Double) async throws -> [Airspace] {
        []
    }

    func nearestAirports(to coordinate: CLLocationCoordinate2D, count: Int) async throws -> [Airport] {
        Array(airports.prefix(count))
    }

    // Navaids
    var navaids: [Navaid] = []

    func navaid(byID id: String) async throws -> Navaid? {
        navaids.first { $0.id == id }
    }

    func navaids(near coordinate: CLLocationCoordinate2D, radiusNM: Double) async throws -> [Navaid] {
        navaids
    }

    // Weather station coordinate resolution
    func airportCoordinate(forStation stationID: String) async throws -> CLLocationCoordinate2D? {
        airports.first { $0.icao == stationID }.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
    }

    func cachedWeather(for stationID: String) async throws -> WeatherCache? {
        weatherCache[stationID]
    }

    func cacheWeather(_ weather: WeatherCache) async throws {
        weatherCache[weather.stationID] = weather
    }

    func staleWeatherStations(olderThan interval: TimeInterval) async throws -> [String] {
        []
    }

    func clearWeatherCache() async throws {
        weatherCache.removeAll()
    }

    func importNASRData(from url: URL, progress: @escaping (Double) -> Void) async throws {
        // no-op for tests
    }

    func loadSeedDataIfNeeded() {
        // no-op for tests
    }
}
