//
//  NearestAirportViewModelTests.swift
//  efb-212Tests
//
//  Tests for NearestAirportViewModel: fetching nearest airports,
//  distance/bearing computation, runway/frequency extraction, and GPS state.
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

    static func makeMockLocation() -> MockLocationManager {
        let loc = MockLocationManager()
        return loc
    }

    // MARK: - Fetch Nearest Airports

    @Test func fetchNearestAirportsPopulatesList() async {
        let db = Self.makeMockDB()
        let loc = Self.makeMockLocation()
        let vm = NearestAirportViewModel(databaseManager: db, locationManager: loc)

        let paoLocation = CLLocation(latitude: 37.4611, longitude: -122.1150)
        await vm.fetchNearestAirports(from: paoLocation)

        #expect(!vm.nearestAirports.isEmpty)
        #expect(vm.nearestAirports.count == 3) // Mock returns all airports up to count
        #expect(!vm.isLoading)
        #expect(vm.lastError == nil)
    }

    @Test func fetchNearestAirportsComputesDistance() async {
        let db = Self.makeMockDB()
        let loc = Self.makeMockLocation()
        let vm = NearestAirportViewModel(databaseManager: db, locationManager: loc)

        let paoLocation = CLLocation(latitude: 37.4611, longitude: -122.1150)
        await vm.fetchNearestAirports(from: paoLocation)

        // Find KPAO in results — should be at distance ~0
        let paoResult = vm.nearestAirports.first(where: { $0.airport.icao == "KPAO" })
        #expect(paoResult != nil)
        #expect(paoResult!.distanceNM < 0.1, "KPAO distance from itself should be ~0 NM")
    }

    @Test func fetchNearestAirportsComputesBearing() async {
        let db = Self.makeMockDB()
        let loc = Self.makeMockLocation()
        let vm = NearestAirportViewModel(databaseManager: db, locationManager: loc)

        let paoLocation = CLLocation(latitude: 37.4611, longitude: -122.1150)
        await vm.fetchNearestAirports(from: paoLocation)

        // Find KSQL bearing from KPAO — KSQL is northwest of KPAO
        let sqlResult = vm.nearestAirports.first(where: { $0.airport.icao == "KSQL" })
        #expect(sqlResult != nil)
        // Bearing should be between 0 and 360
        #expect(sqlResult!.bearingTrue >= 0 && sqlResult!.bearingTrue <= 360)
    }

    @Test func fetchNearestAirportsExtractsRunwayInfo() async {
        let db = Self.makeMockDB()
        let loc = Self.makeMockLocation()
        let vm = NearestAirportViewModel(databaseManager: db, locationManager: loc)

        let paoLocation = CLLocation(latitude: 37.4611, longitude: -122.1150)
        await vm.fetchNearestAirports(from: paoLocation)

        let paoResult = vm.nearestAirports.first(where: { $0.airport.icao == "KPAO" })
        #expect(paoResult?.longestRunwayLength == 2443) // feet
        #expect(paoResult?.longestRunwaySurface == .asphalt)
    }

    @Test func fetchNearestAirportsExtractsCTAF() async {
        let db = Self.makeMockDB()
        let loc = Self.makeMockLocation()
        let vm = NearestAirportViewModel(databaseManager: db, locationManager: loc)

        let paoLocation = CLLocation(latitude: 37.4611, longitude: -122.1150)
        await vm.fetchNearestAirports(from: paoLocation)

        let paoResult = vm.nearestAirports.first(where: { $0.airport.icao == "KPAO" })
        #expect(paoResult?.ctafFrequency == 118.6) // MHz
    }

    @Test func fetchNearestAirportsDetectsTowered() async {
        let db = Self.makeMockDB()
        let loc = Self.makeMockLocation()
        let vm = NearestAirportViewModel(databaseManager: db, locationManager: loc)

        let paoLocation = CLLocation(latitude: 37.4611, longitude: -122.1150)
        await vm.fetchNearestAirports(from: paoLocation)

        // KSFO has a tower frequency, so isTowered should be true
        let sfoResult = vm.nearestAirports.first(where: { $0.airport.icao == "KSFO" })
        #expect(sfoResult?.isTowered == true)

        // KSQL has no tower frequency, so isTowered should be false
        let sqlResult = vm.nearestAirports.first(where: { $0.airport.icao == "KSQL" })
        #expect(sqlResult?.isTowered == false)
    }

    // MARK: - GPS State

    @Test func initialGPSStateIsFalse() {
        let db = Self.makeMockDB()
        let loc = Self.makeMockLocation()
        let vm = NearestAirportViewModel(databaseManager: db, locationManager: loc)

        #expect(vm.hasGPS == false)
    }

    @Test func refreshWithNoLocationSetsNoGPS() async {
        let db = Self.makeMockDB()
        let loc = Self.makeMockLocation()
        // loc.location is nil by default
        let vm = NearestAirportViewModel(databaseManager: db, locationManager: loc)

        await vm.refresh()

        #expect(vm.hasGPS == false)
        #expect(vm.nearestAirports.isEmpty)
    }

    @Test func refreshWithLocationSetsGPSTrue() async {
        let db = Self.makeMockDB()
        let loc = Self.makeMockLocation()
        loc.location = CLLocation(latitude: 37.4611, longitude: -122.1150)
        let vm = NearestAirportViewModel(databaseManager: db, locationManager: loc)

        await vm.refresh()

        #expect(vm.hasGPS == true)
        #expect(!vm.nearestAirports.isEmpty)
    }

    // MARK: - Empty Results

    @Test func fetchWithEmptyDBReturnsEmpty() async {
        let db = MockDatabaseManager()
        db.airports = []
        let loc = Self.makeMockLocation()
        let vm = NearestAirportViewModel(databaseManager: db, locationManager: loc)

        let location = CLLocation(latitude: 37.4611, longitude: -122.1150)
        await vm.fetchNearestAirports(from: location)

        #expect(vm.nearestAirports.isEmpty)
        #expect(vm.lastError == nil)
    }

    // MARK: - NearbyAirport Model

    @Test func nearbyAirportIdentifiable() {
        let nearby = NearbyAirport(
            airport: Self.kpao,
            distanceNM: 0.0,
            bearingTrue: 0.0,
            longestRunwayLength: 2443,
            longestRunwaySurface: .asphalt,
            ctafFrequency: 118.6,
            isTowered: false
        )
        #expect(nearby.id == "KPAO")
    }

    @Test func nearbyAirportWithNilRunway() {
        // Airport with no runways
        let noRunwayAirport = Airport(
            icao: "KTST", faaID: "TST", name: "Test Airport",
            latitude: 37.0, longitude: -122.0, elevation: 100,
            type: .airport, ownership: .publicOwned,
            ctafFrequency: nil, unicomFrequency: nil,
            artccID: nil, fssID: nil, magneticVariation: nil,
            patternAltitude: nil, fuelTypes: [],
            hasBeaconLight: false, runways: [], frequencies: []
        )
        let nearby = NearbyAirport(
            airport: noRunwayAirport,
            distanceNM: 5.0,
            bearingTrue: 180.0,
            longestRunwayLength: nil,
            longestRunwaySurface: nil,
            ctafFrequency: nil,
            isTowered: false
        )
        #expect(nearby.longestRunwayLength == nil)
        #expect(nearby.longestRunwaySurface == nil)
        #expect(nearby.ctafFrequency == nil)
    }

    // MARK: - Distance Calculation Accuracy

    @Test func distanceBetweenKnownAirports() async {
        let db = Self.makeMockDB()
        let loc = Self.makeMockLocation()
        let vm = NearestAirportViewModel(databaseManager: db, locationManager: loc)

        // Fetch from KPAO location
        let paoLocation = CLLocation(latitude: 37.4611, longitude: -122.1150)
        await vm.fetchNearestAirports(from: paoLocation)

        // KSQL is approximately 5-8 NM from KPAO
        let sqlResult = vm.nearestAirports.first(where: { $0.airport.icao == "KSQL" })
        #expect(sqlResult != nil)
        #expect(sqlResult!.distanceNM > 3.0, "KSQL should be at least 3 NM from KPAO")
        #expect(sqlResult!.distanceNM < 10.0, "KSQL should be less than 10 NM from KPAO")
    }

    // MARK: - Loading State

    @Test func isLoadingFalseAfterFetch() async {
        let db = Self.makeMockDB()
        let loc = Self.makeMockLocation()
        let vm = NearestAirportViewModel(databaseManager: db, locationManager: loc)

        let location = CLLocation(latitude: 37.4611, longitude: -122.1150)
        await vm.fetchNearestAirports(from: location)

        #expect(!vm.isLoading)
    }
}
