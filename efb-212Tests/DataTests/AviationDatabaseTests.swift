//
//  AviationDatabaseTests.swift
//  efb-212Tests
//
//  Tests for AviationDatabase spatial queries, FTS5 search, and weather cache.
//  Uses an in-memory GRDB database (via temporary file) to validate
//  R-tree spatial indexing and full-text search behavior.
//

import Testing
import Foundation
import CoreLocation
@testable import efb_212

@Suite("AviationDatabase Tests", .serialized)
struct AviationDatabaseTests {

    // MARK: - Test Helpers

    /// Create a temporary on-disk database (GRDB DatabasePool requires a file path).
    static func makeTempDB() throws -> AviationDatabase {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test-\(UUID().uuidString).sqlite").path
        return try AviationDatabase(path: dbPath)
    }

    static func makeTestAirport(
        icao: String = "KPAO",
        faaID: String? = "PAO",
        name: String = "Palo Alto",
        latitude: Double = 37.4611,
        longitude: Double = -122.1150,
        elevation: Double = 4,
        runways: [Runway] = [],
        frequencies: [Frequency] = []
    ) -> Airport {
        Airport(
            icao: icao,
            faaID: faaID,
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
            runways: runways,
            frequencies: frequencies
        )
    }

    /// Bay Area test airports with known positions.
    static let kpao = makeTestAirport(icao: "KPAO", name: "Palo Alto", latitude: 37.4611, longitude: -122.1150)
    static let ksql = makeTestAirport(icao: "KSQL", faaID: "SQL", name: "San Carlos", latitude: 37.5119, longitude: -122.2494)
    static let koak = makeTestAirport(icao: "KOAK", faaID: "OAK", name: "Oakland Intl", latitude: 37.7213, longitude: -122.2208)
    static let ksfo = makeTestAirport(icao: "KSFO", faaID: "SFO", name: "San Francisco Intl", latitude: 37.6213, longitude: -122.3790)
    static let ksjc = makeTestAirport(icao: "KSJC", faaID: "SJC", name: "San Jose Intl", latitude: 37.3626, longitude: -121.9291)

    /// A far-away airport (New York) for distance filtering tests.
    static let kjfk = makeTestAirport(icao: "KJFK", faaID: "JFK", name: "John F Kennedy Intl", latitude: 40.6413, longitude: -73.7781)

    // MARK: - Insert & Count

    @Test func insertAndCount() throws {
        let db = try Self.makeTempDB()
        #expect(try db.airportCount() == 0)

        try db.insertAirport(Self.kpao)
        #expect(try db.airportCount() == 1)

        try db.insertAirport(Self.ksql)
        #expect(try db.airportCount() == 2)
    }

    @Test func bulkInsert() throws {
        let db = try Self.makeTempDB()
        let airports = [Self.kpao, Self.ksql, Self.koak, Self.ksfo, Self.ksjc]
        try db.insertAirports(airports)
        #expect(try db.airportCount() == 5)
    }

    @Test func insertOrReplaceOverwrites() throws {
        let db = try Self.makeTempDB()
        try db.insertAirport(Self.kpao)
        #expect(try db.airportCount() == 1)

        // Insert same ICAO with different name
        let modified = Self.makeTestAirport(icao: "KPAO", name: "Palo Alto Modified")
        try db.insertAirport(modified)
        #expect(try db.airportCount() == 1)

        let fetched = try db.airport(byICAO: "KPAO")
        #expect(fetched?.name == "Palo Alto Modified")
    }

    // MARK: - Lookup by ICAO

    @Test func lookupByICAO() throws {
        let db = try Self.makeTempDB()
        try db.insertAirports([Self.kpao, Self.ksql])

        let found = try db.airport(byICAO: "KPAO")
        #expect(found != nil)
        #expect(found?.icao == "KPAO")
        #expect(found?.name == "Palo Alto")
        #expect(found?.latitude == 37.4611)
    }

