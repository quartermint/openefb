//
//  AlaskaHawaiiAirports.swift
//  efb-212
//
//  Alaska and Hawaii airports seed data.
//

import Foundation

extension AirportSeedData {

    nonisolated static func alaskaHawaiiAirports() -> [Airport] {
        [
            Airport(
                icao: "PANC", faaID: "ANC", name: "Ted Stevens Anchorage Intl",
                latitude: 61.1744, longitude: -149.9964, elevation: 152,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZAN", fssID: nil, magneticVariation: 18.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("07L/25R", length: 10897, width: 150, surface: .asphalt,
                        baseEnd: "07L", recipEnd: "25R",
                        baseLat: 61.1783, baseLon: -150.0250,
                        recipLat: 61.1700, recipLon: -149.9800),
                    rwy("07R/25L", length: 10600, width: 200, surface: .asphalt,
                        baseEnd: "07R", recipEnd: "25L",
                        baseLat: 61.1733, baseLon: -150.0233,
                        recipLat: 61.1650, recipLon: -149.9783),
                    rwy("15/33", length: 10500, width: 150, surface: .asphalt,
                        baseEnd: "15", recipEnd: "33",
                        baseLat: 61.1883, baseLon: -150.0000,
                        recipLat: 61.1617, recipLon: -149.9917)
                ],
                frequencies: [
                    freq(.tower, 118.300, "Anchorage Tower"),
                    freq(.ground, 121.900, "Anchorage Ground"),
                    freq(.atis, 127.600, "Anchorage ATIS"),
                    freq(.approach, 118.600, "Anchorage Approach")
                ]
            ),

