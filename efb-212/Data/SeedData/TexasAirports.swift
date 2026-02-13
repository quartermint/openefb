//
//  TexasAirports.swift
//  efb-212
//
//  Texas and Louisiana airports seed data.
//

import Foundation

extension AirportSeedData {

    nonisolated static func texasAirports() -> [Airport] {
        [
            Airport(
                icao: "KDFW", faaID: "DFW", name: "Dallas/Fort Worth Intl",
                latitude: 32.8968, longitude: -97.0380, elevation: 607,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZFW", fssID: nil, magneticVariation: 4.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("13L/31R", length: 9000, width: 200, surface: .concrete,
                        baseEnd: "13L", recipEnd: "31R",
                        baseLat: 32.9067, baseLon: -97.0467,
                        recipLat: 32.8883, recipLon: -97.0283),
                    rwy("13R/31L", length: 9301, width: 200, surface: .concrete,
                        baseEnd: "13R", recipEnd: "31L",
                        baseLat: 32.9100, baseLon: -97.0500,
                        recipLat: 32.8900, recipLon: -97.0300),
                    rwy("17C/35C", length: 13401, width: 200, surface: .concrete,
                        baseEnd: "17C", recipEnd: "35C",
                        baseLat: 32.9150, baseLon: -97.0383,
                        recipLat: 32.8783, recipLon: -97.0300),
                    rwy("17L/35R", length: 8500, width: 150, surface: .concrete,
                        baseEnd: "17L", recipEnd: "35R",
                        baseLat: 32.9117, baseLon: -97.0450,
                        recipLat: 32.8883, recipLon: -97.0383),
                    rwy("17R/35L", length: 11387, width: 200, surface: .concrete,
                        baseEnd: "17R", recipEnd: "35L",
                        baseLat: 32.9133, baseLon: -97.0317,
                        recipLat: 32.8833, recipLon: -97.0233),
                    rwy("18L/36R", length: 13400, width: 200, surface: .concrete,
                        baseEnd: "18L", recipEnd: "36R",
                        baseLat: 32.9167, baseLon: -97.0267,
                        recipLat: 32.8800, recipLon: -97.0183),
                    rwy("18R/36L", length: 9000, width: 200, surface: .concrete,
                        baseEnd: "18R", recipEnd: "36L",
                        baseLat: 32.9117, baseLon: -97.0200,
                        recipLat: 32.8883, recipLon: -97.0133)
                ],
                frequencies: [
                    freq(.tower, 118.750, "DFW Tower"),
                    freq(.ground, 121.650, "DFW Ground"),
                    freq(.atis, 134.900, "DFW ATIS"),
                    freq(.approach, 124.150, "DFW Approach"),
                    freq(.clearance, 135.575, "DFW Clearance")
                ]
            ),