    @Test func lookupByICAONotFound() throws {
        let db = try Self.makeTempDB()
        try db.insertAirport(Self.kpao)

        let notFound = try db.airport(byICAO: "KXYZ")
        #expect(notFound == nil)
    }

    // MARK: - Nearest Airports (R-tree spatial query + distance sort)

    @Test func nearestAirportsSortedByDistance() throws {
        let db = try Self.makeTempDB()
        try db.insertAirports([Self.kpao, Self.ksql, Self.koak, Self.ksfo, Self.ksjc, Self.kjfk])

        // Query from KPAO's location — nearest airports should be sorted by distance
        let paoCoord = CLLocationCoordinate2D(latitude: 37.4611, longitude: -122.1150)
        let nearest = try db.nearestAirports(to: paoCoord, count: 3)

        #expect(nearest.count == 3)
        // First result should be KPAO itself (distance 0)
        #expect(nearest[0].icao == "KPAO")

        // Verify all returned airports are closer than omitted ones
        let paoLocation = CLLocation(latitude: 37.4611, longitude: -122.1150)
        var prevDistance: Double = -1
        for airport in nearest {
            let dist = paoLocation.distance(from: CLLocation(latitude: airport.latitude, longitude: airport.longitude))
            #expect(dist >= prevDistance, "Airports should be sorted by ascending distance")
            prevDistance = dist
        }
    }

    @Test func nearestAirportsLimitWorks() throws {
        let db = try Self.makeTempDB()
        try db.insertAirports([Self.kpao, Self.ksql, Self.koak, Self.ksfo, Self.ksjc])

        let paoCoord = CLLocationCoordinate2D(latitude: 37.4611, longitude: -122.1150)
        let nearest = try db.nearestAirports(to: paoCoord, count: 2)
        #expect(nearest.count == 2)
    }

    @Test func nearestAirportsExcludesFarAway() throws {
        let db = try Self.makeTempDB()
        try db.insertAirports([Self.kpao, Self.kjfk])

        // Query from KPAO — JFK is ~2250 NM away, outside the 50 NM R-tree box
        let paoCoord = CLLocationCoordinate2D(latitude: 37.4611, longitude: -122.1150)
        let nearest = try db.nearestAirports(to: paoCoord, count: 10)

        // JFK should not be in the result set because it is outside the 50 NM bounding box
        let icaos = nearest.map(\.icao)
        #expect(!icaos.contains("KJFK"))
        #expect(icaos.contains("KPAO"))
    }

    // MARK: - Airports Within Radius (R-tree bounding box query)

    @Test func airportsWithinRadius() throws {
        let db = try Self.makeTempDB()
        try db.insertAirports([Self.kpao, Self.ksql, Self.koak, Self.ksfo, Self.ksjc, Self.kjfk])

        // 20 NM radius from KPAO — should include nearby Bay Area airports
        let paoCoord = CLLocationCoordinate2D(latitude: 37.4611, longitude: -122.1150)
        let results = try db.airports(near: paoCoord, radiusNM: 20.0)

        let icaos = Set(results.map(\.icao))
        // KPAO, KSQL, KSFO, KOAK, KSJC are all within ~20 NM of each other
        #expect(icaos.contains("KPAO"))
        #expect(icaos.contains("KSQL"))
        // JFK should not be included
        #expect(!icaos.contains("KJFK"))
    }

    @Test func airportsWithinSmallRadius() throws {
        let db = try Self.makeTempDB()
        try db.insertAirports([Self.kpao, Self.ksql, Self.koak, Self.kjfk])

        // 5 NM radius from KPAO — should include KSQL but possibly not KOAK
        let paoCoord = CLLocationCoordinate2D(latitude: 37.4611, longitude: -122.1150)
        let results = try db.airports(near: paoCoord, radiusNM: 5.0)

        let icaos = Set(results.map(\.icao))
        #expect(icaos.contains("KPAO"))
        // KSQL is ~5-7 NM from KPAO
        // JFK should definitely not be included
        #expect(!icaos.contains("KJFK"))
    }

    // MARK: - FTS5 Search

