//
//  MockDatabaseManager.swift
//  efb-212Tests
//
//  Mock database service for testing components that depend on DatabaseServiceProtocol.
//

import Foundation
import CoreLocation
@testable import efb_212

final class MockDatabaseManager: DatabaseServiceProtocol, @unchecked Sendable {
    var airports: [Airport] = []
    var airspacesData: [Airspace] = []
    var navaids: [Navaid] = []

    func airport(byICAO icao: String) throws -> Airport? {
        airports.first { $0.icao == icao }
    }

    func airports(near coordinate: CLLocationCoordinate2D, radiusNM: Double) throws -> [Airport] {
        airports
    }

    func nearestAirports(to coordinate: CLLocationCoordinate2D, count: Int) throws -> [Airport] {
        Array(airports.prefix(count))
    }

    func searchAirports(query: String, limit: Int) throws -> [Airport] {
        airports.filter {
            $0.icao.contains(query.uppercased()) ||
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    func airspaces(near coordinate: CLLocationCoordinate2D, radiusNM: Double) throws -> [Airspace] {
        airspacesData
    }

    func navaids(near coordinate: CLLocationCoordinate2D, radiusNM: Double) throws -> [Navaid] {
        navaids
    }
}
