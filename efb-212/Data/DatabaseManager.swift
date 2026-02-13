//
//  DatabaseManager.swift
//  efb-212
//
//  Coordinator for the dual database architecture:
//  - GRDB (AviationDatabase) for aviation data (airports, navaids, airspace, weather cache)
//  - SwiftData for user data (profiles, flights, settings)
//
//  Implements DatabaseManagerProtocol. All methods are nonisolated since
//  the protocol is Sendable and GRDB operations are not MainActor-isolated.
//

import Foundation
import CoreLocation

final class DatabaseManager: DatabaseManagerProtocol, @unchecked Sendable {
    private let aviationDB: AviationDatabase?

    // MARK: - Init

    nonisolated init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let dbPath = appSupport.appendingPathComponent("aviation.sqlite").path

        do {
            try FileManager.default.createDirectory(
                at: appSupport,
                withIntermediateDirectories: true
            )
            self.aviationDB = try AviationDatabase(path: dbPath)
        } catch {
            print("Failed to initialize aviation database: \(error)")
            self.aviationDB = nil
        }
    }

    /// Internal initializer for testing with a pre-configured database.
    nonisolated init(aviationDatabase: AviationDatabase?) {
        self.aviationDB = aviationDatabase
    }

    // MARK: - Aviation Data (GRDB)

    nonisolated func airport(byICAO icao: String) async throws -> Airport? {
        guard let db = aviationDB else { return nil }
        return try db.airport(byICAO: icao)
    }

    nonisolated func airports(near coordinate: CLLocationCoordinate2D, radiusNM: Double) async throws -> [Airport] {
        guard let db = aviationDB else { return [] }
        return try db.airports(near: coordinate, radiusNM: radiusNM)
    }

    nonisolated func searchAirports(query: String, limit: Int) async throws -> [Airport] {
        guard let db = aviationDB else { return [] }
        return try db.searchAirports(query: query, limit: limit)
    }

    nonisolated func airspaces(containing coordinate: CLLocationCoordinate2D, altitude: Double) async throws -> [Airspace] {
        // Airspace queries not yet implemented — requires geometry processing
        return []
    }

    nonisolated func nearestAirports(to coordinate: CLLocationCoordinate2D, count: Int) async throws -> [Airport] {
        guard let db = aviationDB else { return [] }
        return try db.nearestAirports(to: coordinate, count: count)
    }

    // MARK: - Weather Cache (ephemeral GRDB)

    nonisolated func cachedWeather(for stationID: String) async throws -> WeatherCache? {
        guard let db = aviationDB else { return nil }
        return try db.cachedWeather(for: stationID)
    }

    nonisolated func cacheWeather(_ weather: WeatherCache) async throws {
        guard let db = aviationDB else { return }
        try db.cacheWeather(weather)
    }

    nonisolated func staleWeatherStations(olderThan interval: TimeInterval) async throws -> [String] {
        guard let db = aviationDB else { return [] }
        return try db.staleWeatherStations(olderThan: interval)
    }

    nonisolated func clearWeatherCache() async throws {
        guard let db = aviationDB else { return }
        try db.clearWeatherCache()
    }

    // MARK: - NASR Import

    nonisolated func importNASRData(from url: URL, progress: @escaping (Double) -> Void) async throws {
        // NASR import will be implemented when SwiftNASR integration is added.
        // This is a placeholder that reports completion immediately.
        progress(1.0)
    }
}