    @Test func searchByICAO() throws {
        let db = try Self.makeTempDB()
        try db.insertAirports([Self.kpao, Self.ksql, Self.koak])

        let results = try db.searchAirports(query: "KPAO", limit: 10)
        #expect(results.count == 1)
        #expect(results.first?.icao == "KPAO")
    }

    @Test func searchByName() throws {
        let db = try Self.makeTempDB()
        try db.insertAirports([Self.kpao, Self.ksql, Self.koak])

        let results = try db.searchAirports(query: "San Carlos", limit: 10)
        #expect(results.count == 1)
        #expect(results.first?.icao == "KSQL")
    }

    @Test func searchByPartialName() throws {
        let db = try Self.makeTempDB()
        try db.insertAirports([Self.kpao, Self.ksql, Self.koak, Self.ksfo])

        // "San" should match "San Carlos" and "San Francisco Intl" and "San Jose Intl"
        let results = try db.searchAirports(query: "San", limit: 10)
        let icaos = Set(results.map(\.icao))
        #expect(icaos.contains("KSQL"))   // San Carlos
        #expect(icaos.contains("KSFO"))   // San Francisco Intl
    }

    @Test func searchByFAAID() throws {
        let db = try Self.makeTempDB()
        try db.insertAirports([Self.kpao, Self.ksql, Self.koak])

        let results = try db.searchAirports(query: "PAO", limit: 10)
        // Should find KPAO (faaID = "PAO")
        #expect(results.count >= 1)
        let icaos = results.map(\.icao)
        #expect(icaos.contains("KPAO"))
    }

    @Test func searchLimitWorks() throws {
        let db = try Self.makeTempDB()
        try db.insertAirports([Self.kpao, Self.ksql, Self.koak, Self.ksfo, Self.ksjc])

        // "K" matches all ICAO codes starting with K
        let results = try db.searchAirports(query: "K", limit: 2)
        #expect(results.count <= 2)
    }

    @Test func searchNoResults() throws {
        let db = try Self.makeTempDB()
        try db.insertAirports([Self.kpao, Self.ksql])

        let results = try db.searchAirports(query: "ZZZZ", limit: 10)
        #expect(results.isEmpty)
    }

    // MARK: - Runway & Frequency Round-Trip

    @Test func airportWithRunwaysRoundTrip() throws {
        let db = try Self.makeTempDB()

        let runway = Runway(
            id: "13/31", length: 2443, width: 70,
            surface: .asphalt, lighting: .fullTime,
            baseEndID: "13", reciprocalEndID: "31",
            baseEndLatitude: 37.4585, baseEndLongitude: -122.1120,
            reciprocalEndLatitude: 37.4636, reciprocalEndLongitude: -122.1181,
            baseEndElevation: 4, reciprocalEndElevation: 4
        )
        let airport = Self.makeTestAirport(icao: "KPAO", runways: [runway])
        try db.insertAirport(airport)

        let fetched = try db.airport(byICAO: "KPAO")
        #expect(fetched != nil)
        #expect(fetched?.runways.count == 1)
        #expect(fetched?.runways.first?.id == "13/31")
        #expect(fetched?.runways.first?.length == 2443)
        #expect(fetched?.runways.first?.surface == .asphalt)
    }

    @Test func airportWithFrequenciesRoundTrip() throws {
        let db = try Self.makeTempDB()

        let freqID = UUID()
        let frequency = Frequency(id: freqID, type: .ctaf, frequency: 118.6, name: "Palo Alto CTAF")
        let airport = Self.makeTestAirport(icao: "KPAO", frequencies: [frequency])
        try db.insertAirport(airport)

        let fetched = try db.airport(byICAO: "KPAO")
        #expect(fetched != nil)
        #expect(fetched?.frequencies.count == 1)
        #expect(fetched?.frequencies.first?.frequency == 118.6)
        #expect(fetched?.frequencies.first?.type == .ctaf)
        #expect(fetched?.frequencies.first?.name == "Palo Alto CTAF")
    }

