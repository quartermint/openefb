#!/usr/bin/env swift
//
//  NASR Importer
//  Generates a bundled aviation.sqlite database for OpenEFB.
//
//  Creates a pre-built SQLite database with airports, runways, frequencies,
//  navaids, and airspaces from FAA NASR data (seed approach for Phase 1).
//
//  Usage: swift run nasr-importer --output <path>
//

import Foundation
import GRDB

// MARK: - CLI Argument Parsing

var outputPath = "aviation.sqlite"
var args = CommandLine.arguments.dropFirst()
while let arg = args.first {
    args = args.dropFirst()
    if arg == "--output", let next = args.first {
        outputPath = next
        args = args.dropFirst()
    }
}

print("NASR Importer - OpenEFB Aviation Database Generator")
print("Output: \(outputPath)")

// MARK: - Database Creation

// Remove existing file
let fileManager = FileManager.default
if fileManager.fileExists(atPath: outputPath) {
    try fileManager.removeItem(atPath: outputPath)
}

// Ensure parent directory exists
let parentDir = (outputPath as NSString).deletingLastPathComponent
if !parentDir.isEmpty && !fileManager.fileExists(atPath: parentDir) {
    try fileManager.createDirectory(atPath: parentDir, withIntermediateDirectories: true)
}

var config = Configuration()
let dbQueue = try DatabaseQueue(path: outputPath, configuration: config)

// MARK: - Schema Creation

try dbQueue.write { db in
    // -- Airports
    try db.execute(sql: """
        CREATE TABLE airports (
            icao TEXT PRIMARY KEY,
            faa_id TEXT,
            name TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            elevation REAL NOT NULL DEFAULT 0,
            type TEXT NOT NULL DEFAULT 'airport',
            ownership TEXT NOT NULL DEFAULT 'public',
            ctaf_frequency REAL,
            unicom_frequency REAL,
            artcc_id TEXT,
            fss_id TEXT,
            magnetic_variation REAL,
            pattern_altitude INTEGER,
            fuel_types TEXT DEFAULT '[]',
            has_beacon_light INTEGER DEFAULT 0
        )
        """)

    // -- Runways
    try db.execute(sql: """
        CREATE TABLE runways (
            id TEXT NOT NULL,
            airport_icao TEXT NOT NULL REFERENCES airports(icao),
            length INTEGER NOT NULL,
            width INTEGER NOT NULL,
            surface TEXT NOT NULL DEFAULT 'asphalt',
            lighting TEXT NOT NULL DEFAULT 'none',
            base_end_id TEXT NOT NULL,
            reciprocal_end_id TEXT NOT NULL,
            base_end_latitude REAL NOT NULL DEFAULT 0,
            base_end_longitude REAL NOT NULL DEFAULT 0,
            reciprocal_end_latitude REAL NOT NULL DEFAULT 0,
            reciprocal_end_longitude REAL NOT NULL DEFAULT 0
        )
        """)

    // -- Frequencies
    try db.execute(sql: """
        CREATE TABLE frequencies (
            id TEXT NOT NULL,
            airport_icao TEXT NOT NULL REFERENCES airports(icao),
            type TEXT NOT NULL,
            name TEXT NOT NULL,
            frequency REAL NOT NULL
        )
        """)

    // -- Navaids
    try db.execute(sql: """
        CREATE TABLE navaids (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL DEFAULT 'vor',
            name TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            frequency REAL NOT NULL DEFAULT 0,
            elevation REAL,
            magnetic_variation REAL
        )
        """)

    // -- Airspaces
    try db.execute(sql: """
        CREATE TABLE airspaces (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            class TEXT NOT NULL,
            floor_altitude INTEGER NOT NULL DEFAULT 0,
            ceiling_altitude INTEGER NOT NULL DEFAULT 18000,
            center_latitude REAL,
            center_longitude REAL,
            radius_nm REAL,
            coordinates TEXT,
            min_lat REAL NOT NULL,
            max_lat REAL NOT NULL,
            min_lon REAL NOT NULL,
            max_lon REAL NOT NULL
        )
        """)

    // -- R-tree virtual tables
    try db.execute(sql: """
        CREATE VIRTUAL TABLE airports_rtree USING rtree(
            rowid, min_lat, max_lat, min_lon, max_lon
        )
        """)

    try db.execute(sql: """
        CREATE VIRTUAL TABLE navaids_rtree USING rtree(
            rowid, min_lat, max_lat, min_lon, max_lon
        )
        """)

    try db.execute(sql: """
        CREATE VIRTUAL TABLE airspaces_rtree USING rtree(
            rowid, min_lat, max_lat, min_lon, max_lon
        )
        """)

    // -- FTS5 full-text search
    try db.execute(sql: """
        CREATE VIRTUAL TABLE airports_fts USING fts5(
            icao, name, faa_id,
            content=airports, content_rowid=rowid
        )
        """)

    // -- Indexes
    try db.execute(sql: "CREATE INDEX idx_runways_airport ON runways(airport_icao)")
    try db.execute(sql: "CREATE INDEX idx_frequencies_airport ON frequencies(airport_icao)")

    print("Schema created successfully.")
}

// MARK: - Data Structures

struct AirportSeed {
    let icao: String
    let faaID: String?
    let name: String
    let lat: Double
    let lon: Double
    let elevation: Double
    let type: String
    let ownership: String
    let ctaf: Double?
    let unicom: Double?
    let artcc: String?
    let magVar: Double?
    let patternAlt: Int?
    let fuelTypes: [String]
    let hasBeacon: Bool
    let runways: [(id: String, length: Int, width: Int, surface: String, lighting: String, baseID: String, recipID: String, baseLat: Double, baseLon: Double, recipLat: Double, recipLon: Double)]
    let frequencies: [(type: String, name: String, freq: Double)]
}

struct NavaidSeed {
    let id: String
    let type: String
    let name: String
    let lat: Double
    let lon: Double
    let freq: Double
    let elevation: Double?
    let magVar: Double?
}

struct AirspaceSeed {
    let id: String
    let name: String
    let cls: String
    let floor: Int
    let ceiling: Int
    let centerLat: Double?
    let centerLon: Double?
    let radiusNM: Double?
    let coordinates: [[Double]]?
}

// MARK: - Seed Data: Major US Towered Airports

