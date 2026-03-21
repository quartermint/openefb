//
//  NASR Importer
//  Generates a bundled aviation.sqlite database for OpenEFB.
//
//  Downloads OurAirports CSV data (FAA-derived, 20K+ US airports) and builds
//  a pre-built SQLite database with airports, runways, frequencies, navaids,
//  and airspaces. Includes R-tree spatial indexes and FTS5 full-text search.
//
//  Usage:
//    swift run nasr-importer --download --output efb-212/Resources/aviation.sqlite
//    swift run nasr-importer --data-dir ./csv-data --output aviation.sqlite
//

import Foundation
import GRDB
import ArgumentParser

// MARK: - CLI

@main
struct NASRImporter: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "nasr-importer",
        abstract: "Generate aviation.sqlite from OurAirports CSV data for OpenEFB."
    )

    @Flag(name: .long, help: "Download CSVs from ourairports.com/data/")
    var download = false

    @Option(name: .long, help: "Path to directory containing pre-downloaded CSVs")
    var dataDir: String?

    @Option(name: .long, help: "Output path for aviation.sqlite")
    var output: String = "aviation.sqlite"

    func run() throws {
        print("NASR Importer - OpenEFB Aviation Database Generator")
        print("Output: \(output)")

        let csvDir: String
        var tempDir: URL?

        if download {
            print("Downloading OurAirports CSV data...")
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("nasr-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
            tempDir = tmp

            let semaphore = DispatchSemaphore(value: 0)
            var downloadError: Error?

            Task {
                do {
                    try await downloadCSVs(to: tmp.path)
                } catch {
                    downloadError = error
                }
                semaphore.signal()
            }
            semaphore.wait()

            if let error = downloadError {
                throw error
            }

            csvDir = tmp.path
        } else if let dir = dataDir {
            csvDir = dir
        } else {
            throw ValidationError("Provide --download or --data-dir <path>")
        }

        try generateDatabase(csvDir: csvDir, outputPath: output)

        // Cleanup temp dir
        if let tmp = tempDir {
            try? FileManager.default.removeItem(at: tmp)
        }

        print("Done!")
    }
}

// MARK: - CSV Download

func downloadCSVs(to directory: String) async throws {
    let baseURL = "https://ourairports.com/data/"
    let files = ["airports.csv", "runways.csv", "airport-frequencies.csv", "navaids.csv"]

    for file in files {
        let url = URL(string: baseURL + file)!
        print("  Downloading \(file)...")
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "NASRImporter", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to download \(file)"])
        }
        let filePath = (directory as NSString).appendingPathComponent(file)
        try data.write(to: URL(fileURLWithPath: filePath))
        print("    \(data.count / 1024) KB")
    }
}

// MARK: - CSV Parsing

/// Parse a CSV line handling quoted fields with embedded commas and newlines.
func parseCSVLine(_ line: String) -> [String] {
    var fields: [String] = []
    var current = ""
    var inQuotes = false
    var i = line.startIndex

    while i < line.endIndex {
        let ch = line[i]
        if inQuotes {
            if ch == "\"" {
                let next = line.index(after: i)
                if next < line.endIndex && line[next] == "\"" {
                    // Escaped quote
                    current.append("\"")
                    i = line.index(after: next)
                    continue
                } else {
                    inQuotes = false
                }
            } else {
                current.append(ch)
            }
        } else {
            if ch == "\"" {
                inQuotes = true
            } else if ch == "," {
                fields.append(current)
                current = ""
            } else {
                current.append(ch)
            }
        }
        i = line.index(after: i)
    }
    fields.append(current)
    return fields
}

/// Parse a CSV file into an array of dictionaries keyed by header names.
func parseCSV(at path: String) throws -> (headers: [String], rows: [[String]]) {
    let content = try String(contentsOfFile: path, encoding: .utf8)
    let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
    guard let headerLine = lines.first else {
        return ([], [])
    }
    let headers = parseCSVLine(headerLine)
    var rows: [[String]] = []
    for line in lines.dropFirst() {
        let fields = parseCSVLine(line)
        if fields.count >= headers.count / 2 { // Accept rows with at least half the expected fields
            rows.append(fields)
        }
    }
    return (headers, rows)
}

