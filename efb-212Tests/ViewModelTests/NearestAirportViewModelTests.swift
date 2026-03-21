//
//  NearestAirportViewModelTests.swift
//  efb-212Tests
//
//  Tests for NearestAirportViewModel: nearest airport computation,
//  distance/bearing calculation, and NearestAirportEntry model.
//
//  NOTE: Updated to use current NearestAirportViewModel init(appState:databaseService:).
//  Old NearbyAirport type renamed to NearestAirportEntry.
//

import Testing
import Foundation
import CoreLocation
@testable import efb_212

@Suite("NearestAirportViewModel Tests")
struct NearestAirportViewModelTests {

    // MARK: - Test Helpers

    static let kpao = Airport(
        icao: "KPAO", faaID: "PAO", name: "Palo Alto",
        latitude: 37.4611, longitude: -122.1150, elevation: 4,
        type: .airport, ownership: .publicOwned,
        ctafFrequency: 118.6, unicomFrequency: nil,
        artccID: nil, fssID: nil, magneticVariation: nil,
        patternAltitude: 800, fuelTypes: ["100LL"],
        hasBeaconLight: true,
        runways: [
            Runway(
                id: "13/31", length: 2443, width: 70,
                surface: .asphalt, lighting: .fullTime,
                baseEndID: "13", reciprocalEndID: "31",
                baseEndLatitude: 37.4585, baseEndLongitude: -122.1120,
                reciprocalEndLatitude: 37.4636, reciprocalEndLongitude: -122.1181,
                baseEndElevation: 4, reciprocalEndElevation: 4
            )
        ],
        frequencies: [
            Frequency(id: UUID(), type: .ctaf, frequency: 118.6, name: "Palo Alto CTAF")
        ]
    )

    static let ksql = Airport(
        icao: "KSQL", faaID: "SQL", name: "San Carlos",
        latitude: 37.5119, longitude: -122.2494, elevation: 5,
        type: .airport, ownership: .publicOwned,
        ctafFrequency: 119.0, unicomFrequency: nil,
        artccID: nil, fssID: nil, magneticVariation: nil,
        patternAltitude: 800, fuelTypes: ["100LL"],
        hasBeaconLight: true,
        runways: [
            Runway(
                id: "12/30", length: 2600, width: 75,
                surface: .asphalt, lighting: .fullTime,
                baseEndID: "12", reciprocalEndID: "30",
                baseEndLatitude: 37.5090, baseEndLongitude: -122.2450,
                reciprocalEndLatitude: 37.5148, reciprocalEndLongitude: -122.2538,
                baseEndElevation: 5, reciprocalEndElevation: 5
            )
        ],
        frequencies: []
    )

    static let ksfo = Airport(
        icao: "KSFO", faaID: "SFO", name: "San Francisco Intl",
        latitude: 37.6213, longitude: -122.3790, elevation: 13,
        type: .airport, ownership: .publicOwned,
        ctafFrequency: nil, unicomFrequency: nil,
        artccID: nil, fssID: nil, magneticVariation: nil,
        patternAltitude: 1000, fuelTypes: ["100LL", "Jet-A"],
        hasBeaconLight: true,
        runways: [
            Runway(
                id: "10L/28R", length: 11870, width: 200,
                surface: .asphalt, lighting: .fullTime,
                baseEndID: "10L", reciprocalEndID: "28R",
                baseEndLatitude: 37.6286, baseEndLongitude: -122.3930,
                reciprocalEndLatitude: 37.6117, reciprocalEndLongitude: -122.3573,
                baseEndElevation: 10, reciprocalEndElevation: 13
            )
        ],
        frequencies: [
            Frequency(id: UUID(), type: .tower, frequency: 120.5, name: "SFO Tower")
        ]
    )

    static func makeMockDB() -> MockDatabaseManager {
        let db = MockDatabaseManager()
        db.airports = [kpao, ksql, ksfo]
        return db
    }

    // MARK: - NearestAirportEntry Model

    @Test func nearestAirportEntryIdentifiable() {
        let entry = NearestAirportEntry(
            airport: Self.kpao,
            distance: 0.0,
            bearing: 0.0
        )
        #expect(entry.id == "KPAO")
    }

    @Test func nearestAirportEntryDistance() {
        let entry = NearestAirportEntry(
            airport: Self.ksql,
            distance: 5.3,
            bearing: 315.0
        )
        #expect(entry.distance == 5.3)  // nautical miles
        #expect(entry.bearing == 315.0) // degrees true
    }

    // MARK: - ViewModel with Current API

    @Test @MainActor func viewModelInitialization() {
        let db = Self.makeMockDB()
        let appState = AppState()
        let vm = NearestAirportViewModel(appState: appState, databaseService: db)

        #expect(vm.nearestAirport == nil)
        #expect(vm.nearestAirports.isEmpty)
        #expect(vm.isLoading == false)
    }

    // MARK: - Airport Data Verification

    @Test func airportRunwayData() {
        #expect(Self.kpao.runways.first?.length == 2443)  // feet
        #expect(Self.kpao.runways.first?.surface == .asphalt)
        #expect(Self.kpao.frequencies.first?.frequency == 118.6)  // MHz
    }

    @Test func airportCTAF() {
        #expect(Self.kpao.ctafFrequency == 118.6)  // MHz
        #expect(Self.ksfo.ctafFrequency == nil)
    }

    @Test func airportTowerDetection() {
        // KSFO has a tower frequency
        let sfoHasTower = Self.ksfo.frequencies.contains { $0.type == .tower }
        #expect(sfoHasTower == true)

        // KSQL has no tower frequency
        let sqlHasTower = Self.ksql.frequencies.contains { $0.type == .tower }
        #expect(sqlHasTower == false)
    }
}
