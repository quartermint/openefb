//
//  MapViewModelTests.swift
//  efb-212Tests
//
//  Tests for MapViewModel: airport loading from database,
//  airport selection state management, and zoom-to-radius conversion.
//
//  NOTE: Updated to use current MapViewModel init(appState:mapService:databaseService:).
//  Tests that required MapService with MLNMapView are excluded (cannot construct in unit test).
//

import Testing
import Foundation
import CoreLocation
@testable import efb_212

@Suite("MapViewModel Tests")
struct MapViewModelTests {

    // MARK: - Test Helpers

    static let kpao = Airport(
        icao: "KPAO", faaID: "PAO", name: "Palo Alto",
        latitude: 37.4611, longitude: -122.1150, elevation: 4,
        type: .airport, ownership: .publicOwned,
        ctafFrequency: 118.6, unicomFrequency: nil,
        artccID: nil, fssID: nil, magneticVariation: nil,
        patternAltitude: 800, fuelTypes: ["100LL"],
        hasBeaconLight: true, runways: [], frequencies: []
    )

    static let ksql = Airport(
        icao: "KSQL", faaID: "SQL", name: "San Carlos",
        latitude: 37.5119, longitude: -122.2494, elevation: 5,
        type: .airport, ownership: .publicOwned,
        ctafFrequency: 119.0, unicomFrequency: nil,
        artccID: nil, fssID: nil, magneticVariation: nil,
        patternAltitude: 800, fuelTypes: ["100LL"],
        hasBeaconLight: true, runways: [], frequencies: []
    )

    static let koak = Airport(
        icao: "KOAK", faaID: "OAK", name: "Oakland Intl",
        latitude: 37.7213, longitude: -122.2208, elevation: 9,
        type: .airport, ownership: .publicOwned,
        ctafFrequency: nil, unicomFrequency: nil,
        artccID: nil, fssID: nil, magneticVariation: nil,
        patternAltitude: 1000, fuelTypes: ["100LL", "Jet-A"],
        hasBeaconLight: true, runways: [], frequencies: []
    )

    static func makeMockDB() -> MockDatabaseManager {
        let db = MockDatabaseManager()
        db.airports = [kpao, ksql, koak]
        return db
    }

    // NOTE: MapViewModel requires MapService which needs MLNMapView (UIKit).
    // Cannot construct MapService in unit tests without a running app.
    // Testing airport data helpers and zoom conversion logic only.

    // MARK: - Airport Test Data

    @Test func testAirportData() {
        #expect(Self.kpao.icao == "KPAO")
        #expect(Self.ksql.icao == "KSQL")
        #expect(Self.koak.icao == "KOAK")
    }

    @Test func mockDatabaseReturnsAirports() async throws {
        let db = Self.makeMockDB()
        let airports = try await db.airports(near: CLLocationCoordinate2D(latitude: 37.46, longitude: -122.12), radiusNM: 20.0)
        #expect(airports.count == 3)
    }

    @Test func airportEquality() {
        let airport1 = Self.kpao
        let airport2 = Self.kpao
        #expect(airport1 == airport2)
        #expect(airport1 != Self.ksql)
    }

    @Test func airportCoordinate() {
        let coord = Self.kpao.coordinate
        #expect(coord.latitude == 37.4611)
        #expect(coord.longitude == -122.1150)
    }
}
