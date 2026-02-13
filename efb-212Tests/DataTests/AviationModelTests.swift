//
//  AviationModelTests.swift
//  efb-212Tests
//
//  Tests for aviation data model types: Airport, FlightPlan, WeatherCache, etc.
//

import Testing
import Foundation
import CoreLocation
@testable import efb_212

@Suite("Aviation Model Tests")
struct AviationModelTests {

    // MARK: - Test Helpers

    static func makeTestAirport(
        icao: String = "KPAO",
        name: String = "Palo Alto",
        latitude: Double = 37.4611,
        longitude: Double = -122.1150,
        elevation: Double = 4
    ) -> Airport {
        Airport(
            icao: icao,
            faaID: "PAO",
            name: name,
            latitude: latitude,
            longitude: longitude,
            elevation: elevation,
            type: .airport,
            ownership: .publicOwned,
            ctafFrequency: 118.6,
            unicomFrequency: nil,
            artccID: nil,
            fssID: nil,
            magneticVariation: nil,
            patternAltitude: 800,
            fuelTypes: ["100LL"],
            hasBeaconLight: true,
            runways: [],
            frequencies: []
        )
    }

    // MARK: - Airport Tests

    @Test func airportIdentity() {
        let airport = Self.makeTestAirport()
        #expect(airport.id == "KPAO")
        #expect(airport.icao == "KPAO")
        #expect(airport.name == "Palo Alto")
    }

    @Test func airportCoordinate() {
        let airport = Self.makeTestAirport()
        #expect(airport.coordinate.latitude == 37.4611)
        #expect(airport.coordinate.longitude == -122.1150)
    }

    @Test func airportEquality() {
        let airport1 = Self.makeTestAirport(icao: "KPAO")
        let airport2 = Self.makeTestAirport(icao: "KPAO", name: "Different Name")
        let airport3 = Self.makeTestAirport(icao: "KSQL")

        // Equality is based on ICAO only
        #expect(airport1 == airport2)
        #expect(airport1 != airport3)
    }

    @Test func airportHashing() {
        let airport1 = Self.makeTestAirport(icao: "KPAO")
        let airport2 = Self.makeTestAirport(icao: "KPAO", name: "Different Name")

        // Same ICAO should hash the same
        var set = Set<Airport>()
        set.insert(airport1)
        set.insert(airport2)
        #expect(set.count == 1)
    }

    @Test func airportProperties() {
        let airport = Self.makeTestAirport()
        #expect(airport.type == .airport)
        #expect(airport.ownership == .publicOwned)
        #expect(airport.ctafFrequency == 118.6)
        #expect(airport.elevation == 4)
        #expect(airport.patternAltitude == 800)
        #expect(airport.fuelTypes == ["100LL"])
        #expect(airport.hasBeaconLight == true)
    }

    // MARK: - FlightPlan Tests

    @Test func flightPlanCreation() {
        let plan = FlightPlan(departure: "KPAO", destination: "KSQL")
        #expect(plan.departure == "KPAO")
        #expect(plan.destination == "KSQL")
        #expect(plan.cruiseAltitude == 3000)    // default
        #expect(plan.cruiseSpeed == 100)        // default knots
        #expect(plan.waypoints.isEmpty)
        #expect(plan.totalDistance == 0)
        #expect(plan.estimatedTime == 0)
    }

    @Test func flightPlanCustomValues() {
        let plan = FlightPlan(
            departure: "KPAO",
            destination: "KOAK",
            cruiseAltitude: 5500,
            cruiseSpeed: 120,
            fuelBurnRate: 8.5,
            notes: "Bay tour"
        )
        #expect(plan.cruiseAltitude == 5500)
        #expect(plan.cruiseSpeed == 120)
        #expect(plan.fuelBurnRate == 8.5)
        #expect(plan.notes == "Bay tour")
    }

    @Test func flightPlanIdentifiable() {
        let plan1 = FlightPlan(departure: "KPAO", destination: "KSQL")
        let plan2 = FlightPlan(departure: "KPAO", destination: "KSQL")
        // Each plan should have a unique UUID
        #expect(plan1.id != plan2.id)
    }

    // MARK: - WeatherCache Tests

    @Test func weatherCacheFreshness() {
        let fresh = WeatherCache(stationID: "KPAO", fetchedAt: Date())
        #expect(!fresh.isStale)
    }

    @Test func weatherCacheStaleness() {
        let stale = WeatherCache(stationID: "KPAO", fetchedAt: Date(timeIntervalSinceNow: -7200))
        #expect(stale.isStale)
    }

    @Test func weatherCacheAge() {
        let twoHoursAgo = Date(timeIntervalSinceNow: -7200)
        let cache = WeatherCache(stationID: "KPAO", fetchedAt: twoHoursAgo)
        // Age should be approximately 7200 seconds (allow 5 second tolerance)
        #expect(cache.age > 7195)
        #expect(cache.age < 7210)
    }

