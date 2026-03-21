//
//  AviationModels.swift
//  efb-212
//
//  Shared aviation data structures used across the app.
//  Airport/Runway/Frequency/Navaid/Airspace are used with GRDB for aviation database.
//  FlightPlan/Waypoint/WeatherCache/ChartRegion are used across services and views.
//
//  All structs use nonisolated init for GRDB FetchableRecord compatibility.
//  GRDB conformances (FetchableRecord, PersistableRecord, TableRecord) are declared
//  here but GRDB import is deferred to the database layer to avoid coupling.
//

import Foundation
import CoreLocation

// MARK: - Airport

struct Airport: Identifiable, Codable, Equatable, Hashable, Sendable {
    var id: String { icao }
    let icao: String                     // ICAO identifier (e.g., "KPAO")
    let faaID: String?                   // FAA LID if different (e.g., "PAO")
    let name: String                     // "Palo Alto"
    let latitude: Double                 // degrees
    let longitude: Double                // degrees
    let elevation: Double                // feet MSL
    let type: AirportType
    let ownership: OwnershipType
    let ctafFrequency: Double?           // MHz
    let unicomFrequency: Double?         // MHz
    let artccID: String?                 // Controlling ARTCC
    let fssID: String?                   // Flight service station
    let magneticVariation: Double?       // degrees (W negative)
    let patternAltitude: Int?            // feet AGL
    let fuelTypes: [String]
    let hasBeaconLight: Bool
    let runways: [Runway]
    let frequencies: [Frequency]

    nonisolated init(
        icao: String,
        faaID: String? = nil,
        name: String,
        latitude: Double,
        longitude: Double,
        elevation: Double,
        type: AirportType,
        ownership: OwnershipType,
        ctafFrequency: Double? = nil,
        unicomFrequency: Double? = nil,
        artccID: String? = nil,
        fssID: String? = nil,
        magneticVariation: Double? = nil,
        patternAltitude: Int? = nil,
        fuelTypes: [String] = [],
        hasBeaconLight: Bool = false,
        runways: [Runway] = [],
        frequencies: [Frequency] = []
    ) {
        self.icao = icao
        self.faaID = faaID
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.type = type
        self.ownership = ownership
        self.ctafFrequency = ctafFrequency
        self.unicomFrequency = unicomFrequency
        self.artccID = artccID
        self.fssID = fssID
        self.magneticVariation = magneticVariation
        self.patternAltitude = patternAltitude
        self.fuelTypes = fuelTypes
        self.hasBeaconLight = hasBeaconLight
        self.runways = runways
        self.frequencies = frequencies
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(icao)
    }

    static func == (lhs: Airport, rhs: Airport) -> Bool {
        lhs.icao == rhs.icao
    }
}

// MARK: - Runway

struct Runway: Identifiable, Codable, Equatable, Sendable {
    let id: String                       // e.g., "13/31"
    let length: Int                      // feet
    let width: Int                       // feet
    let surface: SurfaceType
    let lighting: LightingType
    let baseEndID: String                // "13"
    let reciprocalEndID: String          // "31"
    let baseEndLatitude: Double          // degrees
    let baseEndLongitude: Double         // degrees
    let reciprocalEndLatitude: Double    // degrees
    let reciprocalEndLongitude: Double   // degrees
    let baseEndElevation: Double?        // feet MSL (TDZE)
    let reciprocalEndElevation: Double?  // feet MSL (TDZE)

    nonisolated init(
        id: String, length: Int, width: Int,
        surface: SurfaceType, lighting: LightingType,
        baseEndID: String, reciprocalEndID: String,
        baseEndLatitude: Double, baseEndLongitude: Double,
        reciprocalEndLatitude: Double, reciprocalEndLongitude: Double,
        baseEndElevation: Double? = nil, reciprocalEndElevation: Double? = nil
    ) {
        self.id = id
        self.length = length
        self.width = width
        self.surface = surface
        self.lighting = lighting
        self.baseEndID = baseEndID
        self.reciprocalEndID = reciprocalEndID
        self.baseEndLatitude = baseEndLatitude
        self.baseEndLongitude = baseEndLongitude
        self.reciprocalEndLatitude = reciprocalEndLatitude
        self.reciprocalEndLongitude = reciprocalEndLongitude
        self.baseEndElevation = baseEndElevation
        self.reciprocalEndElevation = reciprocalEndElevation
    }
}