/// Get the value at a specific header index from a row, safely.
func fieldValue(_ row: [String], index: Int?) -> String {
    guard let idx = index, idx < row.count else { return "" }
    return row[idx]
}

func doubleValue(_ row: [String], index: Int?) -> Double? {
    let val = fieldValue(row, index: index)
    return Double(val)
}

func intValue(_ row: [String], index: Int?) -> Int? {
    let val = fieldValue(row, index: index)
    return Int(val)
}

// MARK: - Airport Type Mapping

/// Map OurAirports type to AirportType enum rawValue in the app.
/// AirportType cases: airport, heliport, seaplane, ultralight
func mapAirportType(_ ourAirportsType: String) -> String {
    switch ourAirportsType {
    case "large_airport": return "airport"
    case "medium_airport": return "airport"
    case "small_airport": return "airport"
    case "seaplane_base": return "seaplane"
    case "heliport": return "heliport"
    default: return "airport"
    }
}

/// Map OurAirports frequency types to our schema.
func mapFrequencyType(_ ourType: String) -> String {
    let upper = ourType.uppercased()
    switch upper {
    case "TWR": return "tower"
    case "GND": return "ground"
    case "ATIS": return "atis"
    case "APP", "APPR": return "approach"
    case "DEP": return "departure"
    case "CTAF": return "ctaf"
    case "UNIC": return "unicom"
    case "CNTR", "CTR": return "center"
    case "FSS": return "fss"
    case "AWOS": return "awos"
    case "ASOS": return "asos"
    case "RDO": return "other"
    case "MULTICOM": return "other"
    case "RCO": return "fss"
    default: return "other"
    }
}

/// Map OurAirports navaid types to our schema.
func mapNavaidType(_ ourType: String) -> String {
    let upper = ourType.uppercased()
    switch upper {
    case "VOR": return "vor"
    case "VOR-DME", "VORDME": return "vor_dme"
    case "VORTAC": return "vortac"
    case "TACAN": return "tacan"
    case "NDB": return "ndb"
    case "NDB-DME": return "ndb"
    case "DME": return "dme"
    default: return "vor"
    }
}

// MARK: - Database Generation