    // MARK: - Weather Cache

    @Test func weatherCacheRoundTrip() throws {
        let db = try Self.makeTempDB()

        let weather = WeatherCache(
            stationID: "KPAO",
            metar: "KPAO 121855Z 31008KT 10SM FEW040 20/10 A3012",
            flightCategory: .vfr,
            temperature: 20.0,
            dewpoint: 10.0,
            wind: WindInfo(direction: 310, speed: 8, gusts: nil, isVariable: false),
            visibility: 10.0,
            ceiling: nil,
            fetchedAt: Date()
        )
        try db.cacheWeather(weather)

        let fetched = try db.cachedWeather(for: "KPAO")
        #expect(fetched != nil)
        #expect(fetched?.stationID == "KPAO")
        #expect(fetched?.flightCategory == .vfr)
        #expect(fetched?.temperature == 20.0)
        #expect(fetched?.wind?.direction == 310)
        #expect(fetched?.wind?.speed == 8)
    }

    @Test func weatherCacheClear() throws {
        let db = try Self.makeTempDB()

        let weather = WeatherCache(stationID: "KPAO", fetchedAt: Date())
        try db.cacheWeather(weather)
        #expect(try db.cachedWeather(for: "KPAO") != nil)

        try db.clearWeatherCache()
        #expect(try db.cachedWeather(for: "KPAO") == nil)
    }

    @Test func staleWeatherStations() throws {
        let db = try Self.makeTempDB()

        // Insert fresh weather
        let fresh = WeatherCache(stationID: "KPAO", fetchedAt: Date())
        try db.cacheWeather(fresh)

        // Insert stale weather (2 hours ago)
        let stale = WeatherCache(stationID: "KSQL", fetchedAt: Date(timeIntervalSinceNow: -7200))
        try db.cacheWeather(stale)

        // Find stations older than 1 hour
        let staleStations = try db.staleWeatherStations(olderThan: 3600)
        #expect(staleStations.contains("KSQL"))
        #expect(!staleStations.contains("KPAO"))
    }

    // MARK: - Navaid Insert & Lookup

    static func makeTestNavaid(
        id: String = "SJC",
        name: String = "San Jose",
        type: NavaidType = .vorDme,
        latitude: Double = 37.3626,
        longitude: Double = -121.9291,
        frequency: Double = 114.1,
        magneticVariation: Double? = 14.0,
        elevation: Double? = 56
    ) -> Navaid {
        Navaid(
            id: id, name: name, type: type,
            latitude: latitude, longitude: longitude,
            frequency: frequency,
            magneticVariation: magneticVariation,
            elevation: elevation
        )
    }

    static let sjcVOR = makeTestNavaid()
    static let oakVOR = makeTestNavaid(id: "OAK", name: "Oakland", latitude: 37.7213, longitude: -122.2208, frequency: 116.8)
    static let sqpVOR = makeTestNavaid(id: "SQP", name: "Saratoga", latitude: 37.27, longitude: -122.05, frequency: 117.0)

    @Test func insertAndLookupNavaid() throws {
        let db = try Self.makeTempDB()
        try db.insertNavaid(Self.sjcVOR)

        let found = try db.navaid(byID: "SJC")
        #expect(found != nil)
        #expect(found?.id == "SJC")
        #expect(found?.name == "San Jose")
        #expect(found?.type == .vorDme)
        #expect(found?.frequency == 114.1)
        #expect(found?.latitude == 37.3626)
    }

    @Test func navaidNotFound() throws {
        let db = try Self.makeTempDB()
        try db.insertNavaid(Self.sjcVOR)

        let notFound = try db.navaid(byID: "ZZZZ")
        #expect(notFound == nil)
    }

    @Test func bulkInsertNavaids() throws {
        let db = try Self.makeTempDB()
        try db.insertNavaids([Self.sjcVOR, Self.oakVOR, Self.sqpVOR])

        // All three should be queryable
        #expect(try db.navaid(byID: "SJC") != nil)
        #expect(try db.navaid(byID: "OAK") != nil)
        #expect(try db.navaid(byID: "SQP") != nil)
    }