// MARK: - Frequency

struct Frequency: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let type: FrequencyType
    let frequency: Double                // MHz (e.g., 118.6)
    let name: String                     // "Palo Alto Tower"

    nonisolated init(id: UUID = UUID(), type: FrequencyType, frequency: Double, name: String) {
        self.id = id
        self.type = type
        self.frequency = frequency
        self.name = name
    }
}

// MARK: - Navaid

struct Navaid: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String                       // e.g., "SJC"
    let name: String                     // "San Jose"
    let type: NavaidType
    let latitude: Double                 // degrees
    let longitude: Double                // degrees
    let frequency: Double                // MHz (VOR) or kHz (NDB)
    let magneticVariation: Double?       // degrees (W negative)
    let elevation: Double?               // feet MSL

    nonisolated init(
        id: String,
        name: String,
        type: NavaidType,
        latitude: Double,
        longitude: Double,
        frequency: Double,
        magneticVariation: Double? = nil,
        elevation: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.latitude = latitude
        self.longitude = longitude
        self.frequency = frequency
        self.magneticVariation = magneticVariation
        self.elevation = elevation
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Airspace

struct Airspace: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let classification: AirspaceClass
    let name: String                     // "SFO Class B"
    let floor: Int                       // feet MSL (0 = surface)
    let ceiling: Int                     // feet MSL
    let geometry: AirspaceGeometry

    nonisolated init(
        id: UUID = UUID(),
        classification: AirspaceClass,
        name: String,
        floor: Int,
        ceiling: Int,
        geometry: AirspaceGeometry
    ) {
        self.id = id
        self.classification = classification
        self.name = name
        self.floor = floor
        self.ceiling = ceiling
        self.geometry = geometry
    }
}

// MARK: - TFR (Temporary Flight Restriction)

struct TFR: Identifiable, Codable, Equatable, Sendable {
    let id: String                       // NOTAM number (e.g., "FDC 4/0254")
    let type: TFRType
    let description: String              // Human-readable TFR description
    let effectiveDate: Date
    let expirationDate: Date
    let latitude: Double                 // Center latitude (for circular TFRs)
    let longitude: Double                // Center longitude
    let radiusNM: Double?                // Radius in nautical miles (nil for polygon TFRs)
    let boundaries: [[Double]]           // Array of [lat, lon] pairs (for polygon TFRs)
    let floorAltitude: Int               // feet MSL
    let ceilingAltitude: Int             // feet MSL

    /// Whether the TFR is currently active based on effective/expiration dates.
    nonisolated var isActive: Bool {
        let now = Date()
        return now >= effectiveDate && now <= expirationDate
    }

    /// Center coordinate for map display and distance calculations.
    nonisolated var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    nonisolated init(
        id: String,
        type: TFRType,
        description: String,
        effectiveDate: Date,
        expirationDate: Date,
        latitude: Double,
        longitude: Double,
        radiusNM: Double? = nil,
        boundaries: [[Double]] = [],
        floorAltitude: Int = 0,
        ceilingAltitude: Int = 18000
    ) {
        self.id = id
        self.type = type
        self.description = description
        self.effectiveDate = effectiveDate
        self.expirationDate = expirationDate
        self.latitude = latitude
        self.longitude = longitude
        self.radiusNM = radiusNM
        self.boundaries = boundaries
        self.floorAltitude = floorAltitude
        self.ceilingAltitude = ceilingAltitude
    }
}

// MARK: - Flight Plan