func generateDatabase(csvDir: String, outputPath: String) throws {
    let fileManager = FileManager.default

    // Remove existing file
    if fileManager.fileExists(atPath: outputPath) {
        try fileManager.removeItem(atPath: outputPath)
    }

    // Ensure parent directory exists
    let parentDir = (outputPath as NSString).deletingLastPathComponent
    if !parentDir.isEmpty && !fileManager.fileExists(atPath: parentDir) {
        try fileManager.createDirectory(atPath: parentDir, withIntermediateDirectories: true)
    }

    let config = Configuration()
    let dbQueue = try DatabaseQueue(path: outputPath, configuration: config)

    // MARK: Schema Creation

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

    // MARK: Parse and Import Airports

    print("Parsing airports.csv...")
    let airportsCSV = try parseCSV(at: (csvDir as NSString).appendingPathComponent("airports.csv"))
    let aHeaders = airportsCSV.headers

    // Build header index
    let aIdIdx = aHeaders.firstIndex(of: "id")
    let aIdentIdx = aHeaders.firstIndex(of: "ident")
    let aTypeIdx = aHeaders.firstIndex(of: "type")
    let aNameIdx = aHeaders.firstIndex(of: "name")
    let aLatIdx = aHeaders.firstIndex(of: "latitude_deg")
    let aLonIdx = aHeaders.firstIndex(of: "longitude_deg")
    let aElevIdx = aHeaders.firstIndex(of: "elevation_ft")
    let aCountryIdx = aHeaders.firstIndex(of: "iso_country")
    let aGpsCodeIdx = aHeaders.firstIndex(of: "gps_code")
    let aLocalCodeIdx = aHeaders.firstIndex(of: "local_code")
    let _ = aHeaders.firstIndex(of: "municipality")

    // Build id -> ident lookup for runway/frequency joins
    var airportIdToICAO: [String: String] = [:]
    // Track which OurAirports types we accept
    // Include heliports to reach 20K+ total US airports (pilots need heliports for emergency landing reference)
    let acceptedTypes: Set<String> = ["large_airport", "medium_airport", "small_airport", "seaplane_base", "heliport"]

    var airportCount = 0

    try dbQueue.write { db in
        for row in airportsCSV.rows {
            let country = fieldValue(row, index: aCountryIdx)
            guard country == "US" else { continue }

            let airportType = fieldValue(row, index: aTypeIdx)
            guard acceptedTypes.contains(airportType) else { continue }

            let ident = fieldValue(row, index: aIdentIdx)
            guard !ident.isEmpty else { continue }

            guard let lat = doubleValue(row, index: aLatIdx),
                  let lon = doubleValue(row, index: aLonIdx) else { continue }

            // Use ident as ICAO (OurAirports ident field is the ICAO code for most airports)
            let icao = ident
            let name = fieldValue(row, index: aNameIdx)
            let elevation = doubleValue(row, index: aElevIdx) ?? 0
            let gpsCode = fieldValue(row, index: aGpsCodeIdx)
            let localCode = fieldValue(row, index: aLocalCodeIdx)
            // Use local_code as FAA ID if available, otherwise gps_code stripped of 'K' prefix
            let faaID: String? = {
                if !localCode.isEmpty { return localCode }
                if !gpsCode.isEmpty && gpsCode.hasPrefix("K") && gpsCode.count == 4 {
                    return String(gpsCode.dropFirst())
                }
                return nil
            }()

            let dbType = mapAirportType(airportType)
            let hasBeacon = (airportType == "large_airport" || airportType == "medium_airport") ? 1 : 0
            // Note: heliports get has_beacon_light=0 (same as small_airport)

            try db.execute(
                sql: """
                    INSERT OR IGNORE INTO airports (icao, faa_id, name, latitude, longitude, elevation, type, ownership, ctaf_frequency, unicom_frequency, artcc_id, fss_id, magnetic_variation, pattern_altitude, fuel_types, has_beacon_light)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                arguments: [
                    icao, faaID, name,
                    lat, lon, elevation,
                    dbType, "public",
                    nil, nil,  // ctaf, unicom -- populated from frequencies CSV
                    nil, nil,  // artcc, fss
                    nil, nil,  // magVar, patternAlt
                    "[]", hasBeacon
                ]
            )

            // Map OurAirports ID to ICAO for join
            let oaID = fieldValue(row, index: aIdIdx)
            if !oaID.isEmpty {
                airportIdToICAO[oaID] = icao
            }
            airportCount += 1
        }
    }

    print("Airports inserted: \(airportCount)")

    // MARK: Parse and Import Runways

    print("Parsing runways.csv...")
    let runwaysCSV = try parseCSV(at: (csvDir as NSString).appendingPathComponent("runways.csv"))
    let rHeaders = runwaysCSV.headers

    let rAirportRefIdx = rHeaders.firstIndex(of: "airport_ref")
    let rLengthIdx = rHeaders.firstIndex(of: "length_ft")
    let rWidthIdx = rHeaders.firstIndex(of: "width_ft")
    let rSurfaceIdx = rHeaders.firstIndex(of: "surface")
    let rLightedIdx = rHeaders.firstIndex(of: "lighted")
    let rClosedIdx = rHeaders.firstIndex(of: "closed")
    let rLeIdentIdx = rHeaders.firstIndex(of: "le_ident")
    let rHeIdentIdx = rHeaders.firstIndex(of: "he_ident")
    let rLeLatIdx = rHeaders.firstIndex(of: "le_latitude_deg")
    let rLeLonIdx = rHeaders.firstIndex(of: "le_longitude_deg")
    let rHeLatIdx = rHeaders.firstIndex(of: "he_latitude_deg")
    let rHeLonIdx = rHeaders.firstIndex(of: "he_longitude_deg")

    var runwayCount = 0

    try dbQueue.write { db in
        for row in runwaysCSV.rows {
            let airportRef = fieldValue(row, index: rAirportRefIdx)
            guard let icao = airportIdToICAO[airportRef] else { continue }

            // Skip closed runways
            let closed = fieldValue(row, index: rClosedIdx)
            if closed == "1" { continue }

            let leIdent = fieldValue(row, index: rLeIdentIdx)
            let heIdent = fieldValue(row, index: rHeIdentIdx)
            guard !leIdent.isEmpty else { continue }

            let length = intValue(row, index: rLengthIdx) ?? 0
            let width = intValue(row, index: rWidthIdx) ?? 0
            guard length > 0 else { continue }

            let rawSurface = fieldValue(row, index: rSurfaceIdx).lowercased()
            let surface: String = {
                if rawSurface.contains("asphalt") || rawSurface.contains("asp") { return "asphalt" }
                if rawSurface.contains("concrete") || rawSurface.contains("con") || rawSurface.contains("pem") { return "concrete" }
                if rawSurface.contains("turf") || rawSurface.contains("grass") { return "turf" }
                if rawSurface.contains("gravel") || rawSurface.contains("grvl") { return "gravel" }
                if rawSurface.contains("dirt") { return "dirt" }
                if rawSurface.contains("water") { return "water" }
                return "other"
            }()

            let lighted = fieldValue(row, index: rLightedIdx) == "1"
            let lighting = lighted ? "fullTime" : "none"

            let rwyID = heIdent.isEmpty ? leIdent : "\(leIdent)/\(heIdent)"

            let leLat = doubleValue(row, index: rLeLatIdx) ?? 0
            let leLon = doubleValue(row, index: rLeLonIdx) ?? 0
            let heLat = doubleValue(row, index: rHeLatIdx) ?? 0
            let heLon = doubleValue(row, index: rHeLonIdx) ?? 0

            try db.execute(
                sql: """
                    INSERT INTO runways (id, airport_icao, length, width, surface, lighting, base_end_id, reciprocal_end_id, base_end_latitude, base_end_longitude, reciprocal_end_latitude, reciprocal_end_longitude)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                arguments: [
                    rwyID, icao,
                    length, width,
                    surface, lighting,
                    leIdent, heIdent.isEmpty ? leIdent : heIdent,
                    leLat, leLon,
                    heLat, heLon
                ]
            )
            runwayCount += 1
        }
    }

    print("Runways inserted: \(runwayCount)")

    // MARK: Parse and Import Frequencies

    print("Parsing airport-frequencies.csv...")
    let freqsCSV = try parseCSV(at: (csvDir as NSString).appendingPathComponent("airport-frequencies.csv"))
    let fHeaders = freqsCSV.headers

    let fAirportRefIdx = fHeaders.firstIndex(of: "airport_ref")
    let fTypeIdx = fHeaders.firstIndex(of: "type")
    let fDescIdx = fHeaders.firstIndex(of: "description")
    let fFreqIdx = fHeaders.firstIndex(of: "frequency_mhz")

    var frequencyCount = 0

    // Track CTAF/UNICOM for airport updates
    var airportCTAF: [String: Double] = [:]
    var airportUNICOM: [String: Double] = [:]

    try dbQueue.write { db in
        for row in freqsCSV.rows {
            let airportRef = fieldValue(row, index: fAirportRefIdx)
            guard let icao = airportIdToICAO[airportRef] else { continue }

            let freqType = fieldValue(row, index: fTypeIdx)
            let description = fieldValue(row, index: fDescIdx)
            guard let freqMHz = doubleValue(row, index: fFreqIdx) else { continue }
            guard freqMHz > 0 else { continue }

            let mappedType = mapFrequencyType(freqType)
            let freqName = description.isEmpty ? freqType : description

            let freqID = UUID().uuidString
            try db.execute(
                sql: """
                    INSERT INTO frequencies (id, airport_icao, type, name, frequency)
                    VALUES (?, ?, ?, ?, ?)
                    """,
                arguments: [freqID, icao, mappedType, freqName, freqMHz]
            )
            frequencyCount += 1

            // Track CTAF and UNICOM for airport record updates
            if mappedType == "ctaf" {
                airportCTAF[icao] = freqMHz
            } else if mappedType == "unicom" {
                airportUNICOM[icao] = freqMHz
            }
        }
    }

    print("Frequencies inserted: \(frequencyCount)")

    // Update airports with CTAF/UNICOM from frequency data
    try dbQueue.write { db in
        for (icao, ctaf) in airportCTAF {
            try db.execute(
                sql: "UPDATE airports SET ctaf_frequency = ? WHERE icao = ?",
                arguments: [ctaf, icao]
            )
        }
        for (icao, unicom) in airportUNICOM {
            try db.execute(
                sql: "UPDATE airports SET unicom_frequency = ? WHERE icao = ?",
                arguments: [unicom, icao]
            )
        }
    }

    print("Updated \(airportCTAF.count) airports with CTAF, \(airportUNICOM.count) with UNICOM")

    // MARK: Parse and Import Navaids

    print("Parsing navaids.csv...")
    let navaidsCSV = try parseCSV(at: (csvDir as NSString).appendingPathComponent("navaids.csv"))
    let nHeaders = navaidsCSV.headers

    let nIdentIdx = nHeaders.firstIndex(of: "ident")
    let nTypeIdx = nHeaders.firstIndex(of: "type")
    let nNameIdx = nHeaders.firstIndex(of: "name")
    let nLatIdx = nHeaders.firstIndex(of: "latitude_deg")
    let nLonIdx = nHeaders.firstIndex(of: "longitude_deg")
    let nFreqIdx = nHeaders.firstIndex(of: "frequency_khz")
    let nElevIdx = nHeaders.firstIndex(of: "elevation_ft")
    let nMagVarIdx = nHeaders.firstIndex(of: "magnetic_variation_deg")
    let nCountryIdx = nHeaders.firstIndex(of: "iso_country")

    var navaidCount = 0

    try dbQueue.write { db in
        for row in navaidsCSV.rows {
            let country = fieldValue(row, index: nCountryIdx)
            guard country == "US" else { continue }

            let ident = fieldValue(row, index: nIdentIdx)
            guard !ident.isEmpty else { continue }

            guard let lat = doubleValue(row, index: nLatIdx),
                  let lon = doubleValue(row, index: nLonIdx) else { continue }

            let name = fieldValue(row, index: nNameIdx)
            let navType = fieldValue(row, index: nTypeIdx)
            let mappedType = mapNavaidType(navType)

            // OurAirports provides frequency in kHz -- convert to MHz for VOR/VORTAC/DME
            let freqKhz = doubleValue(row, index: nFreqIdx) ?? 0
            let freqMHz: Double = {
                let upper = navType.uppercased()
                if upper.contains("NDB") {
                    return freqKhz  // NDB uses kHz directly
                }
                return freqKhz / 1000.0  // VOR/VORTAC/DME -> MHz
            }()

            let elevation = doubleValue(row, index: nElevIdx)
            let magVar = doubleValue(row, index: nMagVarIdx)

            try db.execute(
                sql: """
                    INSERT OR IGNORE INTO navaids (id, type, name, latitude, longitude, frequency, elevation, magnetic_variation)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                arguments: [ident, mappedType, name, lat, lon, freqMHz, elevation, magVar]
            )
            navaidCount += 1
        }
    }

    print("Navaids inserted: \(navaidCount)")

    // MARK: Insert Airspace Seed Data (no CSV source available)

    print("Inserting airspace seed data (45 Class B/C/D)...")

    // Keep existing airspace seed data -- there is no simple CSV source for US airspace geometry
    struct AirspaceSeed {
        let id: String
        let name: String
        let cls: String
        let floor: Int
        let ceiling: Int
        let centerLat: Double
        let centerLon: Double
        let radiusNM: Double
    }

    let airspaces: [AirspaceSeed] = [
        // Class B airspaces (simplified circular approximations for 20 major cities)
        AirspaceSeed(id: "SFO-B", name: "SFO Class B", cls: "bravo", floor: 0, ceiling: 10000, centerLat: 37.621, centerLon: -122.379, radiusNM: 30.0),
        AirspaceSeed(id: "LAX-B", name: "LAX Class B", cls: "bravo", floor: 0, ceiling: 12500, centerLat: 33.942, centerLon: -118.408, radiusNM: 30.0),
        AirspaceSeed(id: "ORD-B", name: "ORD Class B", cls: "bravo", floor: 0, ceiling: 10000, centerLat: 41.974, centerLon: -87.907, radiusNM: 30.0),
        AirspaceSeed(id: "ATL-B", name: "ATL Class B", cls: "bravo", floor: 0, ceiling: 12500, centerLat: 33.637, centerLon: -84.428, radiusNM: 30.0),
        AirspaceSeed(id: "DFW-B", name: "DFW Class B", cls: "bravo", floor: 0, ceiling: 11000, centerLat: 32.897, centerLon: -97.038, radiusNM: 30.0),
        AirspaceSeed(id: "DEN-B", name: "DEN Class B", cls: "bravo", floor: 5431, ceiling: 12000, centerLat: 39.856, centerLon: -104.674, radiusNM: 30.0),
        AirspaceSeed(id: "JFK-B", name: "New York Class B", cls: "bravo", floor: 0, ceiling: 7000, centerLat: 40.640, centerLon: -73.779, radiusNM: 30.0),
        AirspaceSeed(id: "SEA-B", name: "SEA Class B", cls: "bravo", floor: 0, ceiling: 10000, centerLat: 47.450, centerLon: -122.309, radiusNM: 25.0),
        AirspaceSeed(id: "MIA-B", name: "MIA Class B", cls: "bravo", floor: 0, ceiling: 7000, centerLat: 25.796, centerLon: -80.287, radiusNM: 25.0),
        AirspaceSeed(id: "PHX-B", name: "PHX Class B", cls: "bravo", floor: 0, ceiling: 9000, centerLat: 33.437, centerLon: -112.008, radiusNM: 25.0),
        AirspaceSeed(id: "BOS-B", name: "BOS Class B", cls: "bravo", floor: 0, ceiling: 7000, centerLat: 42.364, centerLon: -71.005, radiusNM: 25.0),
        AirspaceSeed(id: "MSP-B", name: "MSP Class B", cls: "bravo", floor: 0, ceiling: 10000, centerLat: 44.885, centerLon: -93.222, radiusNM: 25.0),
        AirspaceSeed(id: "DTW-B", name: "DTW Class B", cls: "bravo", floor: 0, ceiling: 8000, centerLat: 42.212, centerLon: -83.353, radiusNM: 20.0),
        AirspaceSeed(id: "LAS-B", name: "LAS Class B", cls: "bravo", floor: 0, ceiling: 10000, centerLat: 36.084, centerLon: -115.152, radiusNM: 25.0),
        AirspaceSeed(id: "IAH-B", name: "IAH Class B", cls: "bravo", floor: 0, ceiling: 10000, centerLat: 29.984, centerLon: -95.341, radiusNM: 25.0),
        AirspaceSeed(id: "MCO-B", name: "MCO Class B", cls: "bravo", floor: 0, ceiling: 10000, centerLat: 28.429, centerLon: -81.309, radiusNM: 25.0),
        AirspaceSeed(id: "CLT-B", name: "CLT Class B", cls: "bravo", floor: 0, ceiling: 10000, centerLat: 35.214, centerLon: -80.943, radiusNM: 25.0),
        AirspaceSeed(id: "PHL-B", name: "PHL Class B", cls: "bravo", floor: 0, ceiling: 7000, centerLat: 39.872, centerLon: -75.241, radiusNM: 25.0),
        AirspaceSeed(id: "SLC-B", name: "SLC Class B", cls: "bravo", floor: 4227, ceiling: 12000, centerLat: 40.788, centerLon: -111.978, radiusNM: 25.0),
        AirspaceSeed(id: "DCA-B", name: "DCA Class B", cls: "bravo", floor: 0, ceiling: 7000, centerLat: 38.852, centerLon: -77.038, radiusNM: 25.0),
        // Class C airspaces (20 example airports with tower)
        AirspaceSeed(id: "SJC-C", name: "SJC Class C", cls: "charlie", floor: 0, ceiling: 4100, centerLat: 37.363, centerLon: -121.929, radiusNM: 10.0),
        AirspaceSeed(id: "OAK-C", name: "OAK Class C", cls: "charlie", floor: 0, ceiling: 3500, centerLat: 37.721, centerLon: -122.221, radiusNM: 10.0),
        AirspaceSeed(id: "SMF-C", name: "SMF Class C", cls: "charlie", floor: 0, ceiling: 4100, centerLat: 38.695, centerLon: -121.591, radiusNM: 10.0),
        AirspaceSeed(id: "SAN-C", name: "SAN Class C", cls: "charlie", floor: 0, ceiling: 3000, centerLat: 32.734, centerLon: -117.190, radiusNM: 10.0),
        AirspaceSeed(id: "BUR-C", name: "BUR Class C", cls: "charlie", floor: 0, ceiling: 5000, centerLat: 34.201, centerLon: -118.359, radiusNM: 10.0),
        AirspaceSeed(id: "TUS-C", name: "TUS Class C", cls: "charlie", floor: 0, ceiling: 7000, centerLat: 32.116, centerLon: -110.941, radiusNM: 10.0),
        AirspaceSeed(id: "ABQ-C", name: "ABQ Class C", cls: "charlie", floor: 0, ceiling: 11000, centerLat: 35.040, centerLon: -106.609, radiusNM: 10.0),
        AirspaceSeed(id: "RNO-C", name: "RNO Class C", cls: "charlie", floor: 0, ceiling: 8000, centerLat: 39.499, centerLon: -119.768, radiusNM: 10.0),
        AirspaceSeed(id: "BNA-C", name: "BNA Class C", cls: "charlie", floor: 0, ceiling: 5500, centerLat: 36.125, centerLon: -86.678, radiusNM: 10.0),
        AirspaceSeed(id: "AUS-C", name: "AUS Class C", cls: "charlie", floor: 0, ceiling: 5000, centerLat: 30.195, centerLon: -97.670, radiusNM: 10.0),
        AirspaceSeed(id: "PDX-C", name: "PDX Class C", cls: "charlie", floor: 0, ceiling: 5000, centerLat: 45.589, centerLon: -122.598, radiusNM: 10.0),
        AirspaceSeed(id: "RDU-C", name: "RDU Class C", cls: "charlie", floor: 0, ceiling: 5000, centerLat: 35.878, centerLon: -78.788, radiusNM: 10.0),
        AirspaceSeed(id: "IND-C", name: "IND Class C", cls: "charlie", floor: 0, ceiling: 5000, centerLat: 39.717, centerLon: -86.294, radiusNM: 10.0),
        AirspaceSeed(id: "MKE-C", name: "MKE Class C", cls: "charlie", floor: 0, ceiling: 5000, centerLat: 42.947, centerLon: -87.897, radiusNM: 10.0),
        AirspaceSeed(id: "JAX-C", name: "JAX Class C", cls: "charlie", floor: 0, ceiling: 4500, centerLat: 30.494, centerLon: -81.688, radiusNM: 10.0),
        AirspaceSeed(id: "FLL-C", name: "FLL Class C", cls: "charlie", floor: 0, ceiling: 3000, centerLat: 26.073, centerLon: -80.153, radiusNM: 10.0),
        AirspaceSeed(id: "PBI-C", name: "PBI Class C", cls: "charlie", floor: 0, ceiling: 3000, centerLat: 26.683, centerLon: -80.096, radiusNM: 10.0),
        AirspaceSeed(id: "SAV-C", name: "SAV Class C", cls: "charlie", floor: 0, ceiling: 4100, centerLat: 32.128, centerLon: -81.202, radiusNM: 10.0),
        AirspaceSeed(id: "TPA-C", name: "TPA Class C", cls: "charlie", floor: 0, ceiling: 4000, centerLat: 27.976, centerLon: -82.533, radiusNM: 10.0),
        AirspaceSeed(id: "CHS-C", name: "CHS Class C", cls: "charlie", floor: 0, ceiling: 4100, centerLat: 32.899, centerLon: -80.041, radiusNM: 10.0),
        // Sample Class D airspaces (5)
        AirspaceSeed(id: "PAO-D", name: "Palo Alto Class D", cls: "delta", floor: 0, ceiling: 1500, centerLat: 37.461, centerLon: -122.115, radiusNM: 4.3),
        AirspaceSeed(id: "HWD-D", name: "Hayward Class D", cls: "delta", floor: 0, ceiling: 1500, centerLat: 37.659, centerLon: -122.122, radiusNM: 4.3),
        AirspaceSeed(id: "LVK-D", name: "Livermore Class D", cls: "delta", floor: 0, ceiling: 2900, centerLat: 37.693, centerLon: -121.820, radiusNM: 4.3),
        AirspaceSeed(id: "SQL-D", name: "San Carlos Class D", cls: "delta", floor: 0, ceiling: 1500, centerLat: 37.512, centerLon: -122.249, radiusNM: 4.3),
        AirspaceSeed(id: "CCR-D", name: "Concord Class D", cls: "delta", floor: 0, ceiling: 1500, centerLat: 37.990, centerLon: -122.057, radiusNM: 4.3),
    ]

    var airspaceCount = 0

    try dbQueue.write { db in
        for a in airspaces {
            let latDelta = a.radiusNM / 60.0
            let lonDelta = a.radiusNM / (60.0 * cos(a.centerLat * .pi / 180.0))
            let minLat = a.centerLat - latDelta
            let maxLat = a.centerLat + latDelta
            let minLon = a.centerLon - lonDelta
            let maxLon = a.centerLon + lonDelta

            try db.execute(
                sql: """
                    INSERT INTO airspaces (id, name, class, floor_altitude, ceiling_altitude, center_latitude, center_longitude, radius_nm, coordinates, min_lat, max_lat, min_lon, max_lon)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                arguments: [
                    a.id, a.name, a.cls,
                    a.floor, a.ceiling,
                    a.centerLat, a.centerLon,
                    a.radiusNM, nil,
                    minLat, maxLat, minLon, maxLon
                ]
            )
            airspaceCount += 1
        }
    }

    print("Airspaces inserted: \(airspaceCount)")

    // MARK: Populate R-tree Indexes

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

    // MARK: Populate FTS5 Index

    print("Building FTS5 search index...")

    try dbQueue.write { db in
        try db.execute(sql: """
            INSERT INTO airports_fts (rowid, icao, name, faa_id)
            SELECT rowid, icao, name, COALESCE(faa_id, '') FROM airports
            """)
    }

    // MARK: Finalize: Set journal mode to DELETE for bundling

    print("Setting journal_mode=DELETE for app bundle compatibility...")

    try dbQueue.write { db in
        try db.execute(sql: "PRAGMA journal_mode=DELETE")
    }

    // MARK: Summary

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
        print("Airports:    \(airports)")
        print("Runways:     \(runways)")
        print("Frequencies: \(frequencies)")
        print("Navaids:     \(navaids)")
        print("Airspaces:   \(airspaces)")
        print("R-tree airports: \(rtreeAirports)")
        print("FTS5 entries:    \(ftsCount)")
        print("Output: \(outputPath)")
        print("=================================")
    }

    let fileSize = try fileManager.attributesOfItem(atPath: outputPath)[.size] as? Int ?? 0
    print("File size: \(fileSize / 1024) KB (\(fileSize / (1024 * 1024)) MB)")
}