            Airport(
                icao: "PAFA", faaID: "FAI", name: "Fairbanks Intl",
                latitude: 64.8154, longitude: -147.8564, elevation: 434,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZAN", fssID: nil, magneticVariation: 19.0,
                patternAltitude: 1400, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("02L/20R", length: 11800, width: 150, surface: .asphalt,
                        baseEnd: "02L", recipEnd: "20R",
                        baseLat: 64.8017, baseLon: -147.8633,
                        recipLat: 64.8300, recipLon: -147.8500),
                    rwy("02R/20L", length: 6501, width: 150, surface: .asphalt,
                        baseEnd: "02R", recipEnd: "20L",
                        baseLat: 64.8083, baseLon: -147.8567,
                        recipLat: 64.8250, recipLon: -147.8467)
                ],
                frequencies: [
                    freq(.tower, 118.300, "Fairbanks Tower"),
                    freq(.ground, 121.900, "Fairbanks Ground"),
                    freq(.atis, 119.750, "Fairbanks ATIS"),
                    freq(.approach, 125.200, "Fairbanks Approach")
                ]
            ),

            Airport(
                icao: "PAJN", faaID: "JNU", name: "Juneau Intl",
                latitude: 58.3550, longitude: -134.5763, elevation: 21,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZAN", fssID: nil, magneticVariation: 21.0,
                patternAltitude: 1000, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("08/26", length: 8857, width: 150, surface: .asphalt,
                        baseEnd: "08", recipEnd: "26",
                        baseLat: 58.3550, baseLon: -134.5950,
                        recipLat: 58.3550, recipLon: -134.5583)
                ],
                frequencies: [
                    freq(.tower, 118.700, "Juneau Tower"),
                    freq(.ground, 121.900, "Juneau Ground"),
                    freq(.atis, 135.200, "Juneau ATIS")
                ]
            ),

            Airport(
                icao: "PAEN", faaID: "ENA", name: "Kenai Muni",
                latitude: 60.5731, longitude: -151.2450, elevation: 99,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZAN", fssID: nil, magneticVariation: 18.0,
                patternAltitude: 1100, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("02L/20R", length: 7575, width: 150, surface: .asphalt,
                        baseEnd: "02L", recipEnd: "20R",
                        baseLat: 60.5633, baseLon: -151.2483,
                        recipLat: 60.5833, recipLon: -151.2417),
                    rwy("02R/20L", length: 4000, width: 75, surface: .asphalt,
                        baseEnd: "02R", recipEnd: "20L",
                        baseLat: 60.5683, baseLon: -151.2417,
                        recipLat: 60.5800, recipLon: -151.2383)
                ],
                frequencies: [
                    freq(.tower, 118.200, "Kenai Tower"),
                    freq(.ground, 121.800, "Kenai Ground"),
                    freq(.awos, 118.575, "Kenai AWOS")
                ]
            ),

            // ── Hawaii ──

            Airport(
                icao: "PHNL", faaID: "HNL", name: "Daniel K Inouye Intl",
                latitude: 21.3187, longitude: -157.9225, elevation: 13,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZHN", fssID: nil, magneticVariation: 10.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("04L/22R", length: 12357, width: 200, surface: .asphalt,
                        baseEnd: "04L", recipEnd: "22R",
                        baseLat: 21.3100, baseLon: -157.9367,
                        recipLat: 21.3283, recipLon: -157.9117),
                    rwy("04R/22L", length: 12000, width: 150, surface: .asphalt,
                        baseEnd: "04R", recipEnd: "22L",
                        baseLat: 21.3067, baseLon: -157.9300,
                        recipLat: 21.3250, recipLon: -157.9050),
                    rwy("08L/26R", length: 9000, width: 150, surface: .asphalt,
                        baseEnd: "08L", recipEnd: "26R",
                        baseLat: 21.3250, baseLon: -157.9367,
                        recipLat: 21.3183, recipLon: -157.9100),
                    rwy("08R/26L", length: 6952, width: 150, surface: .asphalt,
                        baseEnd: "08R", recipEnd: "26L",
                        baseLat: 21.3217, baseLon: -157.9317,
                        recipLat: 21.3167, recipLon: -157.9100)
                ],
                frequencies: [
                    freq(.tower, 118.100, "Honolulu Tower"),
                    freq(.ground, 121.900, "Honolulu Ground"),
                    freq(.atis, 127.900, "Honolulu ATIS"),
                    freq(.approach, 118.300, "Honolulu Approach"),
                    freq(.clearance, 121.400, "Honolulu Clearance")
                ]
            ),

            Airport(
                icao: "PHOG", faaID: "OGG", name: "Kahului",
                latitude: 20.8986, longitude: -156.4305, elevation: 54,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZHN", fssID: nil, magneticVariation: 10.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("02/20", length: 6995, width: 150, surface: .asphalt,
                        baseEnd: "02", recipEnd: "20",
                        baseLat: 20.8900, baseLon: -156.4317,
                        recipLat: 20.9083, recipLon: -156.4283),
                    rwy("05/23", length: 4991, width: 150, surface: .asphalt,
                        baseEnd: "05", recipEnd: "23",
                        baseLat: 20.8933, baseLon: -156.4383,
                        recipLat: 20.9017, recipLon: -156.4250)
                ],
                frequencies: [
                    freq(.tower, 118.700, "Kahului Tower"),
                    freq(.ground, 121.900, "Kahului Ground"),
                    freq(.atis, 127.000, "Kahului ATIS")
                ]
            ),

            Airport(
                icao: "PHKO", faaID: "KOA", name: "Ellison Onizuka Kona Intl",
                latitude: 19.7388, longitude: -156.0456, elevation: 47,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZHN", fssID: nil, magneticVariation: 10.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("17/35", length: 11000, width: 150, surface: .asphalt,
                        baseEnd: "17", recipEnd: "35",
                        baseLat: 19.7517, baseLon: -156.0467,
                        recipLat: 19.7250, recipLon: -156.0450)
                ],
                frequencies: [
                    freq(.tower, 118.600, "Kona Tower"),
                    freq(.ground, 121.900, "Kona Ground"),
                    freq(.atis, 127.400, "Kona ATIS")
                ]
            ),

            Airport(
                icao: "PHLI", faaID: "LIH", name: "Lihue",
                latitude: 21.9760, longitude: -159.3389, elevation: 153,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZHN", fssID: nil, magneticVariation: 10.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("03/21", length: 6500, width: 150, surface: .asphalt,
                        baseEnd: "03", recipEnd: "21",
                        baseLat: 21.9683, baseLon: -159.3433,
                        recipLat: 21.9833, recipLon: -159.3350),
                    rwy("17/35", length: 5993, width: 150, surface: .asphalt,
                        baseEnd: "17", recipEnd: "35",
                        baseLat: 21.9833, baseLon: -159.3400,
                        recipLat: 21.9683, recipLon: -159.3367)
                ],
                frequencies: [
                    freq(.tower, 118.300, "Lihue Tower"),
                    freq(.ground, 121.900, "Lihue Ground"),
                    freq(.atis, 127.600, "Lihue ATIS")
                ]
            ),
        ]
    }
}