    @Test func navaidInsertOrReplaceOverwrites() throws {
        let db = try Self.makeTempDB()
        try db.insertNavaid(Self.sjcVOR)

        // Replace with updated name
        let modified = Self.makeTestNavaid(id: "SJC", name: "San Jose Updated")
        try db.insertNavaid(modified)

        let fetched = try db.navaid(byID: "SJC")
        #expect(fetched?.name == "San Jose Updated")
    }

    // MARK: - Navaids Near Coordinate (bounding box query)

    @Test func navaidsNearCoordinate() throws {
        let db = try Self.makeTempDB()
        try db.insertNavaids([Self.sjcVOR, Self.oakVOR, Self.sqpVOR])

        // Query near SJC with 20 NM radius — should include SJC and SQP
        let sjcCoord = CLLocationCoordinate2D(latitude: 37.3626, longitude: -121.9291)
        let results = try db.navaids(near: sjcCoord, radiusNM: 20.0)

        let ids = Set(results.map(\.id))
        #expect(ids.contains("SJC"))
        #expect(ids.contains("SQP"))  // ~10 NM away
    }

    @Test func navaidsNearSmallRadius() throws {
        let db = try Self.makeTempDB()
        try db.insertNavaids([Self.sjcVOR, Self.oakVOR])

        // Very small radius from SJC — Oakland is ~25 NM away, shouldn't appear
        let sjcCoord = CLLocationCoordinate2D(latitude: 37.3626, longitude: -121.9291)
        let results = try db.navaids(near: sjcCoord, radiusNM: 5.0)

        let ids = Set(results.map(\.id))
        #expect(ids.contains("SJC"))
        #expect(!ids.contains("OAK"))
    }

    @Test func navaidsNearEmptyDB() throws {
        let db = try Self.makeTempDB()

        let coord = CLLocationCoordinate2D(latitude: 37.46, longitude: -122.12)
        let results = try db.navaids(near: coord, radiusNM: 50.0)
        #expect(results.isEmpty)
    }

    // MARK: - Weather Station Coordinate Resolution

    @Test func airportCoordinateForStation() throws {
        let db = try Self.makeTempDB()
        try db.insertAirport(Self.kpao)

        let coord = try db.airportCoordinate(forStation: "KPAO")
        #expect(coord != nil)
        #expect(coord?.latitude == 37.4611)
        #expect(coord?.longitude == -122.1150)
    }

    @Test func airportCoordinateForUnknownStation() throws {
        let db = try Self.makeTempDB()
        try db.insertAirport(Self.kpao)

        let coord = try db.airportCoordinate(forStation: "KXYZ")
        #expect(coord == nil)
    }

    @Test func airportCoordinateMultipleStations() throws {
        let db = try Self.makeTempDB()
        try db.insertAirports([Self.kpao, Self.ksql, Self.koak])

        let paoCoord = try db.airportCoordinate(forStation: "KPAO")
        let sqlCoord = try db.airportCoordinate(forStation: "KSQL")
        let oakCoord = try db.airportCoordinate(forStation: "KOAK")

        #expect(paoCoord?.latitude == 37.4611)
        #expect(sqlCoord?.latitude == 37.5119)
        #expect(oakCoord?.latitude == 37.7213)
    }

    // MARK: - Navaid Optional Fields

    @Test func navaidWithNilOptionalFields() throws {
        let db = try Self.makeTempDB()
        let navaid = Navaid(
            id: "TST", name: "Test NDB", type: .ndb,
            latitude: 37.0, longitude: -122.0, frequency: 350.0,
            magneticVariation: nil, elevation: nil
        )
        try db.insertNavaid(navaid)

        let fetched = try db.navaid(byID: "TST")
        #expect(fetched != nil)
        #expect(fetched?.type == .ndb)
        #expect(fetched?.magneticVariation == nil)
        #expect(fetched?.elevation == nil)
    }
}
