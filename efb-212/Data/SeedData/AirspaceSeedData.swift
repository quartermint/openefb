//
//  AirspaceSeedData.swift
//  efb-212
//
//  Bundled seed data for Bay Area airspace boundaries.
//  Coordinates are approximate for display purposes and based on published FAA charts.
//
//  SAFETY NOTE: These boundaries are approximate. Pilots must always verify
//  against current VFR sectional charts and NOTAMs for actual airspace limits.
//

import Foundation

enum AirspaceSeedData: Sendable {

    /// Returns all bundled airspace seed data.
    nonisolated static func allAirspaces() -> [Airspace] {
        var airspaces: [Airspace] = []
        airspaces.append(contentsOf: sfoBravo())
        airspaces.append(contentsOf: oakCharlie())
        airspaces.append(contentsOf: sjcCharlie())
        airspaces.append(contentsOf: paoDelta())
        airspaces.append(contentsOf: sqlDelta())
        return airspaces
    }

    // MARK: - SFO Class B (Multi-tier)

    /// SFO Class Bravo airspace — simplified multi-tier representation.
    /// The real SFO Class B has many shelves; these are the primary tiers.
    nonisolated static func sfoBravo() -> [Airspace] {
        [
            // Inner ring: Surface to 10,000 MSL (around SFO proper)
            Airspace(
                classification: .bravo,
                name: "SFO Class B Inner",
                floor: 0,
                ceiling: 10000,
                geometry: .polygon(coordinates: [
                    [37.6500, -122.4500],
                    [37.6500, -122.3000],
                    [37.5800, -122.2800],
                    [37.5500, -122.3200],
                    [37.5500, -122.4300],
                    [37.5800, -122.4600],
                ])
            ),
            // Middle shelf: 1500 MSL to 10,000 MSL
            Airspace(
                classification: .bravo,
                name: "SFO Class B Middle Shelf",
                floor: 1500,
                ceiling: 10000,
                geometry: .polygon(coordinates: [
                    [37.7200, -122.5500],
                    [37.7200, -122.2000],
                    [37.6500, -122.1500],
                    [37.5000, -122.1500],
                    [37.4500, -122.2000],
                    [37.4500, -122.5000],
                    [37.5000, -122.5500],
                    [37.6000, -122.5800],
                ])
            ),
            // Outer shelf: 3000 MSL to 10,000 MSL
            Airspace(
                classification: .bravo,
                name: "SFO Class B Outer Shelf",
                floor: 3000,
                ceiling: 10000,
                geometry: .polygon(coordinates: [
                    [37.8000, -122.6500],
                    [37.8000, -122.1000],
                    [37.7200, -122.0500],
                    [37.4000, -122.0500],
                    [37.3500, -122.1000],
                    [37.3500, -122.5500],
                    [37.4000, -122.6500],
                    [37.5500, -122.7000],
                    [37.7000, -122.7000],
                ])
            ),
        ]
    }

    // MARK: - OAK Class C

    /// Oakland Class Charlie airspace — inner and outer rings.
    nonisolated static func oakCharlie() -> [Airspace] {
        [
            // Inner ring: Surface to 3000 MSL (5 NM radius approx)
            Airspace(
                classification: .charlie,
                name: "OAK Class C Inner",
                floor: 0,
                ceiling: 3000,
                geometry: .circle(center: [37.7213, -122.2208], radiusNM: 5.0)
            ),
            // Outer ring: 1500 to 3000 MSL (10 NM radius approx)
            Airspace(
                classification: .charlie,
                name: "OAK Class C Outer",
                floor: 1500,
                ceiling: 3000,
                geometry: .circle(center: [37.7213, -122.2208], radiusNM: 10.0)
            ),
        ]
    }

    // MARK: - SJC Class C

    /// San Jose Class Charlie airspace — inner and outer rings.
    nonisolated static func sjcCharlie() -> [Airspace] {
        [
            // Inner ring: Surface to 2700 MSL (5 NM radius approx)
            Airspace(
                classification: .charlie,
                name: "SJC Class C Inner",
                floor: 0,
                ceiling: 2700,
                geometry: .circle(center: [37.3626, -121.9290], radiusNM: 5.0)
            ),
            // Outer ring: 1500 to 2700 MSL (10 NM radius approx)
            Airspace(
                classification: .charlie,
                name: "SJC Class C Outer",
                floor: 1500,
                ceiling: 2700,
                geometry: .circle(center: [37.3626, -121.9290], radiusNM: 10.0)
            ),
        ]
    }

    // MARK: - PAO Class D

    /// Palo Alto Class Delta airspace — surface to 2500 MSL.
    nonisolated static func paoDelta() -> [Airspace] {
        [
            Airspace(
                classification: .delta,
                name: "PAO Class D",
                floor: 0,
                ceiling: 2500,
                geometry: .circle(center: [37.4613, -122.1150], radiusNM: 4.3)
            ),
        ]
    }

    // MARK: - SQL Class D

    /// San Carlos Class Delta airspace — surface to 1500 MSL.
    nonisolated static func sqlDelta() -> [Airspace] {
        [
            Airspace(
                classification: .delta,
                name: "SQL Class D",
                floor: 0,
                ceiling: 1500,
                geometry: .circle(center: [37.5119, -122.2494], radiusNM: 4.3)
            ),
        ]
    }
}
