//
//  AirportSeedData.swift
//  efb-212
//
//  Bundled seed data for US airports. Contains accurate data for major
//  towered airports, busy GA airports, and airports with instrument approaches
//  across all US geographic regions.
//
//  SAFETY NOTE: All frequencies, elevations, and runway data are based on
//  published FAA data. If any value is uncertain, it is omitted (nil) rather
//  than guessed. Pilots must always verify against current NOTAMs and charts.
//

import Foundation

enum AirportSeedData: Sendable {

    /// Returns all bundled airport seed data.
    nonisolated static func allAirports() -> [Airport] {
        var airports: [Airport] = []
        airports.append(contentsOf: westCoastAirports())
        airports.append(contentsOf: southwestAirports())
        airports.append(contentsOf: midwestAirports())
        airports.append(contentsOf: southeastAirports())
        airports.append(contentsOf: northeastAirports())
        airports.append(contentsOf: mountainWestAirports())
        airports.append(contentsOf: pacificNorthwestAirports())
        airports.append(contentsOf: texasAirports())
        airports.append(contentsOf: alaskaHawaiiAirports())
        return airports
    }
}

// MARK: - Seed Data Helpers

/// Convenience factory for Frequency used by seed data files.
nonisolated func freq(_ type: FrequencyType, _ mhz: Double, _ name: String) -> Frequency {
    Frequency(id: UUID(), type: type, frequency: mhz, name: name)
}

/// Convenience factory for Runway used by seed data files.
nonisolated func rwy(
    _ id: String, length: Int, width: Int,
    surface: SurfaceType = .asphalt, lighting: LightingType = .fullTime,
    baseEnd: String, recipEnd: String,
    baseLat: Double, baseLon: Double,
    recipLat: Double, recipLon: Double,
    baseElev: Double? = nil, recipElev: Double? = nil
) -> Runway {
    Runway(
        id: id, length: length, width: width,
        surface: surface, lighting: lighting,
        baseEndID: baseEnd, reciprocalEndID: recipEnd,
        baseEndLatitude: baseLat, baseEndLongitude: baseLon,
        reciprocalEndLatitude: recipLat, reciprocalEndLongitude: recipLon,
        baseEndElevation: baseElev, reciprocalEndElevation: recipElev
    )
}
