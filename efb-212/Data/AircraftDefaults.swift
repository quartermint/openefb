//
//  AircraftDefaults.swift
//  efb-212
//
//  Default performance data for common GA aircraft types.
//  Matched by FAA registry model string (e.g., "AA-5B", "172S").
//  Values are typical POH cruise performance — users can override.
//

import Foundation

struct AircraftPerformanceDefaults {
    let fuelCapacityGallons: Double   // usable fuel — gallons
    let fuelBurnGPH: Double           // cruise fuel burn — gallons per hour
    let cruiseSpeedKts: Double        // cruise TAS — knots
    let displayName: String           // friendly name (e.g., "Grumman Tiger")
}

/// Lookup default performance for a given FAA model string.
/// Tries exact match first, then prefix matching.
func aircraftDefaults(forModel model: String) -> AircraftPerformanceDefaults? {
    let normalized = model.trimmingCharacters(in: .whitespaces).uppercased()

    // Exact match
    if let exact = defaultsDatabase[normalized] { return exact }

    // Prefix match (e.g., "172S" matches "172" entry)
    for (key, value) in defaultsDatabase {
        if normalized.hasPrefix(key) { return value }
    }

    return nil
}

// MARK: - Defaults Database

private let defaultsDatabase: [String: AircraftPerformanceDefaults] = [
    // Grumman American
    "AA-5B":    .init(fuelCapacityGallons: 51, fuelBurnGPH: 10.0, cruiseSpeedKts: 139, displayName: "Grumman Tiger"),
    "AA-5A":    .init(fuelCapacityGallons: 38, fuelBurnGPH: 8.0,  cruiseSpeedKts: 128, displayName: "Grumman Cheetah"),
    "AA-5":     .init(fuelCapacityGallons: 38, fuelBurnGPH: 7.5,  cruiseSpeedKts: 120, displayName: "Grumman Traveler"),
    "AA-1":     .init(fuelCapacityGallons: 24, fuelBurnGPH: 6.0,  cruiseSpeedKts: 112, displayName: "Grumman Yankee"),
    "AG-5B":    .init(fuelCapacityGallons: 51, fuelBurnGPH: 10.0, cruiseSpeedKts: 139, displayName: "Grumman Tiger"),

    // Cessna singles
    "152":      .init(fuelCapacityGallons: 26, fuelBurnGPH: 6.1,  cruiseSpeedKts: 107, displayName: "Cessna 152"),
    "172":      .init(fuelCapacityGallons: 56, fuelBurnGPH: 8.5,  cruiseSpeedKts: 122, displayName: "Cessna 172"),
    "172S":     .init(fuelCapacityGallons: 56, fuelBurnGPH: 8.5,  cruiseSpeedKts: 124, displayName: "Cessna 172SP"),
    "172R":     .init(fuelCapacityGallons: 56, fuelBurnGPH: 8.0,  cruiseSpeedKts: 120, displayName: "Cessna 172R"),
    "182":      .init(fuelCapacityGallons: 92, fuelBurnGPH: 13.0, cruiseSpeedKts: 145, displayName: "Cessna 182"),
    "182T":     .init(fuelCapacityGallons: 92, fuelBurnGPH: 13.5, cruiseSpeedKts: 150, displayName: "Cessna 182T"),
    "206":      .init(fuelCapacityGallons: 92, fuelBurnGPH: 15.0, cruiseSpeedKts: 148, displayName: "Cessna 206"),
    "210":      .init(fuelCapacityGallons: 90, fuelBurnGPH: 14.5, cruiseSpeedKts: 170, displayName: "Cessna 210"),
    "177":      .init(fuelCapacityGallons: 49, fuelBurnGPH: 10.0, cruiseSpeedKts: 133, displayName: "Cessna Cardinal"),
    "150":      .init(fuelCapacityGallons: 26, fuelBurnGPH: 5.5,  cruiseSpeedKts: 105, displayName: "Cessna 150"),

    // Piper singles
    "PA-28-140":.init(fuelCapacityGallons: 36, fuelBurnGPH: 8.0,  cruiseSpeedKts: 108, displayName: "Piper Cherokee 140"),
    "PA-28-180":.init(fuelCapacityGallons: 50, fuelBurnGPH: 9.0,  cruiseSpeedKts: 117, displayName: "Piper Cherokee 180"),
    "PA-28-161":.init(fuelCapacityGallons: 50, fuelBurnGPH: 8.5,  cruiseSpeedKts: 111, displayName: "Piper Warrior"),
    "PA-28-181":.init(fuelCapacityGallons: 50, fuelBurnGPH: 9.5,  cruiseSpeedKts: 121, displayName: "Piper Archer"),
    "PA-28-236":.init(fuelCapacityGallons: 77, fuelBurnGPH: 12.0, cruiseSpeedKts: 128, displayName: "Piper Dakota"),
    "PA-28R":   .init(fuelCapacityGallons: 50, fuelBurnGPH: 10.0, cruiseSpeedKts: 135, displayName: "Piper Arrow"),
    "PA-32":    .init(fuelCapacityGallons: 84, fuelBurnGPH: 14.0, cruiseSpeedKts: 143, displayName: "Piper Cherokee Six"),
    "PA-32R":   .init(fuelCapacityGallons: 102, fuelBurnGPH: 14.5, cruiseSpeedKts: 155, displayName: "Piper Saratoga"),
    "PA-34":    .init(fuelCapacityGallons: 100, fuelBurnGPH: 16.0, cruiseSpeedKts: 165, displayName: "Piper Seneca"),
    "PA-44":    .init(fuelCapacityGallons: 108, fuelBurnGPH: 16.0, cruiseSpeedKts: 160, displayName: "Piper Seminole"),

    // Beechcraft
    "A36":      .init(fuelCapacityGallons: 74, fuelBurnGPH: 14.0, cruiseSpeedKts: 167, displayName: "Bonanza A36"),
    "V35":      .init(fuelCapacityGallons: 74, fuelBurnGPH: 13.5, cruiseSpeedKts: 172, displayName: "Bonanza V35"),
    "33":       .init(fuelCapacityGallons: 74, fuelBurnGPH: 13.0, cruiseSpeedKts: 165, displayName: "Bonanza 33"),
    "58":       .init(fuelCapacityGallons: 166, fuelBurnGPH: 26.0, cruiseSpeedKts: 190, displayName: "Baron 58"),
    "76":       .init(fuelCapacityGallons: 108, fuelBurnGPH: 16.0, cruiseSpeedKts: 155, displayName: "Duchess 76"),

    // Cirrus
    "SR20":     .init(fuelCapacityGallons: 56, fuelBurnGPH: 10.5, cruiseSpeedKts: 155, displayName: "Cirrus SR20"),
    "SR22":     .init(fuelCapacityGallons: 92, fuelBurnGPH: 13.5, cruiseSpeedKts: 176, displayName: "Cirrus SR22"),
    "SR22T":    .init(fuelCapacityGallons: 92, fuelBurnGPH: 18.0, cruiseSpeedKts: 211, displayName: "Cirrus SR22T"),

    // Diamond
    "DA20":     .init(fuelCapacityGallons: 24, fuelBurnGPH: 6.0,  cruiseSpeedKts: 120, displayName: "Diamond DA20"),
    "DA40":     .init(fuelCapacityGallons: 40, fuelBurnGPH: 8.5,  cruiseSpeedKts: 130, displayName: "Diamond DA40"),
    "DA42":     .init(fuelCapacityGallons: 50, fuelBurnGPH: 12.0, cruiseSpeedKts: 165, displayName: "Diamond DA42"),

    // Mooney
    "M20":      .init(fuelCapacityGallons: 64, fuelBurnGPH: 9.5,  cruiseSpeedKts: 155, displayName: "Mooney M20"),
    "M20J":     .init(fuelCapacityGallons: 64, fuelBurnGPH: 9.5,  cruiseSpeedKts: 155, displayName: "Mooney 201"),
    "M20K":     .init(fuelCapacityGallons: 75, fuelBurnGPH: 12.0, cruiseSpeedKts: 185, displayName: "Mooney 252"),
]
