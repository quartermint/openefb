//
//  PacificNorthwestAirports.swift
//  efb-212
//
//  Pacific Northwest airports seed data (WA, OR).
//

import Foundation

extension AirportSeedData {

    nonisolated static func pacificNorthwestAirports() -> [Airport] {
        [
            Airport(
                icao: "KSEA", faaID: "SEA", name: "Seattle-Tacoma Intl",
                latitude: 47.4490, longitude: -122.3093, elevation: 433,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZSE", fssID: nil, magneticVariation: 16.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("16L/34R", length: 11901, width: 150, surface: .concrete,
                        baseEnd: "16L", recipEnd: "34R",
                        baseLat: 47.4650, baseLon: -122.3150,
                        recipLat: 47.4333, recipLon: -122.3050),
                    rwy("16C/34C", length: 9426, width: 150, surface: .concrete,
                        baseEnd: "16C", recipEnd: "34C",
                        baseLat: 47.4617, baseLon: -122.3100,
                        recipLat: 47.4367, recipLon: -122.3017),
                    rwy("16R/34L", length: 8500, width: 150, surface: .concrete,
                        baseEnd: "16R", recipEnd: "34L",
                        baseLat: 47.4583, baseLon: -122.3050,
                        recipLat: 47.4367, recipLon: -122.2983)
                ],
                frequencies: [
                    freq(.tower, 119.900, "Seattle Tower"),
                    freq(.ground, 121.700, "Seattle Ground"),
                    freq(.atis, 118.000, "Seattle ATIS"),
                    freq(.approach, 119.200, "Seattle Approach"),
                    freq(.clearance, 128.000, "Seattle Clearance")
                ]
            ),

