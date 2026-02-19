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
        guard let db = aviationDB else { return [] }
        return try db.airspaces(containing: coordinate, altitude: altitude)
    }

    nonisolated func airspaces(near coordinate: CLLocationCoordinate2D, radiusNM: Double) async throws -> [Airspace] {
        guard let db = aviationDB else { return [] }
        return try db.airspaces(near: coordinate, radiusNM: radiusNM)
    }

    nonisolated func nearestAirports(to coordinate: CLLocationCoordinate2D, count: Int) async throws -> [Airport] {
        guard let db = aviationDB else { return [] }
        return try db.nearestAirports(to: coordinate, count: count)
    }

    // MARK: - Navaids

    nonisolated func navaid(byID id: String) async throws -> Navaid? {
        guard let db = aviationDB else { return nil }
        return try db.navaid(byID: id)
    }

    nonisolated func navaids(near coordinate: CLLocationCoordinate2D, radiusNM: Double) async throws -> [Navaid] {
        guard let db = aviationDB else { return [] }
        return try db.navaids(near: coordinate, radiusNM: radiusNM)
    }

    // MARK: - Weather Station Coordinate Resolution

    nonisolated func airportCoordinate(forStation stationID: String) async throws -> CLLocationCoordinate2D? {
        guard let db = aviationDB else { return nil }
        return try db.airportCoordinate(forStation: stationID)
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

    // MARK: - Seed Data

    nonisolated private static let seedDataLoadedKey = "com.efb212.seedDataLoaded"
    nonisolated private static let seedDataVersionKey = "com.efb212.seedDataVersion"
    nonisolated private static let currentSeedVersion = 3

    /// Whether seed data has already been loaded into the database.
    nonisolated var isSeedDataLoaded: Bool {
        UserDefaults.standard.bool(forKey: Self.seedDataLoadedKey)
            && UserDefaults.standard.integer(forKey: Self.seedDataVersionKey) >= Self.currentSeedVersion
    }

    /// Load bundled airport seed data into the aviation database.
    /// This is idempotent — it checks UserDefaults before inserting and skips
    /// if data for the current seed version is already present.
    nonisolated func loadSeedData() throws {
        guard let db = aviationDB else { return }
        guard !isSeedDataLoaded else { return }

        let airports = AirportSeedData.allAirports()
        try db.insertAirports(airports)

        let navaids = NavaidSeedData.allNavaids()
        try db.insertNavaids(navaids)

        let airspaces = AirspaceSeedData.allAirspaces()
        try db.insertAirspaces(airspaces)

        UserDefaults.standard.set(true, forKey: Self.seedDataLoadedKey)
        UserDefaults.standard.set(Self.currentSeedVersion, forKey: Self.seedDataVersionKey)

        let count = try db.airportCount()
        let airspaceCount = try db.airspaceCount()
        print("Loaded \(count) airports, \(navaids.count) navaids, and \(airspaceCount) airspaces from seed data (version \(Self.currentSeedVersion))")
    }

    /// Load seed data if it has not yet been loaded. Safe to call on every launch.
    nonisolated func loadSeedDataIfNeeded() {
        do {
            try loadSeedData()
        } catch {
            print("Failed to load seed data: \(error)")
        }
    }

    // MARK: - NASR Import

    nonisolated func importNASRData(from url: URL, progress: @escaping (Double) -> Void) async throws {
        // For now, importNASRData loads the bundled seed data.
        // Future: integrate SwiftNASR for full NASR data import from FAA distribution.
        progress(0.1)
        try loadSeedData()
        progress(1.0)
    }
}