    @Test func weatherCacheBoundary() {
        // Exactly at the stale boundary (3600 seconds = 60 minutes)
        let justFresh = WeatherCache(stationID: "KPAO", fetchedAt: Date(timeIntervalSinceNow: -3599))
        #expect(!justFresh.isStale)

        let justStale = WeatherCache(stationID: "KPAO", fetchedAt: Date(timeIntervalSinceNow: -3601))
        #expect(justStale.isStale)
    }

    @Test func weatherCacheDefaults() {
        let cache = WeatherCache(stationID: "KPAO")
        #expect(cache.stationID == "KPAO")
        #expect(cache.metar == nil)
        #expect(cache.taf == nil)
        #expect(cache.flightCategory == .vfr)   // default
        #expect(cache.temperature == nil)
        #expect(cache.wind == nil)
    }

    // MARK: - FlightCategory Tests

    @Test func flightCategoryColors() {
        #expect(FlightCategory.vfr.colorName == "green")
        #expect(FlightCategory.mvfr.colorName == "blue")
        #expect(FlightCategory.ifr.colorName == "red")
        #expect(FlightCategory.lifr.colorName == "magenta")
    }

    @Test func flightCategoryAllCases() {
        #expect(FlightCategory.allCases.count == 4)
    }

    // MARK: - BoundingBox Tests

    @Test func boundingBoxContains() {
        let box = BoundingBox(
            minLatitude: 37.0,
            maxLatitude: 38.0,
            minLongitude: -123.0,
            maxLongitude: -122.0
        )
        let inside = CLLocationCoordinate2D(latitude: 37.5, longitude: -122.5)
        let outside = CLLocationCoordinate2D(latitude: 36.0, longitude: -122.5)
        #expect(box.contains(inside))
        #expect(!box.contains(outside))
    }

    @Test func boundingBoxEdge() {
        let box = BoundingBox(
            minLatitude: 37.0,
            maxLatitude: 38.0,
            minLongitude: -123.0,
            maxLongitude: -122.0
        )
        // Points exactly on the boundary should be contained
        let onEdge = CLLocationCoordinate2D(latitude: 37.0, longitude: -123.0)
        #expect(box.contains(onEdge))
    }

    @Test func boundingBoxOutsideLongitude() {
        let box = BoundingBox(
            minLatitude: 37.0,
            maxLatitude: 38.0,
            minLongitude: -123.0,
            maxLongitude: -122.0
        )
        let outsideLon = CLLocationCoordinate2D(latitude: 37.5, longitude: -121.0)
        #expect(!box.contains(outsideLon))
    }

    // MARK: - Waypoint Tests

    @Test func waypointCreation() {
        let wp = Waypoint(
            identifier: "KPAO",
            name: "Palo Alto",
            latitude: 37.4611,
            longitude: -122.1150
        )
        #expect(wp.identifier == "KPAO")
        #expect(wp.name == "Palo Alto")
        #expect(wp.type == .airport)  // default
        #expect(wp.altitude == nil)   // default
        #expect(wp.coordinate.latitude == 37.4611)
    }

    // MARK: - WindInfo Tests

    @Test func windInfoEquality() {
        let wind1 = WindInfo(direction: 270, speed: 10, gusts: 20, isVariable: false)
        let wind2 = WindInfo(direction: 270, speed: 10, gusts: 20, isVariable: false)
        #expect(wind1 == wind2)
    }

    // MARK: - Enum Raw Values

    @Test func airportTypeRawValues() {
        #expect(AirportType.airport.rawValue == "airport")
        #expect(AirportType.heliport.rawValue == "heliport")
        #expect(AirportType.seaplane.rawValue == "seaplane")
        #expect(AirportType.ultralight.rawValue == "ultralight")
    }

    @Test func ownershipTypeRawValues() {
        #expect(OwnershipType.publicOwned.rawValue == "public")
        #expect(OwnershipType.privateOwned.rawValue == "private")
        #expect(OwnershipType.military.rawValue == "military")
    }

    @Test func airspaceClassAllCases() {
        #expect(AirspaceClass.allCases.count == 11)
        #expect(AirspaceClass.allCases.contains(.bravo))
        #expect(AirspaceClass.allCases.contains(.charlie))
        #expect(AirspaceClass.allCases.contains(.delta))
        #expect(AirspaceClass.allCases.contains(.tfr))
    }

    // MARK: - AppTab Tests

    @Test func appTabTitles() {
        #expect(AppTab.map.title == "Map")
        #expect(AppTab.flights.title == "Flights")
        #expect(AppTab.logbook.title == "Logbook")
        #expect(AppTab.aircraft.title == "Aircraft")
        #expect(AppTab.settings.title == "Settings")
    }

    @Test func appTabSystemImages() {
        #expect(AppTab.map.systemImage == "map")
        #expect(AppTab.flights.systemImage == "airplane")
        #expect(AppTab.settings.systemImage == "gear")
    }

    @Test func appTabAllCases() {
        #expect(AppTab.allCases.count == 5)
    }

    // MARK: - MapMode Tests

    @Test func mapModeValues() {
        #expect(MapMode.northUp.rawValue == "northUp")
        #expect(MapMode.trackUp.rawValue == "trackUp")
        #expect(MapMode.allCases.count == 2)
    }
}