            Airport(
                icao: "KDAL", faaID: "DAL", name: "Dallas Love Field",
                latitude: 32.8471, longitude: -96.8518, elevation: 487,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZFW", fssID: nil, magneticVariation: 4.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("13L/31R", length: 7752, width: 150, surface: .concrete,
                        baseEnd: "13L", recipEnd: "31R",
                        baseLat: 32.8550, baseLon: -96.8617,
                        recipLat: 32.8400, recipLon: -96.8433),
                    rwy("13R/31L", length: 8800, width: 150, surface: .concrete,
                        baseEnd: "13R", recipEnd: "31L",
                        baseLat: 32.8583, baseLon: -96.8650,
                        recipLat: 32.8400, recipLon: -96.8433),
                    rwy("18/36", length: 6147, width: 150, surface: .asphalt,
                        baseEnd: "18", recipEnd: "36",
                        baseLat: 32.8567, baseLon: -96.8550,
                        recipLat: 32.8400, recipLon: -96.8517)
                ],
                frequencies: [
                    freq(.tower, 118.700, "Love Tower"),
                    freq(.ground, 121.700, "Love Ground"),
                    freq(.atis, 117.000, "Love ATIS"),
                    freq(.approach, 124.150, "Dallas Approach")
                ]
            ),

            Airport(
                icao: "KADS", faaID: "ADS", name: "Addison",
                latitude: 32.9686, longitude: -96.8364, elevation: 644,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZFW", fssID: nil, magneticVariation: 4.0,
                patternAltitude: 1500, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("15/33", length: 7202, width: 100, surface: .asphalt,
                        baseEnd: "15", recipEnd: "33",
                        baseLat: 32.9767, baseLon: -96.8400,
                        recipLat: 32.9600, recipLon: -96.8333)
                ],
                frequencies: [
                    freq(.tower, 126.975, "Addison Tower"),
                    freq(.ground, 121.600, "Addison Ground"),
                    freq(.atis, 133.400, "Addison ATIS")
                ]
            ),

            Airport(
                icao: "KIAH", faaID: "IAH", name: "George Bush Intercontinental",
                latitude: 29.9844, longitude: -95.3414, elevation: 97,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZHU", fssID: nil, magneticVariation: 2.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("08L/26R", length: 9402, width: 150, surface: .concrete,
                        baseEnd: "08L", recipEnd: "26R",
                        baseLat: 29.9883, baseLon: -95.3583,
                        recipLat: 29.9817, recipLon: -95.3267),
                    rwy("08R/26L", length: 9000, width: 150, surface: .concrete,
                        baseEnd: "08R", recipEnd: "26L",
                        baseLat: 29.9850, baseLon: -95.3567,
                        recipLat: 29.9783, recipLon: -95.3267),
                    rwy("09/27", length: 10000, width: 150, surface: .concrete,
                        baseEnd: "09", recipEnd: "27",
                        baseLat: 29.9783, baseLon: -95.3550,
                        recipLat: 29.9750, recipLon: -95.3200),
                    rwy("15L/33R", length: 12001, width: 150, surface: .concrete,
                        baseEnd: "15L", recipEnd: "33R",
                        baseLat: 30.0000, baseLon: -95.3450,
                        recipLat: 29.9700, recipLon: -95.3317),
                    rwy("15R/33L", length: 10000, width: 150, surface: .concrete,
                        baseEnd: "15R", recipEnd: "33L",
                        baseLat: 29.9967, baseLon: -95.3383,
                        recipLat: 29.9717, recipLon: -95.3267)
                ],
                frequencies: [
                    freq(.tower, 118.575, "Houston Tower"),
                    freq(.ground, 121.700, "Houston Ground"),
                    freq(.atis, 131.550, "Houston ATIS"),
                    freq(.approach, 120.050, "Houston Approach")
                ]
            ),

            Airport(
                icao: "KHOU", faaID: "HOU", name: "William P Hobby",
                latitude: 29.6454, longitude: -95.2789, elevation: 46,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZHU", fssID: nil, magneticVariation: 2.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("04/22", length: 7602, width: 150, surface: .concrete,
                        baseEnd: "04", recipEnd: "22",
                        baseLat: 29.6383, baseLon: -95.2850,
                        recipLat: 29.6533, recipLon: -95.2717),
                    rwy("13L/31R", length: 5149, width: 100, surface: .asphalt,
                        baseEnd: "13L", recipEnd: "31R",
                        baseLat: 29.6517, baseLon: -95.2867,
                        recipLat: 29.6417, recipLon: -95.2733),
                    rwy("13R/31L", length: 6000, width: 150, surface: .concrete,
                        baseEnd: "13R", recipEnd: "31L",
                        baseLat: 29.6533, baseLon: -95.2900,
                        recipLat: 29.6417, recipLon: -95.2750)
                ],
                frequencies: [
                    freq(.tower, 118.700, "Hobby Tower"),
                    freq(.ground, 121.700, "Hobby Ground"),
                    freq(.atis, 124.600, "Hobby ATIS"),
                    freq(.approach, 120.050, "Houston Approach")
                ]
            ),

            Airport(
                icao: "KAUS", faaID: "AUS", name: "Austin-Bergstrom Intl",
                latitude: 30.1945, longitude: -97.6699, elevation: 542,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZHU", fssID: nil, magneticVariation: 4.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("17L/35R", length: 12248, width: 150, surface: .concrete,
                        baseEnd: "17L", recipEnd: "35R",
                        baseLat: 30.2100, baseLon: -97.6683,
                        recipLat: 30.1783, recipLon: -97.6600),
                    rwy("17R/35L", length: 9000, width: 150, surface: .asphalt,
                        baseEnd: "17R", recipEnd: "35L",
                        baseLat: 30.2067, baseLon: -97.6750,
                        recipLat: 30.1833, recipLon: -97.6683)
                ],
                frequencies: [
                    freq(.tower, 119.550, "Austin Tower"),
                    freq(.ground, 121.700, "Austin Ground"),
                    freq(.atis, 118.875, "Austin ATIS"),
                    freq(.approach, 119.000, "Austin Approach")
                ]
            ),

            Airport(
                icao: "KSAT", faaID: "SAT", name: "San Antonio Intl",
                latitude: 29.5337, longitude: -98.4698, elevation: 809,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZHU", fssID: nil, magneticVariation: 4.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("04/22", length: 8502, width: 150, surface: .asphalt,
                        baseEnd: "04", recipEnd: "22",
                        baseLat: 29.5250, baseLon: -98.4783,
                        recipLat: 29.5433, recipLon: -98.4617),
                    rwy("12L/30R", length: 5519, width: 100, surface: .asphalt,
                        baseEnd: "12L", recipEnd: "30R",
                        baseLat: 29.5383, baseLon: -98.4783,
                        recipLat: 29.5317, recipLon: -98.4633),
                    rwy("12R/30L", length: 8505, width: 150, surface: .asphalt,
                        baseEnd: "12R", recipEnd: "30L",
                        baseLat: 29.5400, baseLon: -98.4833,
                        recipLat: 29.5300, recipLon: -98.4600)
                ],
                frequencies: [
                    freq(.tower, 124.800, "San Antonio Tower"),
                    freq(.ground, 121.900, "San Antonio Ground"),
                    freq(.atis, 125.275, "San Antonio ATIS"),
                    freq(.approach, 119.850, "San Antonio Approach")
                ]
            ),

            Airport(
                icao: "KMSY", faaID: "MSY", name: "Louis Armstrong New Orleans Intl",
                latitude: 29.9934, longitude: -90.2580, elevation: 4,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZHU", fssID: nil, magneticVariation: 1.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("02/20", length: 7001, width: 150, surface: .concrete,
                        baseEnd: "02", recipEnd: "20",
                        baseLat: 29.9833, baseLon: -90.2600,
                        recipLat: 30.0017, recipLon: -90.2567),
                    rwy("11/29", length: 10104, width: 150, surface: .concrete,
                        baseEnd: "11", recipEnd: "29",
                        baseLat: 29.9967, baseLon: -90.2733,
                        recipLat: 29.9900, recipLon: -90.2400)
                ],
                frequencies: [
                    freq(.tower, 118.400, "New Orleans Tower"),
                    freq(.ground, 121.900, "New Orleans Ground"),
                    freq(.atis, 127.550, "New Orleans ATIS"),
                    freq(.approach, 126.550, "New Orleans Approach")
                ]
            ),
        ]
    }
}