            Airport(
                icao: "KBFI", faaID: "BFI", name: "Boeing Field/King County Intl",
                latitude: 47.5300, longitude: -122.3019, elevation: 21,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZSE", fssID: nil, magneticVariation: 16.0,
                patternAltitude: 1000, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("14L/32R", length: 3709, width: 100, surface: .asphalt,
                        baseEnd: "14L", recipEnd: "32R",
                        baseLat: 47.5350, baseLon: -122.3067,
                        recipLat: 47.5267, recipLon: -122.2983),
                    rwy("14R/32L", length: 10000, width: 200, surface: .asphalt,
                        baseEnd: "14R", recipEnd: "32L",
                        baseLat: 47.5400, baseLon: -122.3100,
                        recipLat: 47.5200, recipLon: -122.2933)
                ],
                frequencies: [
                    freq(.tower, 120.600, "Boeing Tower"),
                    freq(.ground, 121.900, "Boeing Ground"),
                    freq(.atis, 127.750, "Boeing ATIS"),
                    freq(.approach, 119.200, "Seattle Approach")
                ]
            ),

            Airport(
                icao: "KPAE", faaID: "PAE", name: "Paine Field",
                latitude: 47.9063, longitude: -122.2816, elevation: 606,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZSE", fssID: nil, magneticVariation: 16.0,
                patternAltitude: 1200, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("16L/34R", length: 3004, width: 75, surface: .asphalt,
                        baseEnd: "16L", recipEnd: "34R",
                        baseLat: 47.9100, baseLon: -122.2867,
                        recipLat: 47.9033, recipLon: -122.2833),
                    rwy("16R/34L", length: 9010, width: 150, surface: .asphalt,
                        baseEnd: "16R", recipEnd: "34L",
                        baseLat: 47.9183, baseLon: -122.2800,
                        recipLat: 47.8950, recipLon: -122.2733)
                ],
                frequencies: [
                    freq(.tower, 132.950, "Paine Tower"),
                    freq(.ground, 121.600, "Paine Ground"),
                    freq(.atis, 128.650, "Paine ATIS")
                ]
            ),

            Airport(
                icao: "KRNT", faaID: "RNT", name: "Renton Muni",
                latitude: 47.4930, longitude: -122.2159, elevation: 32,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZSE", fssID: nil, magneticVariation: 16.0,
                patternAltitude: 1000, fuelTypes: ["100LL"],
                hasBeaconLight: true,
                runways: [
                    rwy("16/34", length: 5382, width: 200, surface: .asphalt,
                        baseEnd: "16", recipEnd: "34",
                        baseLat: 47.5000, baseLon: -122.2167,
                        recipLat: 47.4867, recipLon: -122.2150)
                ],
                frequencies: [
                    freq(.tower, 120.000, "Renton Tower"),
                    freq(.ground, 121.600, "Renton Ground"),
                    freq(.atis, 126.850, "Renton ATIS")
                ]
            ),

            Airport(
                icao: "KPDX", faaID: "PDX", name: "Portland Intl",
                latitude: 45.5887, longitude: -122.5975, elevation: 31,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZSE", fssID: nil, magneticVariation: 16.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("10L/28R", length: 11000, width: 150, surface: .asphalt,
                        baseEnd: "10L", recipEnd: "28R",
                        baseLat: 45.5933, baseLon: -122.6183,
                        recipLat: 45.5850, recipLon: -122.5800),
                    rwy("10R/28L", length: 9825, width: 150, surface: .asphalt,
                        baseEnd: "10R", recipEnd: "28L",
                        baseLat: 45.5900, baseLon: -122.6167,
                        recipLat: 45.5817, recipLon: -122.5817),
                    rwy("03/21", length: 6000, width: 150, surface: .asphalt,
                        baseEnd: "03", recipEnd: "21",
                        baseLat: 45.5817, baseLon: -122.5983,
                        recipLat: 45.5967, recipLon: -122.5917)
                ],
                frequencies: [
                    freq(.tower, 118.700, "Portland Tower"),
                    freq(.ground, 121.900, "Portland Ground"),
                    freq(.atis, 128.350, "Portland ATIS"),
                    freq(.approach, 124.350, "Portland Approach")
                ]
            ),

            Airport(
                icao: "KHIO", faaID: "HIO", name: "Portland-Hillsboro",
                latitude: 45.5404, longitude: -122.9498, elevation: 208,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZSE", fssID: nil, magneticVariation: 16.0,
                patternAltitude: 1200, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("02/20", length: 4049, width: 75, surface: .asphalt,
                        baseEnd: "02", recipEnd: "20",
                        baseLat: 45.5350, baseLon: -122.9517,
                        recipLat: 45.5450, recipLon: -122.9483),
                    rwy("13L/31R", length: 3600, width: 60, surface: .asphalt,
                        baseEnd: "13L", recipEnd: "31R",
                        baseLat: 45.5433, baseLon: -122.9567,
                        recipLat: 45.5367, recipLon: -122.9450),
                    rwy("13R/31L", length: 6600, width: 150, surface: .asphalt,
                        baseEnd: "13R", recipEnd: "31L",
                        baseLat: 45.5467, baseLon: -122.9600,
                        recipLat: 45.5333, recipLon: -122.9400)
                ],
                frequencies: [
                    freq(.tower, 119.300, "Hillsboro Tower"),
                    freq(.ground, 121.600, "Hillsboro Ground"),
                    freq(.atis, 124.075, "Hillsboro ATIS")
                ]
            ),

            Airport(
                icao: "KEUG", faaID: "EUG", name: "Mahlon Sweet Field",
                latitude: 44.1246, longitude: -123.2119, elevation: 374,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZSE", fssID: nil, magneticVariation: 16.0,
                patternAltitude: 1200, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("16L/34R", length: 6202, width: 150, surface: .asphalt,
                        baseEnd: "16L", recipEnd: "34R",
                        baseLat: 44.1333, baseLon: -123.2117,
                        recipLat: 44.1167, recipLon: -123.2083),
                    rwy("16R/34L", length: 8009, width: 150, surface: .asphalt,
                        baseEnd: "16R", recipEnd: "34L",
                        baseLat: 44.1350, baseLon: -123.2167,
                        recipLat: 44.1133, recipLon: -123.2117)
                ],
                frequencies: [
                    freq(.tower, 118.900, "Eugene Tower"),
                    freq(.ground, 121.700, "Eugene Ground"),
                    freq(.atis, 125.250, "Eugene ATIS")
                ]
            ),
        ]
    }
}
