//
//  NavaidSeedData.swift
//  efb-212
//
//  Bundled seed data for major US VORs, VOR/DMEs, and NDBs.
//  Frequencies and coordinates are based on published FAA data.
//
//  SAFETY NOTE: All frequencies and positions are based on published
//  FAA data. Pilots must always verify against current charts.
//

import Foundation

enum NavaidSeedData: Sendable {

    /// Returns all bundled navaid seed data.
    nonisolated static func allNavaids() -> [Navaid] {
        var navaids: [Navaid] = []
        navaids.append(contentsOf: westCoastNavaids())
        navaids.append(contentsOf: pacificNorthwestNavaids())
        navaids.append(contentsOf: mountainNavaids())
        navaids.append(contentsOf: midwestNavaids())
        navaids.append(contentsOf: northeastNavaids())
        navaids.append(contentsOf: southeastNavaids())
        navaids.append(contentsOf: texasNavaids())
        return navaids
    }

    // MARK: - West Coast

    nonisolated static func westCoastNavaids() -> [Navaid] {
        [
            // San Francisco Bay Area
            Navaid(id: "SFO", name: "San Francisco", type: .vorDme,
                   latitude: 37.6195, longitude: -122.3747, frequency: 115.8,
                   magneticVariation: 14.0, elevation: 13),
            Navaid(id: "OAK", name: "Oakland", type: .vorDme,
                   latitude: 37.7253, longitude: -122.2225, frequency: 116.8,
                   magneticVariation: 14.0, elevation: 9),
            Navaid(id: "SJC", name: "San Jose", type: .vorDme,
                   latitude: 37.3716, longitude: -121.9452, frequency: 114.1,
                   magneticVariation: 14.0, elevation: 62),
            Navaid(id: "SAU", name: "Sausalito", type: .vor,
                   latitude: 37.8542, longitude: -122.5208, frequency: 116.2,
                   magneticVariation: 14.0, elevation: 920),

            // Southern California
            Navaid(id: "LAX", name: "Los Angeles", type: .vorDme,
                   latitude: 33.9339, longitude: -118.4317, frequency: 113.6,
                   magneticVariation: 13.0, elevation: 128),
            Navaid(id: "VNY", name: "Van Nuys", type: .vorDme,
                   latitude: 34.2228, longitude: -118.4897, frequency: 113.1,
                   magneticVariation: 13.0, elevation: 802),
            Navaid(id: "SAN", name: "San Diego (Mission Bay)", type: .vorDme,
                   latitude: 32.8536, longitude: -117.1611, frequency: 117.8,
                   magneticVariation: 12.0, elevation: 17),
            Navaid(id: "SBA", name: "Santa Barbara", type: .vorDme,
                   latitude: 34.5083, longitude: -119.7711, frequency: 114.9,
                   magneticVariation: 14.0, elevation: 10),

            // Central California
            Navaid(id: "SAC", name: "Sacramento", type: .vorDme,
                   latitude: 38.5083, longitude: -121.4950, frequency: 115.2,
                   magneticVariation: 14.0, elevation: 24),
            Navaid(id: "FAT", name: "Fresno", type: .vorDme,
                   latitude: 36.7819, longitude: -119.7178, frequency: 112.9,
                   magneticVariation: 14.0, elevation: 336),
        ]
    }

    // MARK: - Pacific Northwest

    nonisolated static func pacificNorthwestNavaids() -> [Navaid] {
        [
            Navaid(id: "SEA", name: "Seattle", type: .vorDme,
                   latitude: 47.4350, longitude: -122.3097, frequency: 116.8,
                   magneticVariation: 16.0, elevation: 433),
            Navaid(id: "PDX", name: "Portland (Battle Ground)", type: .vorDme,
                   latitude: 45.5928, longitude: -122.5494, frequency: 116.6,
                   magneticVariation: 16.0, elevation: 21),
        ]
    }

    // MARK: - Mountain West

    nonisolated static func mountainNavaids() -> [Navaid] {
        [
            Navaid(id: "DEN", name: "Denver", type: .vorDme,
                   latitude: 39.8106, longitude: -104.6631, frequency: 117.9,
                   magneticVariation: 8.0, elevation: 5431),
            Navaid(id: "SLC", name: "Salt Lake City", type: .vorDme,
                   latitude: 40.8506, longitude: -111.9797, frequency: 116.8,
                   magneticVariation: 12.0, elevation: 4227),
            Navaid(id: "PXR", name: "Phoenix", type: .vorDme,
                   latitude: 33.4339, longitude: -112.0117, frequency: 115.6,
                   magneticVariation: 11.0, elevation: 1135),
            Navaid(id: "LAS", name: "Las Vegas", type: .vorDme,
                   latitude: 36.0828, longitude: -115.1533, frequency: 116.9,
                   magneticVariation: 12.0, elevation: 2181),
            Navaid(id: "RNO", name: "Reno", type: .vorDme,
                   latitude: 39.4978, longitude: -119.7681, frequency: 117.9,
                   magneticVariation: 14.0, elevation: 4415),
        ]
    }