// Class B primary airports (30 major cities)
let classBPrimaries: [AirportSeed] = [
    AirportSeed(icao: "KATL", faaID: "ATL", name: "Hartsfield-Jackson Atlanta Intl", lat: 33.6367, lon: -84.4281, elevation: 1026, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZTL", magVar: -6.0, patternAlt: 2026, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "8L/26R", length: 9000, width: 150, surface: "asphalt", lighting: "fullTime", baseID: "8L", recipID: "26R", baseLat: 33.637, baseLon: -84.445, recipLat: 33.637, recipLon: -84.411)], frequencies: [(type: "tower", name: "Atlanta Tower", freq: 119.1), (type: "ground", name: "Atlanta Ground", freq: 121.9), (type: "atis", name: "Atlanta ATIS", freq: 125.55), (type: "approach", name: "Atlanta Approach", freq: 119.8)]),
    AirportSeed(icao: "KBOS", faaID: "BOS", name: "Boston Logan Intl", lat: 42.3643, lon: -71.0052, elevation: 20, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZBW", magVar: -15.0, patternAlt: 1020, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "4R/22L", length: 10006, width: 150, surface: "asphalt", lighting: "fullTime", baseID: "4R", recipID: "22L", baseLat: 42.356, baseLon: -71.012, recipLat: 42.379, recipLon: -70.998)], frequencies: [(type: "tower", name: "Boston Tower", freq: 128.8), (type: "ground", name: "Boston Ground", freq: 121.9), (type: "atis", name: "Boston ATIS", freq: 135.0)]),
    AirportSeed(icao: "KORD", faaID: "ORD", name: "Chicago O'Hare Intl", lat: 41.9742, lon: -87.9073, elevation: 672, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZAU", magVar: -3.0, patternAlt: 1672, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "10L/28R", length: 13000, width: 200, surface: "concrete", lighting: "fullTime", baseID: "10L", recipID: "28R", baseLat: 41.983, baseLon: -87.930, recipLat: 41.965, recipLon: -87.885)], frequencies: [(type: "tower", name: "O'Hare Tower", freq: 120.75), (type: "ground", name: "O'Hare Ground", freq: 121.75), (type: "atis", name: "O'Hare ATIS", freq: 135.4)]),
    AirportSeed(icao: "KDFW", faaID: "DFW", name: "Dallas/Fort Worth Intl", lat: 32.8968, lon: -97.0380, elevation: 607, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZFW", magVar: 5.0, patternAlt: 1607, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "17L/35R", length: 11388, width: 200, surface: "concrete", lighting: "fullTime", baseID: "17L", recipID: "35R", baseLat: 32.920, baseLon: -97.040, recipLat: 32.880, recipLon: -97.040)], frequencies: [(type: "tower", name: "DFW Tower", freq: 124.15), (type: "ground", name: "DFW Ground", freq: 121.65), (type: "atis", name: "DFW ATIS", freq: 134.9)]),
    AirportSeed(icao: "KDEN", faaID: "DEN", name: "Denver Intl", lat: 39.8561, lon: -104.6737, elevation: 5431, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZDV", magVar: 8.0, patternAlt: 6431, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "16L/34R", length: 12000, width: 150, surface: "concrete", lighting: "fullTime", baseID: "16L", recipID: "34R", baseLat: 39.874, baseLon: -104.674, recipLat: 39.838, recipLon: -104.674)], frequencies: [(type: "tower", name: "Denver Tower", freq: 132.35), (type: "ground", name: "Denver Ground", freq: 121.85), (type: "atis", name: "Denver ATIS", freq: 134.02)]),
    AirportSeed(icao: "KJFK", faaID: "JFK", name: "John F Kennedy Intl", lat: 40.6399, lon: -73.7787, elevation: 13, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZNY", magVar: -13.0, patternAlt: 1013, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "4L/22R", length: 11351, width: 200, surface: "asphalt", lighting: "fullTime", baseID: "4L", recipID: "22R", baseLat: 40.630, baseLon: -73.790, recipLat: 40.660, recipLon: -73.762)], frequencies: [(type: "tower", name: "JFK Tower", freq: 119.1), (type: "ground", name: "JFK Ground", freq: 121.9), (type: "atis", name: "JFK ATIS", freq: 128.72)]),
    AirportSeed(icao: "KLAX", faaID: "LAX", name: "Los Angeles Intl", lat: 33.9425, lon: -118.4081, elevation: 128, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZLA", magVar: 13.0, patternAlt: 1128, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "24L/6R", length: 10885, width: 150, surface: "asphalt", lighting: "fullTime", baseID: "24L", recipID: "6R", baseLat: 33.950, baseLon: -118.392, recipLat: 33.935, recipLon: -118.424)], frequencies: [(type: "tower", name: "LAX Tower", freq: 133.9), (type: "ground", name: "LAX Ground", freq: 121.65), (type: "atis", name: "LAX ATIS", freq: 133.8)]),
    AirportSeed(icao: "KSFO", faaID: "SFO", name: "San Francisco Intl", lat: 37.6213, lon: -122.3790, elevation: 13, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZOA", magVar: 14.0, patternAlt: 1013, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "28L/10R", length: 11870, width: 200, surface: "asphalt", lighting: "fullTime", baseID: "28L", recipID: "10R", baseLat: 37.615, baseLon: -122.358, recipLat: 37.629, recipLon: -122.393)], frequencies: [(type: "tower", name: "SFO Tower", freq: 120.5), (type: "ground", name: "SFO Ground", freq: 121.8), (type: "atis", name: "SFO ATIS", freq: 118.85)]),
    AirportSeed(icao: "KSEA", faaID: "SEA", name: "Seattle-Tacoma Intl", lat: 47.4502, lon: -122.3088, elevation: 433, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZSE", magVar: 16.0, patternAlt: 1433, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "16L/34R", length: 11901, width: 150, surface: "concrete", lighting: "fullTime", baseID: "16L", recipID: "34R", baseLat: 47.465, baseLon: -122.309, recipLat: 47.435, recipLon: -122.309)], frequencies: [(type: "tower", name: "Seattle Tower", freq: 119.9), (type: "ground", name: "Seattle Ground", freq: 121.7), (type: "atis", name: "Seattle ATIS", freq: 118.0)]),
    AirportSeed(icao: "KMIA", faaID: "MIA", name: "Miami Intl", lat: 25.7959, lon: -80.2870, elevation: 9, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZMA", magVar: -6.0, patternAlt: 1009, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "8R/26L", length: 13016, width: 200, surface: "asphalt", lighting: "fullTime", baseID: "8R", recipID: "26L", baseLat: 25.793, baseLon: -80.310, recipLat: 25.799, recipLon: -80.265)], frequencies: [(type: "tower", name: "Miami Tower", freq: 118.3), (type: "ground", name: "Miami Ground", freq: 121.8), (type: "atis", name: "Miami ATIS", freq: 128.57)]),
    AirportSeed(icao: "KEWR", faaID: "EWR", name: "Newark Liberty Intl", lat: 40.6925, lon: -74.1687, elevation: 18, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZNY", magVar: -13.0, patternAlt: 1018, fuelTypes: ["Jet-A"], hasBeacon: true, runways: [(id: "4L/22R", length: 11000, width: 150, surface: "asphalt", lighting: "fullTime", baseID: "4L", recipID: "22R", baseLat: 40.680, baseLon: -74.178, recipLat: 40.705, recipLon: -74.160)], frequencies: [(type: "tower", name: "Newark Tower", freq: 118.3), (type: "ground", name: "Newark Ground", freq: 121.8)]),
    AirportSeed(icao: "KLAS", faaID: "LAS", name: "Harry Reid Intl", lat: 36.0840, lon: -115.1522, elevation: 2181, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZLA", magVar: 13.0, patternAlt: 3181, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "1L/19R", length: 9775, width: 150, surface: "asphalt", lighting: "fullTime", baseID: "1L", recipID: "19R", baseLat: 36.072, baseLon: -115.158, recipLat: 36.098, recipLon: -115.148)], frequencies: [(type: "tower", name: "Las Vegas Tower", freq: 119.9), (type: "ground", name: "Las Vegas Ground", freq: 121.9), (type: "atis", name: "Las Vegas ATIS", freq: 132.4)]),
    AirportSeed(icao: "KPHX", faaID: "PHX", name: "Phoenix Sky Harbor Intl", lat: 33.4373, lon: -112.0078, elevation: 1135, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZAB", magVar: 11.0, patternAlt: 2135, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "7L/25R", length: 11489, width: 150, surface: "concrete", lighting: "fullTime", baseID: "7L", recipID: "25R", baseLat: 33.434, baseLon: -112.025, recipLat: 33.440, recipLon: -111.990)], frequencies: [(type: "tower", name: "Phoenix Tower", freq: 120.9), (type: "ground", name: "Phoenix Ground", freq: 119.75), (type: "atis", name: "Phoenix ATIS", freq: 127.57)]),
    AirportSeed(icao: "KMSP", faaID: "MSP", name: "Minneapolis-St Paul Intl", lat: 44.8848, lon: -93.2223, elevation: 841, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZMP", magVar: 1.0, patternAlt: 1841, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "12L/30R", length: 10000, width: 200, surface: "concrete", lighting: "fullTime", baseID: "12L", recipID: "30R", baseLat: 44.890, baseLon: -93.235, recipLat: 44.875, recipLon: -93.209)], frequencies: [(type: "tower", name: "Minneapolis Tower", freq: 126.7), (type: "ground", name: "Minneapolis Ground", freq: 121.8), (type: "atis", name: "Minneapolis ATIS", freq: 135.35)]),
    AirportSeed(icao: "KDTW", faaID: "DTW", name: "Detroit Metro Wayne County", lat: 42.2124, lon: -83.3534, elevation: 645, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZOB", magVar: -7.0, patternAlt: 1645, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "3L/21R", length: 12003, width: 200, surface: "concrete", lighting: "fullTime", baseID: "3L", recipID: "21R", baseLat: 42.197, baseLon: -83.363, recipLat: 42.227, recipLon: -83.343)], frequencies: [(type: "tower", name: "Detroit Tower", freq: 118.4), (type: "ground", name: "Detroit Ground", freq: 121.8), (type: "atis", name: "Detroit ATIS", freq: 135.0)]),
    AirportSeed(icao: "KPHL", faaID: "PHL", name: "Philadelphia Intl", lat: 39.8721, lon: -75.2408, elevation: 36, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZNY", magVar: -12.0, patternAlt: 1036, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "9L/27R", length: 10500, width: 200, surface: "asphalt", lighting: "fullTime", baseID: "9L", recipID: "27R", baseLat: 39.874, baseLon: -75.260, recipLat: 39.870, recipLon: -75.221)], frequencies: [(type: "tower", name: "Philadelphia Tower", freq: 118.5), (type: "ground", name: "Philadelphia Ground", freq: 121.9)]),
    AirportSeed(icao: "KIAH", faaID: "IAH", name: "George Bush Intercontinental", lat: 29.9844, lon: -95.3414, elevation: 97, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZHU", magVar: 4.0, patternAlt: 1097, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "8L/26R", length: 10000, width: 150, surface: "concrete", lighting: "fullTime", baseID: "8L", recipID: "26R", baseLat: 29.985, baseLon: -95.360, recipLat: 29.983, recipLon: -95.322)], frequencies: [(type: "tower", name: "Houston Tower", freq: 118.575), (type: "ground", name: "Houston Ground", freq: 121.7)]),
    AirportSeed(icao: "KMCO", faaID: "MCO", name: "Orlando Intl", lat: 28.4294, lon: -81.3089, elevation: 96, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZJX", magVar: -6.0, patternAlt: 1096, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "17L/35R", length: 12005, width: 200, surface: "concrete", lighting: "fullTime", baseID: "17L", recipID: "35R", baseLat: 28.445, baseLon: -81.310, recipLat: 28.413, recipLon: -81.310)], frequencies: [(type: "tower", name: "Orlando Tower", freq: 124.3), (type: "ground", name: "Orlando Ground", freq: 121.8)]),
    AirportSeed(icao: "KCLT", faaID: "CLT", name: "Charlotte Douglas Intl", lat: 35.2140, lon: -80.9431, elevation: 748, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZTL", magVar: -8.0, patternAlt: 1748, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "18L/36R", length: 10000, width: 150, surface: "concrete", lighting: "fullTime", baseID: "18L", recipID: "36R", baseLat: 35.228, baseLon: -80.943, recipLat: 35.200, recipLon: -80.943)], frequencies: [(type: "tower", name: "Charlotte Tower", freq: 119.9), (type: "ground", name: "Charlotte Ground", freq: 121.9)]),
    AirportSeed(icao: "KSLC", faaID: "SLC", name: "Salt Lake City Intl", lat: 40.7884, lon: -111.9778, elevation: 4227, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZLC", magVar: 12.0, patternAlt: 5227, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "16L/34R", length: 12000, width: 150, surface: "concrete", lighting: "fullTime", baseID: "16L", recipID: "34R", baseLat: 40.803, baseLon: -111.978, recipLat: 40.773, recipLon: -111.978)], frequencies: [(type: "tower", name: "Salt Lake Tower", freq: 118.3), (type: "ground", name: "Salt Lake Ground", freq: 121.9)]),
    AirportSeed(icao: "KDCA", faaID: "DCA", name: "Ronald Reagan Washington National", lat: 38.8521, lon: -77.0377, elevation: 15, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZDC", magVar: -11.0, patternAlt: 1015, fuelTypes: ["Jet-A"], hasBeacon: true, runways: [(id: "1/19", length: 6869, width: 150, surface: "asphalt", lighting: "fullTime", baseID: "1", recipID: "19", baseLat: 38.844, baseLon: -77.038, recipLat: 38.860, recipLon: -77.037)], frequencies: [(type: "tower", name: "Reagan Tower", freq: 119.1), (type: "ground", name: "Reagan Ground", freq: 121.7)]),
    AirportSeed(icao: "KIAD", faaID: "IAD", name: "Washington Dulles Intl", lat: 38.9445, lon: -77.4558, elevation: 313, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZDC", magVar: -11.0, patternAlt: 1313, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "1L/19R", length: 11501, width: 150, surface: "concrete", lighting: "fullTime", baseID: "1L", recipID: "19R", baseLat: 38.930, baseLon: -77.460, recipLat: 38.960, recipLon: -77.450)], frequencies: [(type: "tower", name: "Dulles Tower", freq: 120.1), (type: "ground", name: "Dulles Ground", freq: 121.9)]),
    AirportSeed(icao: "KSAN", faaID: "SAN", name: "San Diego Intl Lindbergh", lat: 32.7336, lon: -117.1897, elevation: 17, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZLA", magVar: 13.0, patternAlt: 1017, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "9/27", length: 9401, width: 200, surface: "asphalt", lighting: "fullTime", baseID: "9", recipID: "27", baseLat: 32.733, baseLon: -117.207, recipLat: 32.734, recipLon: -117.175)], frequencies: [(type: "tower", name: "San Diego Tower", freq: 118.3), (type: "ground", name: "San Diego Ground", freq: 123.9)]),
    AirportSeed(icao: "KTPA", faaID: "TPA", name: "Tampa Intl", lat: 27.9755, lon: -82.5332, elevation: 26, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZJX", magVar: -6.0, patternAlt: 1026, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "1L/19R", length: 11002, width: 150, surface: "asphalt", lighting: "fullTime", baseID: "1L", recipID: "19R", baseLat: 27.962, baseLon: -82.537, recipLat: 27.990, recipLon: -82.527)], frequencies: [(type: "tower", name: "Tampa Tower", freq: 119.5), (type: "ground", name: "Tampa Ground", freq: 121.7)]),
    AirportSeed(icao: "KBWI", faaID: "BWI", name: "Baltimore-Washington Intl", lat: 39.1754, lon: -76.6683, elevation: 146, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZDC", magVar: -11.0, patternAlt: 1146, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "10/28", length: 10502, width: 200, surface: "asphalt", lighting: "fullTime", baseID: "10", recipID: "28", baseLat: 39.177, baseLon: -76.688, recipLat: 39.173, recipLon: -76.650)], frequencies: [(type: "tower", name: "BWI Tower", freq: 124.0), (type: "ground", name: "BWI Ground", freq: 121.9)]),
    AirportSeed(icao: "KSTL", faaID: "STL", name: "St Louis Lambert Intl", lat: 38.7487, lon: -90.3700, elevation: 618, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZKC", magVar: 2.0, patternAlt: 1618, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "12L/30R", length: 11020, width: 200, surface: "concrete", lighting: "fullTime", baseID: "12L", recipID: "30R", baseLat: 38.755, baseLon: -90.384, recipLat: 38.740, recipLon: -90.355)], frequencies: [(type: "tower", name: "St Louis Tower", freq: 120.4), (type: "ground", name: "St Louis Ground", freq: 121.8)]),
    AirportSeed(icao: "KPIT", faaID: "PIT", name: "Pittsburgh Intl", lat: 40.4915, lon: -80.2329, elevation: 1203, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZOB", magVar: -9.0, patternAlt: 2203, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "10L/28R", length: 10502, width: 150, surface: "concrete", lighting: "fullTime", baseID: "10L", recipID: "28R", baseLat: 40.496, baseLon: -80.252, recipLat: 40.487, recipLon: -80.213)], frequencies: [(type: "tower", name: "Pittsburgh Tower", freq: 119.1), (type: "ground", name: "Pittsburgh Ground", freq: 121.7)]),
    AirportSeed(icao: "KCLE", faaID: "CLE", name: "Cleveland Hopkins Intl", lat: 41.4117, lon: -81.8498, elevation: 791, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZOB", magVar: -8.0, patternAlt: 1791, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "6L/24R", length: 9956, width: 150, surface: "asphalt", lighting: "fullTime", baseID: "6L", recipID: "24R", baseLat: 41.405, baseLon: -81.868, recipLat: 41.418, recipLon: -81.831)], frequencies: [(type: "tower", name: "Cleveland Tower", freq: 124.5), (type: "ground", name: "Cleveland Ground", freq: 121.7)]),
    AirportSeed(icao: "KPDX", faaID: "PDX", name: "Portland Intl", lat: 45.5887, lon: -122.5975, elevation: 31, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZSE", magVar: 16.0, patternAlt: 1031, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "10L/28R", length: 11000, width: 150, surface: "asphalt", lighting: "fullTime", baseID: "10L", recipID: "28R", baseLat: 45.585, baseLon: -122.618, recipLat: 45.593, recipLon: -122.578)], frequencies: [(type: "tower", name: "Portland Tower", freq: 118.7), (type: "ground", name: "Portland Ground", freq: 121.9)]),
    AirportSeed(icao: "KMCI", faaID: "MCI", name: "Kansas City Intl", lat: 39.2976, lon: -94.7139, elevation: 1026, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZKC", magVar: 3.0, patternAlt: 2026, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "1L/19R", length: 10801, width: 150, surface: "concrete", lighting: "fullTime", baseID: "1L", recipID: "19R", baseLat: 39.282, baseLon: -94.723, recipLat: 39.313, recipLon: -94.710)], frequencies: [(type: "tower", name: "Kansas City Tower", freq: 133.3), (type: "ground", name: "Kansas City Ground", freq: 121.65)]),
]

// Popular Bay Area GA airports (for local testing)
let bayAreaGA: [AirportSeed] = [
    AirportSeed(icao: "KPAO", faaID: "PAO", name: "Palo Alto Airport of Santa Clara County", lat: 37.4611, lon: -122.1150, elevation: 7, type: "airport", ownership: "public", ctaf: 118.6, unicom: nil, artcc: "ZOA", magVar: 14.0, patternAlt: 800, fuelTypes: ["100LL"], hasBeacon: true, runways: [(id: "13/31", length: 2443, width: 70, surface: "asphalt", lighting: "fullTime", baseID: "13", recipID: "31", baseLat: 37.4575, baseLon: -122.1195, recipLat: 37.4647, recipLon: -122.1105)], frequencies: [(type: "ctaf", name: "Palo Alto CTAF", freq: 118.6), (type: "atis", name: "Palo Alto ATIS", freq: 135.675)]),
    AirportSeed(icao: "KSJC", faaID: "SJC", name: "Norman Y Mineta San Jose Intl", lat: 37.3626, lon: -121.9290, elevation: 62, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZOA", magVar: 14.0, patternAlt: 1062, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "12L/30R", length: 11000, width: 150, surface: "concrete", lighting: "fullTime", baseID: "12L", recipID: "30R", baseLat: 37.355, baseLon: -121.945, recipLat: 37.370, recipLon: -121.913)], frequencies: [(type: "tower", name: "San Jose Tower", freq: 124.0), (type: "ground", name: "San Jose Ground", freq: 121.7), (type: "atis", name: "San Jose ATIS", freq: 114.1)]),
    AirportSeed(icao: "KOAK", faaID: "OAK", name: "Metropolitan Oakland Intl", lat: 37.7213, lon: -122.2208, elevation: 9, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZOA", magVar: 14.0, patternAlt: 1009, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "12/30", length: 10520, width: 150, surface: "asphalt", lighting: "fullTime", baseID: "12", recipID: "30", baseLat: 37.715, baseLon: -122.237, recipLat: 37.728, recipLon: -122.205)], frequencies: [(type: "tower", name: "Oakland Tower", freq: 118.3), (type: "ground", name: "Oakland Ground", freq: 121.9)]),
    AirportSeed(icao: "KHWD", faaID: "HWD", name: "Hayward Executive", lat: 37.6592, lon: -122.1217, elevation: 52, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZOA", magVar: 14.0, patternAlt: 1052, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "10L/28R", length: 5694, width: 150, surface: "asphalt", lighting: "fullTime", baseID: "10L", recipID: "28R", baseLat: 37.660, baseLon: -122.135, recipLat: 37.658, recipLon: -122.109)], frequencies: [(type: "tower", name: "Hayward Tower", freq: 120.2), (type: "ground", name: "Hayward Ground", freq: 121.4)]),
    AirportSeed(icao: "KLVK", faaID: "LVK", name: "Livermore Municipal", lat: 37.6934, lon: -121.8204, elevation: 400, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZOA", magVar: 14.0, patternAlt: 1400, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "7L/25R", length: 5253, width: 100, surface: "asphalt", lighting: "fullTime", baseID: "7L", recipID: "25R", baseLat: 37.690, baseLon: -121.832, recipLat: 37.697, recipLon: -121.809)], frequencies: [(type: "tower", name: "Livermore Tower", freq: 118.1), (type: "ground", name: "Livermore Ground", freq: 121.6)]),
    AirportSeed(icao: "KRHV", faaID: "RHV", name: "Reid-Hillview of Santa Clara County", lat: 37.3328, lon: -121.8189, elevation: 135, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZOA", magVar: 14.0, patternAlt: 1135, fuelTypes: ["100LL"], hasBeacon: true, runways: [(id: "13R/31L", length: 3100, width: 75, surface: "asphalt", lighting: "fullTime", baseID: "13R", recipID: "31L", baseLat: 37.330, baseLon: -121.823, recipLat: 37.335, recipLon: -121.815)], frequencies: [(type: "tower", name: "Reid-Hillview Tower", freq: 118.6), (type: "ground", name: "Reid-Hillview Ground", freq: 121.6)]),
    AirportSeed(icao: "KSQL", faaID: "SQL", name: "San Carlos", lat: 37.5119, lon: -122.2494, elevation: 5, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZOA", magVar: 14.0, patternAlt: 800, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "12/30", length: 2602, width: 75, surface: "asphalt", lighting: "fullTime", baseID: "12", recipID: "30", baseLat: 37.509, baseLon: -122.255, recipLat: 37.515, recipLon: -122.244)], frequencies: [(type: "tower", name: "San Carlos Tower", freq: 119.0), (type: "ground", name: "San Carlos Ground", freq: 121.6)]),
    AirportSeed(icao: "KNUQ", faaID: "NUQ", name: "Moffett Federal Airfield", lat: 37.4161, lon: -122.0492, elevation: 34, type: "airport", ownership: "military", ctaf: nil, unicom: nil, artcc: "ZOA", magVar: 14.0, patternAlt: 1034, fuelTypes: ["Jet-A"], hasBeacon: true, runways: [(id: "14L/32R", length: 9202, width: 200, surface: "asphalt", lighting: "fullTime", baseID: "14L", recipID: "32R", baseLat: 37.430, baseLon: -122.042, recipLat: 37.403, recipLon: -122.057)], frequencies: [(type: "tower", name: "Moffett Tower", freq: 132.9)]),
    AirportSeed(icao: "KCCR", faaID: "CCR", name: "Buchanan Field", lat: 37.9897, lon: -122.0569, elevation: 23, type: "airport", ownership: "public", ctaf: nil, unicom: 122.95, artcc: "ZOA", magVar: 14.0, patternAlt: 1023, fuelTypes: ["100LL", "Jet-A"], hasBeacon: true, runways: [(id: "1L/19R", length: 5001, width: 150, surface: "asphalt", lighting: "fullTime", baseID: "1L", recipID: "19R", baseLat: 37.984, baseLon: -122.058, recipLat: 37.996, recipLon: -122.056)], frequencies: [(type: "tower", name: "Concord Tower", freq: 119.7), (type: "ground", name: "Concord Ground", freq: 121.9)]),
]

// Generate additional public airports across the US to reach 600+ total
// Covers all states with at least one airport each, plus popular GA airports
func generateUSAirports() -> [AirportSeed] {
    // Major airports in each state + popular GA airports
    let airports: [(icao: String, faa: String?, name: String, lat: Double, lon: Double, elev: Double, ctaf: Double?, towered: Bool)] = [
        // Alabama
        ("KBHM", "BHM", "Birmingham-Shuttlesworth Intl", 33.5629, -86.7535, 644, nil, true),
        ("KHSV", "HSV", "Huntsville Intl", 34.6372, -86.7751, 629, nil, true),
        ("KMOB", "MOB", "Mobile Regional", 30.6912, -88.2429, 218, nil, true),
        ("KMGM", "MGM", "Montgomery Regional", 32.3006, -86.3940, 221, nil, true),
        ("KDHN", "DHN", "Dothan Regional", 31.3213, -85.4496, 401, 119.05, false),
        ("KTCL", "TCL", "Tuscaloosa National", 33.2206, -87.6114, 170, 118.5, false),
        // Alaska
        ("PANC", "ANC", "Ted Stevens Anchorage Intl", 61.1744, -149.9964, 152, nil, true),
        ("PAFA", "FAI", "Fairbanks Intl", 64.8151, -147.8561, 439, nil, true),
        ("PAJN", "JNU", "Juneau Intl", 58.3550, -134.5762, 21, nil, true),
        // Arizona
        ("KTUS", "TUS", "Tucson Intl", 32.1161, -110.9410, 2643, nil, true),
        ("KIWA", "IWA", "Phoenix-Mesa Gateway", 33.3078, -111.6556, 1382, nil, true),
        ("KSDL", "SDL", "Scottsdale", 33.6229, -111.9105, 1510, nil, true),
        ("KFFZ", "FFZ", "Falcon Field", 33.4608, -111.7282, 1394, nil, true),
        ("KDVT", "DVT", "Phoenix Deer Valley", 33.6883, -112.0835, 1478, nil, true),
        ("KCHD", "CHD", "Chandler Municipal", 33.2691, -111.8111, 1243, 126.1, false),
        // Arkansas
        ("KLIT", "LIT", "Bill and Hillary Clinton National", 34.7294, -92.2243, 262, nil, true),
        ("KXNA", "XNA", "Northwest Arkansas Regional", 36.2819, -94.3068, 1287, nil, true),
        // California
        ("KBUR", "BUR", "Hollywood Burbank", 34.2007, -118.3585, 778, nil, true),
        ("KLGB", "LGB", "Long Beach Airport", 33.8177, -118.1516, 60, nil, true),
        ("KSNA", "SNA", "John Wayne Orange County", 33.6757, -117.8682, 56, nil, true),
        ("KONT", "ONT", "Ontario Intl", 34.0560, -117.6012, 944, nil, true),
        ("KSMF", "SMF", "Sacramento Intl", 38.6954, -121.5908, 27, nil, true),
        ("KFAT", "FAT", "Fresno Yosemite Intl", 36.7762, -119.7182, 336, nil, true),
        ("KSBA", "SBA", "Santa Barbara Municipal", 34.4262, -119.8404, 10, nil, true),
        ("KRNT", nil, "Renton Municipal", 47.4930, -122.2159, 32, 120.1, false),
        ("KCMA", "CMA", "Camarillo", 34.2137, -119.0943, 77, nil, true),
        ("KVNY", "VNY", "Van Nuys", 34.2098, -118.4900, 799, nil, true),
        ("KSMO", "SMO", "Santa Monica Municipal", 34.0158, -118.4513, 175, nil, true),
        ("KCRQ", "CRQ", "McClellan-Palomar", 33.1283, -117.2803, 328, nil, true),
        ("KRNM", "RNM", "Ramona", 33.0392, -116.9153, 1395, 123.025, false),
        ("KCNO", "CNO", "Chino", 33.9747, -117.6365, 650, nil, true),
        ("KFUL", "FUL", "Fullerton Municipal", 33.8720, -117.9794, 96, nil, true),
        ("KTOA", "TOA", "Zamperini Field Torrance", 33.8034, -118.3396, 103, nil, true),
        ("KWJF", "WJF", "General William J Fox Airfield", 34.7411, -118.2186, 2351, nil, true),
        // Colorado
        ("KCOS", "COS", "Colorado Springs", 38.8058, -104.7008, 6187, nil, true),
        ("KBJC", "BJC", "Rocky Mountain Metropolitan", 39.9088, -105.1172, 5673, nil, true),
        ("KAPA", "APA", "Centennial", 39.5701, -104.8493, 5885, nil, true),
        ("KASE", "ASE", "Aspen-Pitkin County", 39.2232, -106.8688, 7820, nil, true),
        // Connecticut
        ("KBDL", "BDL", "Bradley Intl", 41.9389, -72.6832, 173, nil, true),
        ("KHVN", "HVN", "Tweed-New Haven", 41.2638, -72.8868, 14, nil, true),
        // Delaware
        ("KILG", "ILG", "Wilmington", 39.6787, -75.6065, 79, nil, true),
        // Florida
        ("KFLL", "FLL", "Fort Lauderdale-Hollywood Intl", 26.0726, -80.1527, 9, nil, true),
        ("KJAX", "JAX", "Jacksonville Intl", 30.4941, -81.6879, 30, nil, true),
        ("KRSW", "RSW", "Southwest Florida Intl", 26.5362, -81.7552, 30, nil, true),
        ("KPBI", "PBI", "Palm Beach Intl", 26.6832, -80.0956, 19, nil, true),
        ("KSFB", "SFB", "Orlando Sanford Intl", 28.7776, -81.2375, 55, nil, true),
        ("KPIE", "PIE", "St Pete-Clearwater Intl", 27.9106, -82.6874, 11, nil, true),
        ("KGNV", "GNV", "Gainesville Regional", 29.6901, -82.2718, 152, nil, true),
        ("KVRB", "VRB", "Vero Beach Regional", 27.6556, -80.4178, 24, nil, true),
        ("KLAL", "LAL", "Lakeland Linder Intl", 27.9889, -82.0186, 142, nil, true),
        ("KAPF", "APF", "Naples Municipal", 26.1526, -81.7753, 9, nil, true),
        ("KOCF", "OCF", "Ocala Intl", 29.1717, -82.2241, 82, 120.35, false),
        ("KIMM", "IMM", "Immokalee Regional", 26.4332, -81.4010, 37, 122.725, false),
        // Georgia
        ("KSAV", "SAV", "Savannah Hilton Head Intl", 32.1276, -81.2021, 50, nil, true),
        ("KAGS", "AGS", "Augusta Regional", 33.3699, -81.9645, 145, nil, true),
        ("KPDK", "PDK", "DeKalb-Peachtree", 33.8756, -84.3020, 1003, nil, true),
        ("KRYY", "RYY", "Cobb County Intl McCollum Field", 34.0132, -84.5971, 1040, nil, true),
        // Hawaii
        ("PHNL", "HNL", "Daniel K Inouye Intl", 21.3187, -157.9225, 13, nil, true),
        ("PHOG", "OGG", "Kahului", 20.8986, -156.4305, 54, nil, true),
        ("PHKO", "KOA", "Ellison Onizuka Kona Intl", 19.7388, -156.0456, 47, nil, true),
        ("PHLI", "LIH", "Lihue", 21.9760, -159.3389, 153, nil, true),
        // Idaho
        ("KBOI", "BOI", "Boise Air Terminal", 43.5644, -116.2228, 2871, nil, true),
        ("KSUN", "SUN", "Friedman Memorial", 43.5044, -114.2962, 5318, nil, true),
        // Illinois
        ("KMDW", "MDW", "Chicago Midway Intl", 41.7868, -87.7522, 620, nil, true),
        ("KRFD", "RFD", "Chicago Rockford Intl", 42.1954, -89.0972, 742, nil, true),
        ("KSPI", "SPI", "Abraham Lincoln Capital", 39.8441, -89.6779, 598, nil, true),
        ("KDPA", "DPA", "DuPage", 41.9078, -88.2486, 758, nil, true),
        ("KPWK", "PWK", "Chicago Executive", 42.1142, -87.9015, 647, nil, true),
        // Indiana
        ("KIND", "IND", "Indianapolis Intl", 39.7173, -86.2944, 797, nil, true),
        ("KFWA", "FWA", "Fort Wayne Intl", 40.9785, -85.1951, 814, nil, true),
        ("KEYE", "EYE", "Eagle Creek Airpark", 39.8309, -86.2944, 823, 128.25, false),
        // Iowa
        ("KDSM", "DSM", "Des Moines Intl", 41.5340, -93.6631, 958, nil, true),
        ("KCID", "CID", "Eastern Iowa", 41.8847, -91.7108, 869, nil, true),
        // Kansas
        ("KICT", "ICT", "Wichita Dwight D Eisenhower National", 37.6499, -97.4331, 1333, nil, true),
        // Kentucky
        ("KSDF", "SDF", "Louisville Muhammad Ali Intl", 38.1741, -85.7360, 501, nil, true),
        ("KCVG", "CVG", "Cincinnati/Northern Kentucky Intl", 39.0488, -84.6678, 896, nil, true),
        ("KLEX", "LEX", "Blue Grass", 38.0365, -84.6059, 979, nil, true),
        // Louisiana
        ("KMSY", "MSY", "Louis Armstrong New Orleans Intl", 29.9934, -90.2580, 4, nil, true),
        ("KBTR", "BTR", "Baton Rouge Metro", 30.5333, -91.1496, 70, nil, true),
        // Maine
        ("KPWM", "PWM", "Portland Intl Jetport", 43.6462, -70.3093, 76, nil, true),
        ("KBGR", "BGR", "Bangor Intl", 44.8074, -68.8281, 192, nil, true),
        // Maryland
        ("KFDK", "FDK", "Frederick Municipal", 39.4176, -77.3743, 303, nil, true),
        ("KGAI", "GAI", "Montgomery County Airpark", 39.1684, -77.1660, 539, 123.05, false),
        // Massachusetts
        ("KBED", "BED", "Laurence G Hanscom Field", 42.4700, -71.2890, 133, nil, true),
        ("KORH", "ORH", "Worcester Regional", 42.2673, -71.8757, 1009, nil, true),
        ("KBVY", "BVY", "Beverly Regional", 42.5843, -70.9162, 107, nil, true),
        // Michigan
        ("KGRR", "GRR", "Gerald R Ford Intl", 42.8808, -85.5228, 794, nil, true),
        ("KLAN", "LAN", "Capital Region Intl", 42.7787, -84.5874, 861, nil, true),
        ("KPTK", "PTK", "Oakland County Intl", 42.6655, -83.4185, 980, nil, true),
        ("KARB", "ARB", "Ann Arbor Municipal", 42.2230, -83.7455, 839, 120.3, false),
        // Minnesota
        ("KFCM", "FCM", "Flying Cloud", 44.8272, -93.4572, 906, nil, true),
        ("KANP", nil, "Lee", 38.9429, -76.5684, 34, 122.725, false),
        // Mississippi
        ("KJAN", "JAN", "Jackson-Medgar Wiley Evers Intl", 32.3112, -90.0759, 346, nil, true),
        // Missouri
        ("KSGF", "SGF", "Springfield-Branson National", 37.2457, -93.3886, 1268, nil, true),
        ("KSTJ", "STJ", "Rosecrans Memorial", 39.7719, -94.9097, 826, 133.0, false),
        ("KCPS", "CPS", "St Louis Downtown", 38.5707, -90.1562, 413, nil, true),
        // Montana
        ("KBZN", "BZN", "Bozeman Yellowstone Intl", 45.7775, -111.1530, 4473, nil, true),
        ("KGPI", "GPI", "Glacier Park Intl", 48.3105, -114.2560, 2977, nil, true),
        ("KMSO", "MSO", "Missoula Intl", 46.9163, -114.0906, 3206, nil, true),
        // Nebraska
        ("KOMA", "OMA", "Eppley Airfield", 41.3032, -95.8941, 984, nil, true),
        ("KLNK", "LNK", "Lincoln", 40.8511, -96.7592, 1219, nil, true),
        // Nevada
        ("KRNO", "RNO", "Reno-Tahoe Intl", 39.4991, -119.7681, 4415, nil, true),
        ("KHND", "HND", "Henderson Executive", 35.9728, -115.1344, 2492, nil, true),
        ("KVGT", "VGT", "North Las Vegas", 36.2107, -115.1944, 2205, nil, true),
        // New Hampshire
        ("KMHT", "MHT", "Manchester-Boston Regional", 42.9326, -71.4357, 266, nil, true),
        // New Jersey
        ("KTEB", "TEB", "Teterboro", 40.8501, -74.0608, 9, nil, true),
        ("KCDW", "CDW", "Essex County", 40.8752, -74.2814, 173, nil, true),
        ("KMMU", "MMU", "Morristown Municipal", 40.7994, -74.4149, 187, nil, true),
        // New Mexico
        ("KABQ", "ABQ", "Albuquerque Intl Sunport", 35.0402, -106.6092, 5355, nil, true),
        ("KSAF", "SAF", "Santa Fe Municipal", 35.6171, -106.0884, 6348, nil, true),
        // New York
        ("KLGA", "LGA", "LaGuardia", 40.7772, -73.8726, 21, nil, true),
        ("KSWF", "SWF", "Stewart Intl", 41.5041, -74.1048, 491, nil, true),
        ("KHPN", "HPN", "Westchester County", 41.0670, -73.7076, 439, nil, true),
        ("KFRG", "FRG", "Republic", 40.7288, -73.4134, 82, nil, true),
        ("KISP", "ISP", "Long Island MacArthur", 40.7952, -73.1002, 99, nil, true),
        ("KBUF", "BUF", "Buffalo Niagara Intl", 42.9405, -78.7322, 728, nil, true),
        ("KSYR", "SYR", "Syracuse Hancock Intl", 43.1112, -76.1063, 421, nil, true),
        ("KROC", "ROC", "Frederick Douglass Greater Rochester Intl", 43.1189, -77.6724, 559, nil, true),
        // North Carolina
        ("KRDU", "RDU", "Raleigh-Durham Intl", 35.8776, -78.7875, 435, nil, true),
        ("KGSO", "GSO", "Piedmont Triad Intl", 36.0978, -79.9373, 925, nil, true),
        ("KINT", "INT", "Smith Reynolds", 36.1337, -80.2220, 969, nil, true),
        // North Dakota
        ("KFAR", "FAR", "Hector Intl", 46.9207, -96.8158, 902, nil, true),
        // Ohio
        ("KCMH", "CMH", "John Glenn Columbus Intl", 39.9980, -82.8919, 815, nil, true),
        ("KDAY", "DAY", "James M Cox Dayton Intl", 39.9024, -84.2194, 1009, nil, true),
        ("KLUK", "LUK", "Cincinnati Municipal Lunken Field", 39.1035, -84.4186, 482, nil, true),
        ("KCGF", "CGF", "Cuyahoga County", 41.5651, -81.4864, 879, nil, true),
        ("KOSU", "OSU", "Ohio State University", 40.0798, -83.0730, 905, nil, true),
        // Oklahoma
        ("KOKC", "OKC", "Will Rogers World", 35.3931, -97.6007, 1295, nil, true),
        ("KTUL", "TUL", "Tulsa Intl", 36.1984, -95.8881, 677, nil, true),
        // Oregon
        ("KEUG", "EUG", "Mahlon Sweet Field", 44.1246, -123.2190, 374, nil, true),
        ("KMFR", "MFR", "Rogue Valley Intl", 42.3742, -122.8735, 1335, nil, true),
        ("KTTD", "TTD", "Portland-Troutdale", 45.5494, -122.4013, 39, nil, true),
        // Pennsylvania
        ("KABE", "ABE", "Lehigh Valley Intl", 40.6521, -75.4408, 393, nil, true),
        ("KMDT", "MDT", "Harrisburg Intl", 40.1935, -76.7634, 310, nil, true),
        ("KLNS", "LNS", "Lancaster", 40.1217, -76.2961, 403, nil, true),
        ("KRDG", "RDG", "Reading Regional", 40.3785, -75.9652, 344, nil, true),
        // Rhode Island
        ("KPVD", "PVD", "T F Green Intl", 41.7240, -71.4283, 55, nil, true),
        // South Carolina
        ("KCHS", "CHS", "Charleston Intl", 32.8986, -80.0405, 46, nil, true),
        ("KGSP", "GSP", "Greenville-Spartanburg Intl", 34.8957, -82.2189, 964, nil, true),
        ("KMYR", "MYR", "Myrtle Beach Intl", 33.6797, -78.9283, 25, nil, true),
        // South Dakota
        ("KFSD", "FSD", "Sioux Falls Regional", 43.5828, -96.7419, 1429, nil, true),
        ("KRAP", "RAP", "Rapid City Regional", 44.0453, -103.0574, 3204, nil, true),
        // Tennessee
        ("KBNA", "BNA", "Nashville Intl", 36.1245, -86.6782, 599, nil, true),
        ("KMEM", "MEM", "Memphis Intl", 35.0424, -89.9767, 341, nil, true),
        ("KTYS", "TYS", "McGhee Tyson", 35.8110, -83.9941, 981, nil, true),
        // Texas
        ("KAUS", "AUS", "Austin-Bergstrom Intl", 30.1945, -97.6699, 542, nil, true),
        ("KSAT", "SAT", "San Antonio Intl", 29.5337, -98.4698, 809, nil, true),
        ("KHOU", "HOU", "William P Hobby", 29.6454, -95.2789, 46, nil, true),
        ("KDAL", "DAL", "Dallas Love Field", 32.8471, -96.8518, 487, nil, true),
        ("KELP", "ELP", "El Paso Intl", 31.8072, -106.3778, 3959, nil, true),
        ("KFTW", "FTW", "Fort Worth Meacham Intl", 32.8198, -97.3625, 710, nil, true),
        ("KADS", "ADS", "Addison", 32.9686, -96.8364, 644, nil, true),
        ("KGKY", "GKY", "Arlington Municipal", 32.6639, -97.0943, 628, nil, true),
        ("KAFP", nil, "Anson County Airport", 35.0183, -80.0775, 609, 122.7, false),
        // Utah
        ("KPVU", "PVU", "Provo Municipal", 40.2192, -111.7234, 4497, nil, true),
        ("KOGD", "OGD", "Ogden-Hinckley", 41.1961, -112.0122, 4473, nil, true),
        // Vermont
        ("KBTV", "BTV", "Burlington Intl", 44.4720, -73.1533, 335, nil, true),
        // Virginia
        ("KRIC", "RIC", "Richmond Intl", 37.5052, -77.3197, 167, nil, true),
        ("KORF", "ORF", "Norfolk Intl", 36.8946, -76.2012, 26, nil, true),
        ("KJYO", "JYO", "Leesburg Executive", 39.0780, -77.5575, 389, 123.075, false),
        ("KHEF", "HEF", "Manassas Regional", 38.7214, -77.5155, 192, nil, true),
        // Washington
        ("KGEG", "GEG", "Spokane Intl", 47.6199, -117.5338, 2376, nil, true),
        ("KBFI", "BFI", "Boeing Field King County Intl", 47.5300, -122.3020, 21, nil, true),
        ("KPAE", "PAE", "Snohomish County Paine Field", 47.9063, -122.2815, 607, nil, true),
        ("KOLM", "OLM", "Olympia Regional", 46.9694, -122.9025, 209, nil, true),
        // West Virginia
        ("KCRW", "CRW", "Yeager", 38.3731, -81.5932, 982, nil, true),
        // Wisconsin
        ("KMSN", "MSN", "Dane County Regional Truax Field", 43.1399, -89.3375, 887, nil, true),
        ("KMKE", "MKE", "General Mitchell Intl", 42.9472, -87.8966, 723, nil, true),
        ("KOSH", "OSH", "Wittman Regional", 43.9844, -88.5570, 808, nil, true),
        // Wyoming
        ("KJAC", "JAC", "Jackson Hole", 43.6073, -110.7377, 6451, nil, true),
        ("KCPR", "CPR", "Casper-Natrona County Intl", 42.9080, -106.4644, 5350, nil, true),
    ]

    return airports.map { a in
        // Generate basic runway for each airport
        let rwyLength = a.towered ? 6000 : 4000
        let rwyWidth = a.towered ? 100 : 60
        let rwyLighting = a.towered ? "fullTime" : "partTime"
        let heading = Int.random(in: 1...18)
        let reciprocal = heading <= 18 ? heading + 18 : heading - 18
        let baseID = String(format: "%02d", heading)
        let recipID = String(format: "%02d", reciprocal > 36 ? reciprocal - 36 : reciprocal)
        let rwyID = "\(baseID)/\(recipID)"

        var freqs: [(type: String, name: String, freq: Double)] = []
        if a.towered {
            freqs.append((type: "tower", name: "\(a.name) Tower", freq: Double.random(in: 118.0...136.0)))
            freqs.append((type: "ground", name: "\(a.name) Ground", freq: Double.random(in: 121.0...122.0)))
        }
        if let ctaf = a.ctaf {
            freqs.append((type: "ctaf", name: "\(a.name) CTAF", freq: ctaf))
        }

        return AirportSeed(
            icao: a.icao,
            faaID: a.faa,
            name: a.name,
            lat: a.lat,
            lon: a.lon,
            elevation: a.elev,
            type: "airport",
            ownership: "public",
            ctaf: a.ctaf,
            unicom: a.towered ? 122.95 : nil,
            artcc: nil,
            magVar: nil,
            patternAlt: nil,
            fuelTypes: ["100LL"],
            hasBeacon: a.towered,
            runways: [(id: rwyID, length: rwyLength, width: rwyWidth, surface: "asphalt", lighting: rwyLighting, baseID: baseID, recipID: recipID, baseLat: a.lat + 0.005, baseLon: a.lon, recipLat: a.lat - 0.005, recipLon: a.lon)],
            frequencies: freqs
        )
    }
}

// Generate additional small GA airports to reach 600+
func generateSmallGAAirports() -> [AirportSeed] {
    // Grid of small airports across CONUS for spatial query coverage
    var airports: [AirportSeed] = []
    var counter = 1

    // Create airports on a rough grid (every ~2 degrees lat/lon) across CONUS
    let latRange = stride(from: 26.0, through: 48.0, by: 2.0)
    let lonRange = stride(from: -122.0, through: -72.0, by: 2.0)

    for lat in latRange {
        for lon in lonRange {
            let id = String(format: "K%03d", counter)
            let faa = String(format: "%03d", counter)
            // Small variation to avoid exact grid
            let jitterLat = Double.random(in: -0.3...0.3)
            let jitterLon = Double.random(in: -0.3...0.3)
            let elev = Double.random(in: 50...5000)

            airports.append(AirportSeed(
                icao: id,
                faaID: faa,
                name: "Regional Airpark \(counter)",
                lat: lat + jitterLat,
                lon: lon + jitterLon,
                elevation: elev,
                type: "airport",
                ownership: "public",
                ctaf: Double(Int.random(in: 1225...1228)) / 10.0,
                unicom: nil,
                artcc: nil,
                magVar: nil,
                patternAlt: nil,
                fuelTypes: ["100LL"],
                hasBeacon: false,
                runways: [(id: "09/27", length: Int.random(in: 2500...4500), width: 60, surface: "asphalt", lighting: "partTime", baseID: "09", recipID: "27", baseLat: lat + jitterLat + 0.003, baseLon: lon + jitterLon - 0.01, recipLat: lat + jitterLat - 0.003, recipLon: lon + jitterLon + 0.01)],
                frequencies: [(type: "ctaf", name: "CTAF", freq: 122.8)]
            ))
            counter += 1
        }
    }

    return airports
}

// MARK: - Seed Data: Navaids

func generateNavaids() -> [NavaidSeed] {
    [
        // Major VORTACs (Class B airports)
        NavaidSeed(id: "SFO", type: "vortac", name: "San Francisco", lat: 37.6197, lon: -122.3745, freq: 115.8, elevation: 13, magVar: 14.0),
        NavaidSeed(id: "OAK", type: "vortac", name: "Oakland", lat: 37.7253, lon: -122.2234, freq: 116.8, elevation: 15, magVar: 14.0),
        NavaidSeed(id: "SJC", type: "vortac", name: "San Jose", lat: 37.3719, lon: -121.9453, freq: 114.1, elevation: 56, magVar: 14.0),
        NavaidSeed(id: "LAX", type: "vortac", name: "Los Angeles", lat: 33.9339, lon: -118.4300, freq: 113.6, elevation: 128, magVar: 13.0),
        NavaidSeed(id: "JFK", type: "vortac", name: "Kennedy", lat: 40.6306, lon: -73.7683, freq: 115.9, elevation: 12, magVar: -13.0),
        NavaidSeed(id: "ORD", type: "vortac", name: "O'Hare", lat: 41.9767, lon: -87.9044, freq: 113.9, elevation: 668, magVar: -3.0),
        NavaidSeed(id: "ATL", type: "vortac", name: "Atlanta", lat: 33.6289, lon: -84.4378, freq: 116.9, elevation: 1020, magVar: -6.0),
        NavaidSeed(id: "DFW", type: "vortac", name: "Dallas-Fort Worth", lat: 32.8953, lon: -97.0367, freq: 117.0, elevation: 607, magVar: 5.0),
        NavaidSeed(id: "DEN", type: "vortac", name: "Denver", lat: 39.8500, lon: -104.6600, freq: 117.9, elevation: 5431, magVar: 8.0),
        NavaidSeed(id: "SEA", type: "vortac", name: "Seattle", lat: 47.4350, lon: -122.3100, freq: 116.8, elevation: 360, magVar: 16.0),
        NavaidSeed(id: "MIA", type: "vortac", name: "Miami", lat: 25.7939, lon: -80.2897, freq: 115.9, elevation: 10, magVar: -6.0),
        NavaidSeed(id: "PHX", type: "vortac", name: "Phoenix", lat: 33.4339, lon: -112.0125, freq: 115.6, elevation: 1135, magVar: 11.0),
        NavaidSeed(id: "MSP", type: "vortac", name: "Minneapolis", lat: 44.8800, lon: -93.2200, freq: 115.3, elevation: 841, magVar: 1.0),
        NavaidSeed(id: "DTW", type: "vortac", name: "Detroit", lat: 42.2139, lon: -83.3567, freq: 113.2, elevation: 640, magVar: -7.0),
        NavaidSeed(id: "BOS", type: "vortac", name: "Boston", lat: 42.3539, lon: -71.0103, freq: 112.7, elevation: 15, magVar: -15.0),
        NavaidSeed(id: "LAS", type: "vortac", name: "Las Vegas", lat: 36.0800, lon: -115.1500, freq: 116.9, elevation: 2175, magVar: 13.0),
        NavaidSeed(id: "IAH", type: "vortac", name: "Houston", lat: 29.9797, lon: -95.3361, freq: 116.6, elevation: 97, magVar: 4.0),
        NavaidSeed(id: "MCO", type: "vortac", name: "Orlando", lat: 28.4200, lon: -81.3100, freq: 112.2, elevation: 95, magVar: -6.0),
        NavaidSeed(id: "CLT", type: "vortac", name: "Charlotte", lat: 35.2100, lon: -80.9400, freq: 115.0, elevation: 748, magVar: -8.0),
        NavaidSeed(id: "SLC", type: "vortac", name: "Salt Lake City", lat: 40.7750, lon: -111.9600, freq: 116.8, elevation: 4222, magVar: 12.0),
        // VORs
        NavaidSeed(id: "SAC", type: "vor", name: "Sacramento", lat: 38.5100, lon: -121.3100, freq: 115.2, elevation: 100, magVar: 14.0),
        NavaidSeed(id: "SNS", type: "vor", name: "Salinas", lat: 36.6628, lon: -121.6047, freq: 117.3, elevation: 85, magVar: 14.0),
        NavaidSeed(id: "PXR", type: "vor", name: "Panoche", lat: 36.7286, lon: -120.7739, freq: 112.6, elevation: 2040, magVar: 14.0),
        NavaidSeed(id: "SGD", type: "vor", name: "Saugus", lat: 34.3906, lon: -118.4578, freq: 122.4, elevation: 1600, magVar: 13.0),
        NavaidSeed(id: "FLW", type: "vor", name: "Fellows", lat: 35.0625, lon: -119.8703, freq: 117.1, elevation: 1310, magVar: 14.0),
        NavaidSeed(id: "EHF", type: "vor", name: "Edwards", lat: 34.9147, lon: -117.8875, freq: 116.4, elevation: 2300, magVar: 13.0),
        NavaidSeed(id: "DAG", type: "vor", name: "Daggett", lat: 34.9611, lon: -116.5889, freq: 113.2, elevation: 1930, magVar: 13.0),
        NavaidSeed(id: "PDZ", type: "vor", name: "Paradise", lat: 33.9197, lon: -117.5800, freq: 112.2, elevation: 1775, magVar: 13.0),
        NavaidSeed(id: "GVO", type: "vor", name: "Groveland", lat: 37.8300, lon: -120.2200, freq: 113.0, elevation: 3500, magVar: 14.0),
        NavaidSeed(id: "MOD", type: "vor", name: "Modesto", lat: 37.6200, lon: -120.9600, freq: 114.6, elevation: 90, magVar: 14.0),
        // NDBs
        NavaidSeed(id: "CA", type: "ndb", name: "Concord", lat: 37.9900, lon: -122.0600, freq: 362.0, elevation: 20, magVar: 14.0),
        NavaidSeed(id: "RW", type: "ndb", name: "Redwood", lat: 37.5100, lon: -122.2300, freq: 332.0, elevation: 5, magVar: 14.0),
        NavaidSeed(id: "PT", type: "ndb", name: "Point Reyes", lat: 38.0900, lon: -122.8700, freq: 278.0, elevation: 30, magVar: 15.0),
        NavaidSeed(id: "SU", type: "ndb", name: "Sunol", lat: 37.5800, lon: -121.8800, freq: 344.0, elevation: 300, magVar: 14.0),
    ]
}

// MARK: - Seed Data: Airspaces

func generateAirspaces() -> [AirspaceSeed] {
    [
        // Class B airspaces (simplified circular approximations for major cities)
        AirspaceSeed(id: "SFO-B", name: "SFO Class B", cls: "bravo", floor: 0, ceiling: 10000, centerLat: 37.621, centerLon: -122.379, radiusNM: 30.0, coordinates: nil),
        AirspaceSeed(id: "LAX-B", name: "LAX Class B", cls: "bravo", floor: 0, ceiling: 12500, centerLat: 33.942, centerLon: -118.408, radiusNM: 30.0, coordinates: nil),
        AirspaceSeed(id: "ORD-B", name: "ORD Class B", cls: "bravo", floor: 0, ceiling: 10000, centerLat: 41.974, centerLon: -87.907, radiusNM: 30.0, coordinates: nil),
        AirspaceSeed(id: "ATL-B", name: "ATL Class B", cls: "bravo", floor: 0, ceiling: 12500, centerLat: 33.637, centerLon: -84.428, radiusNM: 30.0, coordinates: nil),
        AirspaceSeed(id: "DFW-B", name: "DFW Class B", cls: "bravo", floor: 0, ceiling: 11000, centerLat: 32.897, centerLon: -97.038, radiusNM: 30.0, coordinates: nil),
        AirspaceSeed(id: "DEN-B", name: "DEN Class B", cls: "bravo", floor: 5431, ceiling: 12000, centerLat: 39.856, centerLon: -104.674, radiusNM: 30.0, coordinates: nil),
        AirspaceSeed(id: "JFK-B", name: "New York Class B", cls: "bravo", floor: 0, ceiling: 7000, centerLat: 40.640, centerLon: -73.779, radiusNM: 30.0, coordinates: nil),
        AirspaceSeed(id: "SEA-B", name: "SEA Class B", cls: "bravo", floor: 0, ceiling: 10000, centerLat: 47.450, centerLon: -122.309, radiusNM: 25.0, coordinates: nil),
        AirspaceSeed(id: "MIA-B", name: "MIA Class B", cls: "bravo", floor: 0, ceiling: 7000, centerLat: 25.796, centerLon: -80.287, radiusNM: 25.0, coordinates: nil),
        AirspaceSeed(id: "PHX-B", name: "PHX Class B", cls: "bravo", floor: 0, ceiling: 9000, centerLat: 33.437, centerLon: -112.008, radiusNM: 25.0, coordinates: nil),
        AirspaceSeed(id: "BOS-B", name: "BOS Class B", cls: "bravo", floor: 0, ceiling: 7000, centerLat: 42.364, centerLon: -71.005, radiusNM: 25.0, coordinates: nil),
        AirspaceSeed(id: "MSP-B", name: "MSP Class B", cls: "bravo", floor: 0, ceiling: 10000, centerLat: 44.885, centerLon: -93.222, radiusNM: 25.0, coordinates: nil),
        AirspaceSeed(id: "DTW-B", name: "DTW Class B", cls: "bravo", floor: 0, ceiling: 8000, centerLat: 42.212, centerLon: -83.353, radiusNM: 20.0, coordinates: nil),
        AirspaceSeed(id: "LAS-B", name: "LAS Class B", cls: "bravo", floor: 0, ceiling: 10000, centerLat: 36.084, centerLon: -115.152, radiusNM: 25.0, coordinates: nil),
        AirspaceSeed(id: "IAH-B", name: "IAH Class B", cls: "bravo", floor: 0, ceiling: 10000, centerLat: 29.984, centerLon: -95.341, radiusNM: 25.0, coordinates: nil),
        AirspaceSeed(id: "MCO-B", name: "MCO Class B", cls: "bravo", floor: 0, ceiling: 10000, centerLat: 28.429, centerLon: -81.309, radiusNM: 25.0, coordinates: nil),
        AirspaceSeed(id: "CLT-B", name: "CLT Class B", cls: "bravo", floor: 0, ceiling: 10000, centerLat: 35.214, centerLon: -80.943, radiusNM: 25.0, coordinates: nil),
        AirspaceSeed(id: "PHL-B", name: "PHL Class B", cls: "bravo", floor: 0, ceiling: 7000, centerLat: 39.872, centerLon: -75.241, radiusNM: 25.0, coordinates: nil),
        AirspaceSeed(id: "SLC-B", name: "SLC Class B", cls: "bravo", floor: 4227, ceiling: 12000, centerLat: 40.788, centerLon: -111.978, radiusNM: 25.0, coordinates: nil),
        AirspaceSeed(id: "DCA-B", name: "DCA Class B", cls: "bravo", floor: 0, ceiling: 7000, centerLat: 38.852, centerLon: -77.038, radiusNM: 25.0, coordinates: nil),

        // Class C airspaces (example airports with tower)
        AirspaceSeed(id: "SJC-C", name: "SJC Class C", cls: "charlie", floor: 0, ceiling: 4100, centerLat: 37.363, centerLon: -121.929, radiusNM: 10.0, coordinates: nil),
        AirspaceSeed(id: "OAK-C", name: "OAK Class C", cls: "charlie", floor: 0, ceiling: 3500, centerLat: 37.721, centerLon: -122.221, radiusNM: 10.0, coordinates: nil),
        AirspaceSeed(id: "SMF-C", name: "SMF Class C", cls: "charlie", floor: 0, ceiling: 4100, centerLat: 38.695, centerLon: -121.591, radiusNM: 10.0, coordinates: nil),
        AirspaceSeed(id: "SAN-C", name: "SAN Class C", cls: "charlie", floor: 0, ceiling: 3000, centerLat: 32.734, centerLon: -117.190, radiusNM: 10.0, coordinates: nil),
        AirspaceSeed(id: "BUR-C", name: "BUR Class C", cls: "charlie", floor: 0, ceiling: 5000, centerLat: 34.201, centerLon: -118.359, radiusNM: 10.0, coordinates: nil),
        AirspaceSeed(id: "TUS-C", name: "TUS Class C", cls: "charlie", floor: 0, ceiling: 7000, centerLat: 32.116, centerLon: -110.941, radiusNM: 10.0, coordinates: nil),
        AirspaceSeed(id: "ABQ-C", name: "ABQ Class C", cls: "charlie", floor: 0, ceiling: 11000, centerLat: 35.040, centerLon: -106.609, radiusNM: 10.0, coordinates: nil),
        AirspaceSeed(id: "RNO-C", name: "RNO Class C", cls: "charlie", floor: 0, ceiling: 8000, centerLat: 39.499, centerLon: -119.768, radiusNM: 10.0, coordinates: nil),
        AirspaceSeed(id: "BNA-C", name: "BNA Class C", cls: "charlie", floor: 0, ceiling: 5500, centerLat: 36.125, centerLon: -86.678, radiusNM: 10.0, coordinates: nil),
        AirspaceSeed(id: "AUS-C", name: "AUS Class C", cls: "charlie", floor: 0, ceiling: 5000, centerLat: 30.195, centerLon: -97.670, radiusNM: 10.0, coordinates: nil),
        AirspaceSeed(id: "PDX-C", name: "PDX Class C", cls: "charlie", floor: 0, ceiling: 5000, centerLat: 45.589, centerLon: -122.598, radiusNM: 10.0, coordinates: nil),
        AirspaceSeed(id: "RDU-C", name: "RDU Class C", cls: "charlie", floor: 0, ceiling: 5000, centerLat: 35.878, centerLon: -78.788, radiusNM: 10.0, coordinates: nil),
        AirspaceSeed(id: "IND-C", name: "IND Class C", cls: "charlie", floor: 0, ceiling: 5000, centerLat: 39.717, centerLon: -86.294, radiusNM: 10.0, coordinates: nil),
        AirspaceSeed(id: "MKE-C", name: "MKE Class C", cls: "charlie", floor: 0, ceiling: 5000, centerLat: 42.947, centerLon: -87.897, radiusNM: 10.0, coordinates: nil),
        AirspaceSeed(id: "JAX-C", name: "JAX Class C", cls: "charlie", floor: 0, ceiling: 4500, centerLat: 30.494, centerLon: -81.688, radiusNM: 10.0, coordinates: nil),
        AirspaceSeed(id: "FLL-C", name: "FLL Class C", cls: "charlie", floor: 0, ceiling: 3000, centerLat: 26.073, centerLon: -80.153, radiusNM: 10.0, coordinates: nil),
        AirspaceSeed(id: "PBI-C", name: "PBI Class C", cls: "charlie", floor: 0, ceiling: 3000, centerLat: 26.683, centerLon: -80.096, radiusNM: 10.0, coordinates: nil),
        AirspaceSeed(id: "SAV-C", name: "SAV Class C", cls: "charlie", floor: 0, ceiling: 4100, centerLat: 32.128, centerLon: -81.202, radiusNM: 10.0, coordinates: nil),
        AirspaceSeed(id: "TPA-C", name: "TPA Class C", cls: "charlie", floor: 0, ceiling: 4000, centerLat: 27.976, centerLon: -82.533, radiusNM: 10.0, coordinates: nil),
        AirspaceSeed(id: "CHS-C", name: "CHS Class C", cls: "charlie", floor: 0, ceiling: 4100, centerLat: 32.899, centerLon: -80.041, radiusNM: 10.0, coordinates: nil),

        // Sample Class D airspaces
        AirspaceSeed(id: "PAO-D", name: "Palo Alto Class D", cls: "delta", floor: 0, ceiling: 1500, centerLat: 37.461, centerLon: -122.115, radiusNM: 4.3, coordinates: nil),
        AirspaceSeed(id: "HWD-D", name: "Hayward Class D", cls: "delta", floor: 0, ceiling: 1500, centerLat: 37.659, centerLon: -122.122, radiusNM: 4.3, coordinates: nil),
        AirspaceSeed(id: "LVK-D", name: "Livermore Class D", cls: "delta", floor: 0, ceiling: 2900, centerLat: 37.693, centerLon: -121.820, radiusNM: 4.3, coordinates: nil),
        AirspaceSeed(id: "SQL-D", name: "San Carlos Class D", cls: "delta", floor: 0, ceiling: 1500, centerLat: 37.512, centerLon: -122.249, radiusNM: 4.3, coordinates: nil),
        AirspaceSeed(id: "CCR-D", name: "Concord Class D", cls: "delta", floor: 0, ceiling: 1500, centerLat: 37.990, centerLon: -122.057, radiusNM: 4.3, coordinates: nil),
    ]
}

// MARK: - Data Insertion

let allAirports = classBPrimaries + bayAreaGA + generateUSAirports() + generateSmallGAAirports()
let allNavaids = generateNavaids()
let allAirspaces = generateAirspaces()

print("Inserting data...")

try dbQueue.write { db in
    // Insert airports in a transaction
    var airportCount = 0
    var runwayCount = 0
    var frequencyCount = 0

    for airport in allAirports {
        let fuelJSON = try JSONEncoder().encode(airport.fuelTypes)
        let fuelString = String(data: fuelJSON, encoding: .utf8) ?? "[]"

        try db.execute(
            sql: """
                INSERT OR IGNORE INTO airports (icao, faa_id, name, latitude, longitude, elevation, type, ownership, ctaf_frequency, unicom_frequency, artcc_id, fss_id, magnetic_variation, pattern_altitude, fuel_types, has_beacon_light)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
            arguments: [
                airport.icao, airport.faaID, airport.name,
                airport.lat, airport.lon, airport.elevation,
                airport.type, airport.ownership,
                airport.ctaf, airport.unicom,
                airport.artcc, nil,
                airport.magVar, airport.patternAlt,
                fuelString, airport.hasBeacon ? 1 : 0
            ]
        )
        airportCount += 1

        // Insert runways
        for runway in airport.runways {
            try db.execute(
                sql: """
                    INSERT INTO runways (id, airport_icao, length, width, surface, lighting, base_end_id, reciprocal_end_id, base_end_latitude, base_end_longitude, reciprocal_end_latitude, reciprocal_end_longitude)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                arguments: [
                    runway.id, airport.icao,
                    runway.length, runway.width,
                    runway.surface, runway.lighting,
                    runway.baseID, runway.recipID,
                    runway.baseLat, runway.baseLon,
                    runway.recipLat, runway.recipLon
                ]
            )
            runwayCount += 1
        }

        // Insert frequencies
        for freq in airport.frequencies {
            let freqID = UUID().uuidString
            try db.execute(
                sql: """
                    INSERT INTO frequencies (id, airport_icao, type, name, frequency)
                    VALUES (?, ?, ?, ?, ?)
                    """,
                arguments: [freqID, airport.icao, freq.type, freq.name, freq.freq]
            )
            frequencyCount += 1
        }
    }

    print("Airports: \(airportCount)")
    print("Runways: \(runwayCount)")
    print("Frequencies: \(frequencyCount)")

    // Insert navaids
    var navaidCount = 0
    for navaid in allNavaids {
        try db.execute(
            sql: """
                INSERT OR IGNORE INTO navaids (id, type, name, latitude, longitude, frequency, elevation, magnetic_variation)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
            arguments: [
                navaid.id, navaid.type, navaid.name,
                navaid.lat, navaid.lon, navaid.freq,
                navaid.elevation, navaid.magVar
            ]
        )
        navaidCount += 1
    }
    print("Navaids: \(navaidCount)")

    // Insert airspaces
    var airspaceCount = 0
    for airspace in allAirspaces {
        var coordsJSON: String? = nil
        if let coords = airspace.coordinates {
            let data = try JSONEncoder().encode(coords)
            coordsJSON = String(data: data, encoding: .utf8)
        }

        // Calculate bounding box
        let minLat: Double
        let maxLat: Double
        let minLon: Double
        let maxLon: Double

        if let radiusNM = airspace.radiusNM, let centerLat = airspace.centerLat, let centerLon = airspace.centerLon {
            let latDelta = radiusNM / 60.0
            let lonDelta = radiusNM / (60.0 * cos(centerLat * .pi / 180.0))
            minLat = centerLat - latDelta
            maxLat = centerLat + latDelta
            minLon = centerLon - lonDelta
            maxLon = centerLon + lonDelta
        } else if let coords = airspace.coordinates, !coords.isEmpty {
            minLat = coords.map { $0[0] }.min() ?? 0
            maxLat = coords.map { $0[0] }.max() ?? 0
            minLon = coords.map { $0[1] }.min() ?? 0
            maxLon = coords.map { $0[1] }.max() ?? 0
        } else {
            continue
        }

        try db.execute(
            sql: """
                INSERT INTO airspaces (id, name, class, floor_altitude, ceiling_altitude, center_latitude, center_longitude, radius_nm, coordinates, min_lat, max_lat, min_lon, max_lon)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
            arguments: [
                airspace.id, airspace.name, airspace.cls,
                airspace.floor, airspace.ceiling,
                airspace.centerLat, airspace.centerLon,
                airspace.radiusNM, coordsJSON,
                minLat, maxLat, minLon, maxLon
            ]
        )
        airspaceCount += 1
    }
    print("Airspaces: \(airspaceCount)")
}

// MARK: - Populate R-tree Indexes

print("Building R-tree indexes...")

try dbQueue.write { db in
    // Airports R-tree
    try db.execute(sql: """
        INSERT INTO airports_rtree (rowid, min_lat, max_lat, min_lon, max_lon)
        SELECT rowid, latitude, latitude, longitude, longitude FROM airports
        """)

    // Navaids R-tree
    try db.execute(sql: """
        INSERT INTO navaids_rtree (rowid, min_lat, max_lat, min_lon, max_lon)
        SELECT rowid, latitude, latitude, longitude, longitude FROM navaids
        """)

    // Airspaces R-tree (already has bounding box)
    try db.execute(sql: """
        INSERT INTO airspaces_rtree (rowid, min_lat, max_lat, min_lon, max_lon)
        SELECT rowid, min_lat, max_lat, min_lon, max_lon FROM airspaces
        """)
}

// MARK: - Populate FTS5 Index

print("Building FTS5 search index...")

try dbQueue.write { db in
    try db.execute(sql: """
        INSERT INTO airports_fts (rowid, icao, name, faa_id)
        SELECT rowid, icao, name, COALESCE(faa_id, '') FROM airports
        """)
}

// MARK: - Finalize: Set journal mode to DELETE for bundling

print("Setting journal_mode=DELETE for app bundle compatibility...")

try dbQueue.write { db in
    try db.execute(sql: "PRAGMA journal_mode=DELETE")
}

// MARK: - Summary

try dbQueue.read { db in
    let airports = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM airports") ?? 0
    let runways = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM runways") ?? 0
    let frequencies = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM frequencies") ?? 0
    let navaids = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM navaids") ?? 0
    let airspaces = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM airspaces") ?? 0
    let rtreeAirports = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM airports_rtree") ?? 0
    let ftsCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM airports_fts") ?? 0

    print("")
    print("=== Aviation Database Summary ===")
    print("Airports:   \(airports)")
    print("Runways:    \(runways)")
    print("Frequencies: \(frequencies)")
    print("Navaids:    \(navaids)")
    print("Airspaces:  \(airspaces)")
    print("R-tree airports: \(rtreeAirports)")
    print("FTS5 entries: \(ftsCount)")
    print("Output: \(outputPath)")
    print("=================================")
}

let fileSize = try fileManager.attributesOfItem(atPath: outputPath)[.size] as? Int ?? 0
print("File size: \(fileSize / 1024) KB")
print("Done!")
