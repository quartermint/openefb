//
//  DatabaseManager.swift
//  efb-212
//
//  DatabaseServiceProtocol implementation that coordinates the GRDB aviation database.
//  Delegates all queries to AviationDatabase, propagating EFBError on failure.
//
//  Marked @unchecked Sendable because AviationDatabase (wrapping GRDB DatabasePool)
//  is inherently thread-safe.
//

import Foundation
import CoreLocation

final class DatabaseManager: DatabaseServiceProtocol, @unchecked Sendable {

    let aviationDB: AviationDatabase

    /// Initialize by creating an AviationDatabase instance.
    /// Throws EFBError.databaseCorrupted if the bundled database is missing.
    nonisolated init() throws {
        self.aviationDB = try AviationDatabase()
    }

    /// Internal init for testing with a pre-configured AviationDatabase.
    nonisolated init(aviationDB: AviationDatabase) {
        self.aviationDB = aviationDB
    }

    // MARK: - DatabaseServiceProtocol

    nonisolated func airport(byICAO icao: String) throws -> Airport? {
        try aviationDB.airport(byICAO: icao)
    }

    nonisolated func airports(near coordinate: CLLocationCoordinate2D, radiusNM: Double) throws -> [Airport] {
        try aviationDB.airports(near: coordinate, radiusNM: radiusNM)
    }

    nonisolated func nearestAirports(to coordinate: CLLocationCoordinate2D, count: Int) throws -> [Airport] {
        try aviationDB.nearestAirports(to: coordinate, count: count)
    }

    nonisolated func searchAirports(query: String, limit: Int) throws -> [Airport] {
        try aviationDB.searchAirports(query: query, limit: limit)
    }

    nonisolated func airspaces(near coordinate: CLLocationCoordinate2D, radiusNM: Double) throws -> [Airspace] {
        try aviationDB.airspaces(near: coordinate, radiusNM: radiusNM)
    }

    nonisolated func navaids(near coordinate: CLLocationCoordinate2D, radiusNM: Double) throws -> [Navaid] {
        try aviationDB.navaids(near: coordinate, radiusNM: radiusNM)
    }
}