struct FlightPlan: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String?
    var departure: String                // ICAO
    var destination: String              // ICAO
    var waypoints: [Waypoint]
    var cruiseAltitude: Int              // feet MSL
    var cruiseSpeed: Double              // knots TAS
    var fuelBurnRate: Double?            // GPH
    var totalDistance: Double             // nautical miles (computed)
    var estimatedTime: TimeInterval      // seconds (computed)
    var estimatedFuel: Double?           // gallons (computed)
    var createdAt: Date
    var notes: String?

    nonisolated init(
        id: UUID = UUID(),
        name: String? = nil,
        departure: String,
        destination: String,
        waypoints: [Waypoint] = [],
        cruiseAltitude: Int = 3000,
        cruiseSpeed: Double = 100,
        fuelBurnRate: Double? = nil,
        totalDistance: Double = 0,
        estimatedTime: TimeInterval = 0,
        estimatedFuel: Double? = nil,
        createdAt: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.departure = departure
        self.destination = destination
        self.waypoints = waypoints
        self.cruiseAltitude = cruiseAltitude
        self.cruiseSpeed = cruiseSpeed
        self.fuelBurnRate = fuelBurnRate
        self.totalDistance = totalDistance
        self.estimatedTime = estimatedTime
        self.estimatedFuel = estimatedFuel
        self.createdAt = createdAt
        self.notes = notes
    }
}

// MARK: - Waypoint

struct Waypoint: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var identifier: String               // ICAO, navaid ID, or lat/lon
    var name: String
    var latitude: Double                 // degrees
    var longitude: Double                // degrees
    var altitude: Int?                   // feet MSL (optional per-waypoint)
    var type: WaypointType

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    nonisolated init(
        id: UUID = UUID(),
        identifier: String,
        name: String,
        latitude: Double,
        longitude: Double,
        altitude: Int? = nil,
        type: WaypointType = .airport
    ) {
        self.id = id
        self.identifier = identifier
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.type = type
    }
}

// MARK: - Weather Cache

struct WeatherCache: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var stationID: String                // ICAO (e.g., "KPAO")
    var rawMETAR: String?                // Raw METAR text
    var rawTAF: String?                  // Raw TAF text
    var temperature: Double?             // Celsius
    var dewpoint: Double?                // Celsius
    var windDirection: Int?              // degrees true
    var windSpeed: Int?                  // knots
    var windGust: Int?                   // knots
    var visibility: String?              // statute miles (string to handle "10+" etc.)
    var ceiling: Int?                    // feet AGL
    var flightCategory: FlightCategory
    var observationTime: Date?           // When observation was taken
    var fetchedAt: Date                  // When data was retrieved

    /// Age of the weather data in seconds since fetch.
    nonisolated var age: TimeInterval {
        Date().timeIntervalSince(fetchedAt)
    }

    /// Whether data is considered stale (> 60 minutes from fetch).
    nonisolated var isStale: Bool {
        age > 3600  // 60 minutes
    }

    nonisolated init(
        id: UUID = UUID(),
        stationID: String,
        rawMETAR: String? = nil,
        rawTAF: String? = nil,
        temperature: Double? = nil,
        dewpoint: Double? = nil,
        windDirection: Int? = nil,
        windSpeed: Int? = nil,
        windGust: Int? = nil,
        visibility: String? = nil,
        ceiling: Int? = nil,
        flightCategory: FlightCategory = .vfr,
        observationTime: Date? = nil,
        fetchedAt: Date = Date()
    ) {
        self.id = id
        self.stationID = stationID
        self.rawMETAR = rawMETAR
        self.rawTAF = rawTAF
        self.temperature = temperature
        self.dewpoint = dewpoint
        self.windDirection = windDirection
        self.windSpeed = windSpeed
        self.windGust = windGust
        self.visibility = visibility
        self.ceiling = ceiling
        self.flightCategory = flightCategory
        self.observationTime = observationTime
        self.fetchedAt = fetchedAt
    }
}

// MARK: - Chart Region

struct ChartRegion: Identifiable, Codable, Equatable, Sendable {
    let id: String                       // e.g., "San_Francisco"
    let name: String                     // "San Francisco"
    let effectiveDate: Date
    let expirationDate: Date
    let boundingBox: BoundingBox
    let fileSizeMB: Double               // mbtiles file size
    var isDownloaded: Bool
    var localPath: URL?

    var isExpired: Bool {
        expirationDate < Date()
    }

    nonisolated init(
        id: String,
        name: String,
        effectiveDate: Date,
        expirationDate: Date,
        boundingBox: BoundingBox,
        fileSizeMB: Double,
        isDownloaded: Bool = false,
        localPath: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.effectiveDate = effectiveDate
        self.expirationDate = expirationDate
        self.boundingBox = boundingBox
        self.fileSizeMB = fileSizeMB
        self.isDownloaded = isDownloaded
        self.localPath = localPath
    }
}
