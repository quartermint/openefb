//
//  AviationDatabase.swift
//  efb-212
//
//  GRDB-based aviation database with R-tree spatial indexes and FTS5 search.
//  Stores airports, runways, frequencies, navaids, and weather cache.
//  All methods are nonisolated since GRDB operations are not MainActor-isolated.
//

import Foundation
import CoreLocation
import GRDB

final class AviationDatabase: @unchecked Sendable {
    private let dbPool: DatabasePool

    // MARK: - Init & Migration

    nonisolated init(path: String) throws {
        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA journal_mode = WAL")
        }
        self.dbPool = try DatabasePool(path: path, configuration: config)
        try Self.migrator.migrate(dbPool)
    }

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            // ── Airports ──
            try db.create(table: "airports") { t in
                t.primaryKey("icao", .text)
                t.column("faaID", .text)
                t.column("name", .text).notNull()
                t.column("latitude", .double).notNull()
                t.column("longitude", .double).notNull()
                t.column("elevation", .double).notNull()                     // feet MSL
                t.column("type", .text).notNull()
                t.column("ownership", .text).notNull()
                t.column("ctafFrequency", .double)                           // MHz
                t.column("unicomFrequency", .double)                         // MHz
                t.column("artccID", .text)
                t.column("fssID", .text)
                t.column("magneticVariation", .double)                       // degrees (W negative)
                t.column("patternAltitude", .integer)                        // feet AGL
                t.column("fuelTypes", .text)                                 // JSON array
                t.column("hasBeaconLight", .boolean).notNull().defaults(to: false)
            }

            // R-tree spatial index for airports
            try db.execute(sql: """
                CREATE VIRTUAL TABLE IF NOT EXISTS airports_rtree
                USING rtree(id, minLat, maxLat, minLon, maxLon)
            """)

            // FTS5 full-text search index
            try db.execute(sql: """
                CREATE VIRTUAL TABLE IF NOT EXISTS airports_fts
                USING fts5(icao, name, faaID, content='airports', content_rowid='rowid')
            """)

            // ── Runways ──
            try db.create(table: "runways") { t in
                t.autoIncrementedPrimaryKey("rowid")
                t.column("id", .text).notNull()
                t.column("airportICAO", .text).notNull()
                    .references("airports", onDelete: .cascade)
                t.column("length", .integer).notNull()                       // feet
                t.column("width", .integer).notNull()                        // feet
                t.column("surface", .text).notNull()
                t.column("lighting", .text).notNull()
                t.column("baseEndID", .text).notNull()
                t.column("reciprocalEndID", .text).notNull()
                t.column("baseEndLatitude", .double).notNull()
                t.column("baseEndLongitude", .double).notNull()
                t.column("reciprocalEndLatitude", .double).notNull()
                t.column("reciprocalEndLongitude", .double).notNull()
                t.column("baseEndElevation", .double)                        // feet MSL (TDZE)
                t.column("reciprocalEndElevation", .double)
            }

            // ── Frequencies ──
            try db.create(table: "frequencies") { t in
                t.primaryKey("id", .text)                                    // UUID string
                t.column("airportICAO", .text).notNull()
                    .references("airports", onDelete: .cascade)
                t.column("type", .text).notNull()
                t.column("frequency", .double).notNull()                     // MHz
                t.column("name", .text).notNull()
            }

            // ── Navaids ──
            try db.create(table: "navaids") { t in
                t.primaryKey("id", .text)
                t.column("name", .text).notNull()
                t.column("type", .text).notNull()
                t.column("latitude", .double).notNull()
                t.column("longitude", .double).notNull()
                t.column("frequency", .double).notNull()                     // MHz (VOR) or kHz (NDB)
                t.column("magneticVariation", .double)                       // degrees
                t.column("elevation", .double)                               // feet MSL
            }

            // ── Weather Cache ──
            try db.create(table: "weatherCache") { t in
                t.primaryKey("id", .text)                                    // UUID string
                t.column("stationID", .text).notNull().unique()
                t.column("metar", .text)
                t.column("taf", .text)
                t.column("flightCategory", .text).notNull()
                t.column("temperature", .double)                             // Celsius
                t.column("dewpoint", .double)                                // Celsius
                t.column("windDirection", .integer)                          // degrees true
                t.column("windSpeed", .integer)                              // knots
                t.column("windGusts", .integer)                              // knots
                t.column("windVariable", .boolean)
                t.column("visibility", .double)                              // statute miles
                t.column("ceiling", .integer)                                // feet AGL
                t.column("fetchedAt", .datetime).notNull()
                t.column("observationTime", .datetime)
            }
        }

        return migrator
    }

    // MARK: - Airport Queries

    /// Fetch a single airport by ICAO identifier, including its runways and frequencies.
    nonisolated func airport(byICAO icao: String) throws -> Airport? {
        try dbPool.read { db in
            guard let row = try Row.fetchOne(db, sql: "SELECT * FROM airports WHERE icao = ?", arguments: [icao]) else {
                return nil
            }
            let runways = try self.fetchRunways(db: db, airportICAO: icao)
            let frequencies = try self.fetchFrequencies(db: db, airportICAO: icao)
            return self.airportFromRow(row, runways: runways, frequencies: frequencies)
        }
    }

    /// Search airports near a coordinate within a radius, using R-tree bounding box.
    /// 1 NM ~ 1/60 degree latitude.
    nonisolated func airports(near coordinate: CLLocationCoordinate2D, radiusNM: Double) throws -> [Airport] {
        let degreeOffset = radiusNM / 60.0
        let minLat = coordinate.latitude - degreeOffset
        let maxLat = coordinate.latitude + degreeOffset
        // Longitude degrees shrink with latitude
        let lonOffset = degreeOffset / max(cos(coordinate.latitude * .pi / 180.0), 0.01)
        let minLon = coordinate.longitude - lonOffset
        let maxLon = coordinate.longitude + lonOffset

        return try dbPool.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT a.* FROM airports a
                INNER JOIN airports_rtree r ON a.rowid = r.id
                WHERE r.minLat <= ? AND r.maxLat >= ?
                  AND r.minLon <= ? AND r.maxLon >= ?
            """, arguments: [maxLat, minLat, maxLon, minLon])

            return try rows.compactMap { row -> Airport? in
                let icao: String = row["icao"]
                let runways = try self.fetchRunways(db: db, airportICAO: icao)
                let frequencies = try self.fetchFrequencies(db: db, airportICAO: icao)
                return self.airportFromRow(row, runways: runways, frequencies: frequencies)
            }
        }
    }

    /// Find the nearest airports to a coordinate, limited by count.
    /// Uses R-tree with a generous bounding box, then sorts by distance.
    nonisolated func nearestAirports(to coordinate: CLLocationCoordinate2D, count: Int) throws -> [Airport] {
        // Start with a 50 NM bounding box; if not enough results, expand
        let radiusNM: Double = 50.0
        var results = try airports(near: coordinate, radiusNM: radiusNM)

        // Sort by great-circle distance
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        results.sort { a, b in
            let distA = location.distance(from: CLLocation(latitude: a.latitude, longitude: a.longitude))
            let distB = location.distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
            return distA < distB
        }

        return Array(results.prefix(count))
    }

    /// Full-text search for airports by ICAO, name, or FAA ID using FTS5.
    nonisolated func searchAirports(query: String, limit: Int) throws -> [Airport] {
        let sanitized = query.replacingOccurrences(of: "\"", with: "\"\"")
        let ftsQuery = "\"\(sanitized)\"*"

        return try dbPool.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT a.* FROM airports a
                INNER JOIN airports_fts fts ON a.rowid = fts.rowid
                WHERE airports_fts MATCH ?
                LIMIT ?
            """, arguments: [ftsQuery, limit])

            return try rows.compactMap { row -> Airport? in
                let icao: String = row["icao"]
                let runways = try self.fetchRunways(db: db, airportICAO: icao)
                let frequencies = try self.fetchFrequencies(db: db, airportICAO: icao)
                return self.airportFromRow(row, runways: runways, frequencies: frequencies)
            }
        }
    }

    // MARK: - Weather Cache

    /// Fetch cached weather for a station.
    nonisolated func cachedWeather(for stationID: String) throws -> WeatherCache? {
        try dbPool.read { db in
            guard let row = try Row.fetchOne(db, sql: "SELECT * FROM weatherCache WHERE stationID = ?", arguments: [stationID]) else {
                return nil
            }
            return self.weatherCacheFromRow(row)
        }
    }

    /// Insert or replace weather cache entry.
    nonisolated func cacheWeather(_ weather: WeatherCache) throws {
        try dbPool.write { db in
            try db.execute(
                sql: """
                    INSERT OR REPLACE INTO weatherCache
                    (id, stationID, metar, taf, flightCategory, temperature, dewpoint,
                     windDirection, windSpeed, windGusts, windVariable, visibility, ceiling,
                     fetchedAt, observationTime)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                arguments: [
                    weather.id.uuidString,
                    weather.stationID,
                    weather.metar,
                    weather.taf,
                    weather.flightCategory.rawValue,
                    weather.temperature,
                    weather.dewpoint,
                    weather.wind?.direction,
                    weather.wind?.speed,
                    weather.wind?.gusts,
                    weather.wind?.isVariable,
                    weather.visibility,
                    weather.ceiling,
                    weather.fetchedAt,
                    weather.observationTime
                ]
            )
        }
    }

    /// Find station IDs with weather older than the given interval.
    nonisolated func staleWeatherStations(olderThan interval: TimeInterval) throws -> [String] {
        let cutoff = Date().addingTimeInterval(-interval)
        return try dbPool.read { db in
            try String.fetchAll(db, sql: "SELECT stationID FROM weatherCache WHERE fetchedAt < ?", arguments: [cutoff])
        }
    }

    /// Clear all weather cache entries.
    nonisolated func clearWeatherCache() throws {
        try dbPool.write { db in
            try db.execute(sql: "DELETE FROM weatherCache")
        }
    }

    // MARK: - Private Helpers

    private nonisolated func fetchRunways(db: Database, airportICAO: String) throws -> [Runway] {
        let rows = try Row.fetchAll(db, sql: "SELECT * FROM runways WHERE airportICAO = ?", arguments: [airportICAO])
        return rows.map { row in
            Runway(
                id: row["id"],
                length: row["length"],
                width: row["width"],
                surface: SurfaceType(rawValue: row["surface"]) ?? .other,
                lighting: LightingType(rawValue: row["lighting"]) ?? .none,
                baseEndID: row["baseEndID"],
                reciprocalEndID: row["reciprocalEndID"],
                baseEndLatitude: row["baseEndLatitude"],
                baseEndLongitude: row["baseEndLongitude"],
                reciprocalEndLatitude: row["reciprocalEndLatitude"],
                reciprocalEndLongitude: row["reciprocalEndLongitude"],
                baseEndElevation: row["baseEndElevation"],
                reciprocalEndElevation: row["reciprocalEndElevation"]
            )
        }
    }

    private nonisolated func fetchFrequencies(db: Database, airportICAO: String) throws -> [Frequency] {
        let rows = try Row.fetchAll(db, sql: "SELECT * FROM frequencies WHERE airportICAO = ?", arguments: [airportICAO])
        return rows.map { row in
            let idString: String = row["id"]
            return Frequency(
                id: UUID(uuidString: idString) ?? UUID(),
                type: FrequencyType(rawValue: row["type"]) ?? .ctaf,
                frequency: row["frequency"],
                name: row["name"]
            )
        }
    }

    private nonisolated func airportFromRow(_ row: Row, runways: [Runway], frequencies: [Frequency]) -> Airport {
        let fuelTypesJSON: String? = row["fuelTypes"]
        let fuelTypes: [String]
        if let json = fuelTypesJSON,
           let data = json.data(using: .utf8),
           let parsed = try? JSONDecoder().decode([String].self, from: data) {
            fuelTypes = parsed
        } else {
            fuelTypes = []
        }

        return Airport(
            icao: row["icao"],
            faaID: row["faaID"],
            name: row["name"],
            latitude: row["latitude"],
            longitude: row["longitude"],
            elevation: row["elevation"],
            type: AirportType(rawValue: row["type"]) ?? .airport,
            ownership: OwnershipType(rawValue: row["ownership"]) ?? .publicOwned,
            ctafFrequency: row["ctafFrequency"],
            unicomFrequency: row["unicomFrequency"],
            artccID: row["artccID"],
            fssID: row["fssID"],
            magneticVariation: row["magneticVariation"],
            patternAltitude: row["patternAltitude"],
            fuelTypes: fuelTypes,
            hasBeaconLight: row["hasBeaconLight"],
            runways: runways,
            frequencies: frequencies
        )
    }

    private nonisolated func weatherCacheFromRow(_ row: Row) -> WeatherCache {
        let windDirection: Int? = row["windDirection"]
        let windSpeed: Int? = row["windSpeed"]
        let windGusts: Int? = row["windGusts"]
        let windVariable: Bool? = row["windVariable"]

        let wind: WindInfo?
        if let direction = windDirection, let speed = windSpeed {
            wind = WindInfo(
                direction: direction,
                speed: speed,
                gusts: windGusts,
                isVariable: windVariable ?? false
            )
        } else {
            wind = nil
        }

        let idString: String = row["id"]

        return WeatherCache(
            id: UUID(uuidString: idString) ?? UUID(),
            stationID: row["stationID"],
            metar: row["metar"],
            taf: row["taf"],
            flightCategory: FlightCategory(rawValue: row["flightCategory"]) ?? .vfr,
            temperature: row["temperature"],
            dewpoint: row["dewpoint"],
            wind: wind,
            visibility: row["visibility"],
            ceiling: row["ceiling"],
            fetchedAt: row["fetchedAt"],
            observationTime: row["observationTime"]
        )
    }
}
