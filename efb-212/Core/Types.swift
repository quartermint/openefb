//
//  Types.swift
//  efb-212
//
//  Shared enums and lightweight types used across the app.
//

import Foundation
import CoreLocation

// MARK: - Navigation

enum AppTab: String, CaseIterable {
    case map, flights, logbook, aircraft, settings

    var title: String {
        switch self {
        case .map: return "Map"
        case .flights: return "Flights"
        case .logbook: return "Logbook"
        case .aircraft: return "Aircraft"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .map: return "map"
        case .flights: return "airplane"
        case .logbook: return "book.closed"
        case .aircraft: return "airplane.circle"
        case .settings: return "gear"
        }
    }
}

enum MapMode: String, CaseIterable {
    case northUp    // Map always oriented north
    case trackUp    // Map rotates to heading
}

enum MapLayer: String, CaseIterable {
    case sectional      // VFR sectional chart overlay
    case airports       // Airport dots/icons
    case airspace       // Airspace boundaries
    case tfrs           // TFRs
    case weatherDots    // Color-coded weather dots
    case navaids        // VOR/NDB icons
    case route          // Active flight plan route line
    case ownship        // Own aircraft position
}

// MARK: - Power

enum PowerState: String, CaseIterable {
    case normal           // Full functionality
    case batteryConscious // < 20% — reduce non-essential services
    case emergency        // < 10% — minimum viable operation

    var gpsUpdateInterval: TimeInterval {
        switch self {
        case .normal: return 1.0              // 1 Hz
        case .batteryConscious: return 3.0    // 0.33 Hz
        case .emergency: return 5.0           // 0.2 Hz
        }
    }

    var mapTargetFPS: Int {
        switch self {
        case .normal: return 60
        case .batteryConscious: return 30
        case .emergency: return 15
        }
    }

    var weatherRefreshInterval: TimeInterval {
        switch self {
        case .normal: return 900              // 15 minutes
        case .batteryConscious: return 1800   // 30 minutes
        case .emergency: return .infinity     // No refresh
        }
    }
}

// MARK: - Aviation Enums

enum AirportType: String, Codable, CaseIterable {
    case airport
    case heliport
    case seaplane
    case ultralight
}

enum OwnershipType: String, Codable, CaseIterable {
    case publicOwned = "public"
    case privateOwned = "private"
    case military
}

enum SurfaceType: String, Codable, CaseIterable {
    case asphalt
    case concrete
    case turf
    case gravel
    case water
    case dirt
    case other
}

enum LightingType: String, Codable, CaseIterable {
    case none
    case partTime
    case fullTime
}

enum FrequencyType: String, Codable, CaseIterable {
    case ctaf
    case tower
    case ground
    case clearance
    case approach
    case departure
    case atis
    case awos
    case unicom
    case multicom
}

enum NavaidType: String, Codable, CaseIterable {
    case vor
    case vortac
    case vorDme
    case ndb
    case ndbDme
}

enum TFRType: String, Codable, CaseIterable, Sendable {
    case security       // National security (e.g., Washington DC SFRA)
    case vip            // Presidential/VIP movement
    case hazard         // Hazardous operations (e.g., firefighting, space launch)
    case airshow        // Air show / aerial demo
    case stadium        // Sporting event stadium TFR (3 NM, surface to 3000 AGL)
    case other          // Catch-all
}

enum AirspaceClass: String, Codable, CaseIterable {
    case bravo
    case charlie
    case delta
    case echo
    case golf
    case prohibited
    case restricted
    case moa
    case alert
    case warning
    case tfr
}

enum FlightCategory: String, Codable, CaseIterable {
    case vfr      // Ceiling > 3000 AGL AND visibility > 5 SM
    case mvfr     // Ceiling 1000-3000 AGL OR visibility 3-5 SM
    case ifr      // Ceiling 500-999 AGL OR visibility 1-3 SM
    case lifr     // Ceiling < 500 AGL OR visibility < 1 SM

    var colorName: String {
        switch self {
        case .vfr: return "green"
        case .mvfr: return "blue"
        case .ifr: return "red"
        case .lifr: return "magenta"
        }
    }
}

enum WaypointType: String, Codable, CaseIterable {
    case airport
    case navaid
    case fix
    case userWaypoint
    case latLon
}

// MARK: - Error Severity

enum ErrorSeverity {
    case critical   // Red banner, persistent until resolved
    case error      // Red toast, auto-dismiss after 5s
    case warning    // Yellow toast, auto-dismiss after 3s
    case info       // Blue toast, auto-dismiss after 2s
}

// MARK: - Lightweight Structs

struct WindInfo: Codable, Equatable {
    let direction: Int       // degrees true (0 = variable)
    let speed: Int           // knots
    let gusts: Int?          // knots (nil if no gusts)
    let isVariable: Bool
}

struct BoundingBox: Codable, Equatable {
    let minLatitude: Double
    let maxLatitude: Double
    let minLongitude: Double
    let maxLongitude: Double

    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        coordinate.latitude >= minLatitude &&
        coordinate.latitude <= maxLatitude &&
        coordinate.longitude >= minLongitude &&
        coordinate.longitude <= maxLongitude
    }
}

struct VSpeeds: Codable, Equatable {
    var vr: Int?     // Rotation speed — knots
    var vx: Int?     // Best angle of climb — knots
    var vy: Int?     // Best rate of climb — knots
    var va: Int?     // Maneuvering speed — knots
    var vne: Int?    // Never exceed — knots
    var vfe: Int?    // Max flap extended — knots
    var vs0: Int?    // Stall speed landing config — knots
    var vs1: Int?    // Stall speed clean — knots
}

enum MedicalClass: String, Codable, CaseIterable {
    case first
    case second
    case third
    case basicMed
}

enum CertificateType: String, Codable, CaseIterable {
    case student
    case sport
    case recreational
    case privatePilot = "private"
    case commercial
    case atp
}

// MARK: - Airspace Geometry

enum AirspaceGeometry: Codable, Equatable, Sendable {
    case polygon(coordinates: [[Double]])  // Array of [lat, lon] pairs
    case circle(center: [Double], radiusNM: Double)  // [lat, lon], radius in NM

    // Explicit nonisolated Codable to avoid MainActor isolation warnings in GRDB context
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let coordinates = try container.decodeIfPresent([[Double]].self, forKey: .coordinates) {
            self = .polygon(coordinates: coordinates)
        } else if let center = try container.decodeIfPresent([Double].self, forKey: .center),
                  let radiusNM = try container.decodeIfPresent(Double.self, forKey: .radiusNM) {
            self = .circle(center: center, radiusNM: radiusNM)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid AirspaceGeometry")
            )
        }
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .polygon(let coordinates):
            try container.encode(coordinates, forKey: .coordinates)
        case .circle(let center, let radiusNM):
            try container.encode(center, forKey: .center)
            try container.encode(radiusNM, forKey: .radiusNM)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case coordinates, center, radiusNM
    }
}
