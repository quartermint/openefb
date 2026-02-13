//
//  AviationModels.swift
//  efb-212
//
//  Shared aviation data structures used across the app.
//  Airport/Runway/Frequency/Navaid are used with GRDB for aviation database.
//  FlightPlan/Waypoint/WeatherCache/ChartRegion are used across services and views.
//

import Foundation
import CoreLocation

// MARK: - Airport

struct Airport: Identifiable, Codable, Equatable, Hashable {
    var id: String { icao }
    let icao: String                     // ICAO identifier (e.g., "KPAO")
    let faaID: String?                   // FAA LID if different (e.g., "PAO")
    let name: String                     // "Palo Alto"
    let latitude: Double
    let longitude: Double
    let elevation: Double                // feet MSL
    let type: AirportType
    let ownership: OwnershipType
    let ctafFrequency: Double?           // MHz
    let unicomFrequency: Double?
    let artccID: String?                 // Controlling ARTCC
    let fssID: String?                   // Flight service station
    let magneticVariation: Double?       // degrees (W negative)
    let patternAltitude: Int?            // feet AGL
    let fuelTypes: [String]
    let hasBeaconLight: Bool
    let runways: [Runway]
    let frequencies: [Frequency]

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

struct Runway: Identifiable, Codable, Equatable {
    let id: String                       // e.g., "13/31"
    let length: Int                      // feet
    let width: Int                       // feet
    let surface: SurfaceType
    let lighting: LightingType
    let baseEndID: String                // "13"
    let reciprocalEndID: String          // "31"
    let baseEndLatitude: Double
    let baseEndLongitude: Double
    let reciprocalEndLatitude: Double
    let reciprocalEndLongitude: Double
    let baseEndElevation: Double?        // feet MSL (TDZE)
    let reciprocalEndElevation: Double?
}

// MARK: - Frequency

struct Frequency: Identifiable, Codable, Equatable {
    let id: UUID
    let type: FrequencyType
    let frequency: Double                // MHz (e.g., 118.6)
    let name: String                     // "Palo Alto Tower"
}

// MARK: - Navaid

struct Navaid: Identifiable, Codable, Equatable {
    let id: String                       // e.g., "SJC"
    let name: String                     // "San Jose"
    let type: NavaidType
    let latitude: Double
    let longitude: Double
    let frequency: Double                // MHz (VOR) or kHz (NDB)
    let magneticVariation: Double?
    let elevation: Double?               // feet MSL

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Airspace

struct Airspace: Identifiable, Codable, Equatable {
    let id: UUID
    let classification: AirspaceClass
    let name: String                     // "SFO Class B"
    let floor: Int                       // feet MSL (0 = surface)
    let ceiling: Int                     // feet MSL
    let geometry: AirspaceGeometry
}

// MARK: - Flight Plan

struct FlightPlan: Identifiable, Codable, Equatable {
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

    init(
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

struct Waypoint: Identifiable, Codable, Equatable {
    let id: UUID
    var identifier: String               // ICAO, navaid ID, or lat/lon
    var name: String
    var latitude: Double
    var longitude: Double
    var altitude: Int?                   // feet MSL (optional per-waypoint)
    var type: WaypointType

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
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

struct WeatherCache: Identifiable, Codable, Equatable {
    let id: UUID
    var stationID: String                // ICAO (e.g., "KPAO")
    var metar: String?                   // Raw METAR text
    var taf: String?                     // Raw TAF text
    var flightCategory: FlightCategory
    var temperature: Double?             // Celsius
    var dewpoint: Double?                // Celsius
    var wind: WindInfo?
    var visibility: Double?              // statute miles
    var ceiling: Int?                    // feet AGL
    var fetchedAt: Date                  // When data was retrieved
    var observationTime: Date?           // When observation was taken

    /// Age of the weather data in seconds
    var age: TimeInterval {
        Date().timeIntervalSince(fetchedAt)
    }

    /// Whether data is considered stale (> 60 minutes from fetch)
    var isStale: Bool {
        age > 3600
    }

    init(
        id: UUID = UUID(),
        stationID: String,
        metar: String? = nil,
        taf: String? = nil,
        flightCategory: FlightCategory = .vfr,
        temperature: Double? = nil,
        dewpoint: Double? = nil,
        wind: WindInfo? = nil,
        visibility: Double? = nil,
        ceiling: Int? = nil,
        fetchedAt: Date = Date(),
        observationTime: Date? = nil
    ) {
        self.id = id
        self.stationID = stationID
        self.metar = metar
        self.taf = taf
        self.flightCategory = flightCategory
        self.temperature = temperature
        self.dewpoint = dewpoint
        self.wind = wind
        self.visibility = visibility
        self.ceiling = ceiling
        self.fetchedAt = fetchedAt
        self.observationTime = observationTime
    }
}

// MARK: - Chart Region

struct ChartRegion: Identifiable, Codable, Equatable {
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
}