    // MARK: - Midwest

    nonisolated static func midwestNavaids() -> [Navaid] {
        [
            Navaid(id: "ORD", name: "Chicago O'Hare", type: .vorDme,
                   latitude: 41.9767, longitude: -87.9044, frequency: 113.9,
                   magneticVariation: 3.0, elevation: 672),
            Navaid(id: "MSP", name: "Minneapolis", type: .vorDme,
                   latitude: 44.8850, longitude: -93.2178, frequency: 115.3,
                   magneticVariation: 2.0, elevation: 841),
            Navaid(id: "DTW", name: "Detroit Metro", type: .vorDme,
                   latitude: 42.2117, longitude: -83.3547, frequency: 113.0,
                   magneticVariation: 6.0, elevation: 645),
            Navaid(id: "STL", name: "St Louis", type: .vorDme,
                   latitude: 38.6578, longitude: -90.4297, frequency: 117.4,
                   magneticVariation: 3.0, elevation: 604),
        ]
    }

    // MARK: - Northeast

    nonisolated static func northeastNavaids() -> [Navaid] {
        [
            Navaid(id: "JFK", name: "Kennedy", type: .vorDme,
                   latitude: 40.6397, longitude: -73.7789, frequency: 115.9,
                   magneticVariation: 13.0, elevation: 13),
            Navaid(id: "BOS", name: "Boston", type: .vorDme,
                   latitude: 42.3556, longitude: -71.0117, frequency: 112.7,
                   magneticVariation: 15.0, elevation: 20),
            Navaid(id: "DCA", name: "Washington National", type: .vorDme,
                   latitude: 38.8569, longitude: -77.0389, frequency: 111.0,
                   magneticVariation: 10.0, elevation: 15),
            Navaid(id: "PHL", name: "Philadelphia", type: .vorDme,
                   latitude: 39.8750, longitude: -75.2542, frequency: 108.2,
                   magneticVariation: 12.0, elevation: 36),
            Navaid(id: "EWR", name: "Newark", type: .vorDme,
                   latitude: 40.6925, longitude: -74.1686, frequency: 108.4,
                   magneticVariation: 13.0, elevation: 18),
        ]
    }

    // MARK: - Southeast

    nonisolated static func southeastNavaids() -> [Navaid] {
        [
            Navaid(id: "ATL", name: "Atlanta", type: .vorDme,
                   latitude: 33.6297, longitude: -84.4350, frequency: 116.9,
                   magneticVariation: 5.0, elevation: 1026),
            Navaid(id: "MIA", name: "Miami", type: .vorDme,
                   latitude: 25.7953, longitude: -80.2867, frequency: 115.9,
                   magneticVariation: 5.0, elevation: 8),
            Navaid(id: "MCO", name: "Orlando", type: .vorDme,
                   latitude: 28.4422, longitude: -81.3169, frequency: 112.2,
                   magneticVariation: 5.0, elevation: 96),
            Navaid(id: "CLT", name: "Charlotte", type: .vorDme,
                   latitude: 35.2294, longitude: -80.9533, frequency: 115.0,
                   magneticVariation: 7.0, elevation: 749),
        ]
    }

    // MARK: - Texas

    nonisolated static func texasNavaids() -> [Navaid] {
        [
            Navaid(id: "DFW", name: "Dallas-Fort Worth", type: .vorDme,
                   latitude: 32.8481, longitude: -96.8519, frequency: 117.0,
                   magneticVariation: 4.0, elevation: 603),
            Navaid(id: "IAH", name: "Houston Intercontinental", type: .vorDme,
                   latitude: 29.9672, longitude: -95.3414, frequency: 116.6,
                   magneticVariation: 3.0, elevation: 97),
            Navaid(id: "SAT", name: "San Antonio", type: .vorDme,
                   latitude: 29.5306, longitude: -98.4686, frequency: 116.8,
                   magneticVariation: 4.0, elevation: 809),
        ]
    }
}
