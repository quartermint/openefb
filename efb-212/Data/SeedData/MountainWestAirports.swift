//
//  MountainWestAirports.swift
//  efb-212
//
//  Mountain West airports seed data (CO, UT, WY, MT, ID).
//

import Foundation

extension AirportSeedData {

    nonisolated static func mountainWestAirports() -> [Airport] {
        [
            Airport(
                icao: "KDEN", faaID: "DEN", name: "Denver Intl",
                latitude: 39.8561, longitude: -104.6737, elevation: 5431,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZDV", fssID: nil, magneticVariation: 8.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("07/25", length: 12000, width: 150, surface: .concrete,
                        baseEnd: "07", recipEnd: "25",
                        baseLat: 39.8517, baseLon: -104.6933,
                        recipLat: 39.8600, recipLon: -104.6533),
                    rwy("08/26", length: 12000, width: 150, surface: .concrete,
                        baseEnd: "08", recipEnd: "26",
                        baseLat: 39.8467, baseLon: -104.6917,
                        recipLat: 39.8550, recipLon: -104.6517),
                    rwy("16L/34R", length: 12000, width: 150, surface: .concrete,
                        baseEnd: "16L", recipEnd: "34R",
                        baseLat: 39.8700, baseLon: -104.6750,
                        recipLat: 39.8383, recipLon: -104.6650),
                    rwy("16R/34L", length: 16000, width: 200, surface: .concrete,
                        baseEnd: "16R", recipEnd: "34L",
                        baseLat: 39.8783, baseLon: -104.6617,
                        recipLat: 39.8333, recipLon: -104.6483),
                    rwy("17L/35R", length: 12000, width: 150, surface: .concrete,
                        baseEnd: "17L", recipEnd: "35R",
                        baseLat: 39.8700, baseLon: -104.6917,
                        recipLat: 39.8383, recipLon: -104.6817),
                    rwy("17R/35L", length: 12000, width: 150, surface: .concrete,
                        baseEnd: "17R", recipEnd: "35L",
                        baseLat: 39.8700, baseLon: -104.6833,
                        recipLat: 39.8383, recipLon: -104.6733)
                ],
                frequencies: [
                    freq(.tower, 118.300, "Denver Tower"),
                    freq(.ground, 121.850, "Denver Ground"),
                    freq(.atis, 132.350, "Denver ATIS"),
                    freq(.approach, 120.800, "Denver Approach"),
                    freq(.clearance, 134.025, "Denver Clearance")
                ]
            ),

            Airport(
                icao: "KAPA", faaID: "APA", name: "Centennial",
                latitude: 39.5701, longitude: -104.8493, elevation: 5885,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZDV", fssID: nil, magneticVariation: 8.0,
                patternAltitude: 6900, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("10/28", length: 4800, width: 75, surface: .asphalt,
                        baseEnd: "10", recipEnd: "28",
                        baseLat: 39.5717, baseLon: -104.8583,
                        recipLat: 39.5683, recipLon: -104.8417),
                    rwy("17L/35R", length: 10001, width: 100, surface: .asphalt,
                        baseEnd: "17L", recipEnd: "35R",
                        baseLat: 39.5833, baseLon: -104.8517,
                        recipLat: 39.5567, recipLon: -104.8467),
                    rwy("17R/35L", length: 7001, width: 75, surface: .asphalt,
                        baseEnd: "17R", recipEnd: "35L",
                        baseLat: 39.5800, baseLon: -104.8467,
                        recipLat: 39.5617, recipLon: -104.8433)
                ],
                frequencies: [
                    freq(.tower, 118.900, "Centennial Tower"),
                    freq(.ground, 121.600, "Centennial Ground"),
                    freq(.atis, 118.250, "Centennial ATIS"),
                    freq(.approach, 120.800, "Denver Approach")
                ]
            ),

            Airport(
                icao: "KBJC", faaID: "BJC", name: "Rocky Mountain Metropolitan",
                latitude: 39.9088, longitude: -105.1172, elevation: 5673,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZDV", fssID: nil, magneticVariation: 8.0,
                patternAltitude: 6700, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("03/21", length: 5500, width: 75, surface: .asphalt,
                        baseEnd: "03", recipEnd: "21",
                        baseLat: 39.9033, baseLon: -105.1200,
                        recipLat: 39.9150, recipLon: -105.1150),
                    rwy("12L/30R", length: 7002, width: 100, surface: .asphalt,
                        baseEnd: "12L", recipEnd: "30R",
                        baseLat: 39.9133, baseLon: -105.1283,
                        recipLat: 39.9050, recipLon: -105.1067),
                    rwy("12R/30L", length: 9000, width: 100, surface: .asphalt,
                        baseEnd: "12R", recipEnd: "30L",
                        baseLat: 39.9150, baseLon: -105.1317,
                        recipLat: 39.9033, recipLon: -105.1033)
                ],
                frequencies: [
                    freq(.tower, 119.700, "Rocky Mountain Tower"),
                    freq(.ground, 121.600, "Rocky Mountain Ground"),
                    freq(.atis, 121.200, "Rocky Mountain ATIS")
                ]
            ),

            Airport(
                icao: "KASE", faaID: "ASE", name: "Aspen-Pitkin Co",
                latitude: 39.2232, longitude: -106.8688, elevation: 7820,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZDV", fssID: nil, magneticVariation: 10.0,
                patternAltitude: 8800, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("15/33", length: 8006, width: 100, surface: .asphalt,
                        baseEnd: "15", recipEnd: "33",
                        baseLat: 39.2317, baseLon: -106.8750,
                        recipLat: 39.2150, recipLon: -106.8617)
                ],
                frequencies: [
                    freq(.tower, 118.850, "Aspen Tower"),
                    freq(.ground, 121.600, "Aspen Ground"),
                    freq(.atis, 127.725, "Aspen ATIS")
                ]
            ),

            Airport(
                icao: "KSLC", faaID: "SLC", name: "Salt Lake City Intl",
                latitude: 40.7884, longitude: -111.9778, elevation: 4227,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZLC", fssID: nil, magneticVariation: 12.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("16L/34R", length: 12002, width: 150, surface: .concrete,
                        baseEnd: "16L", recipEnd: "34R",
                        baseLat: 39.8033, baseLon: -111.9817,
                        recipLat: 40.7717, recipLon: -111.9717),
                    rwy("16R/34L", length: 12002, width: 150, surface: .concrete,
                        baseEnd: "16R", recipEnd: "34L",
                        baseLat: 40.8033, baseLon: -111.9750,
                        recipLat: 40.7717, recipLon: -111.9650),
                    rwy("17/35", length: 9596, width: 150, surface: .asphalt,
                        baseEnd: "17", recipEnd: "35",
                        baseLat: 40.8000, baseLon: -111.9683,
                        recipLat: 40.7750, recipLon: -111.9600),
                    rwy("14/32", length: 4898, width: 150, surface: .asphalt,
                        baseEnd: "14", recipEnd: "32",
                        baseLat: 40.7933, baseLon: -111.9850,
                        recipLat: 40.7850, recipLon: -111.9717)
                ],
                frequencies: [
                    freq(.tower, 118.300, "Salt Lake Tower"),
                    freq(.ground, 121.700, "Salt Lake Ground"),
                    freq(.atis, 124.750, "Salt Lake ATIS"),
                    freq(.approach, 124.300, "Salt Lake Approach")
                ]
            ),

            Airport(
                icao: "KOGD", faaID: "OGD", name: "Ogden-Hinckley",
                latitude: 41.1961, longitude: -112.0122, elevation: 4473,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZLC", fssID: nil, magneticVariation: 12.0,
                patternAltitude: 5500, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("03/21", length: 8103, width: 150, surface: .asphalt,
                        baseEnd: "03", recipEnd: "21",
                        baseLat: 41.1867, baseLon: -112.0183,
                        recipLat: 41.2067, recipLon: -112.0067),
                    rwy("07/25", length: 5503, width: 100, surface: .asphalt,
                        baseEnd: "07", recipEnd: "25",
                        baseLat: 41.1950, baseLon: -112.0233,
                        recipLat: 41.1967, recipLon: -112.0017)
                ],
                frequencies: [
                    freq(.tower, 125.325, "Ogden Tower"),
                    freq(.ground, 121.750, "Ogden Ground"),
                    freq(.atis, 118.775, "Ogden ATIS")
                ]
            ),

            Airport(
                icao: "KBOI", faaID: "BOI", name: "Boise Air Terminal",
                latitude: 43.5644, longitude: -116.2228, elevation: 2871,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZLC", fssID: nil, magneticVariation: 15.0,
                patternAltitude: 3800, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("10L/28R", length: 9763, width: 150, surface: .asphalt,
                        baseEnd: "10L", recipEnd: "28R",
                        baseLat: 43.5683, baseLon: -116.2433,
                        recipLat: 43.5617, recipLon: -116.2067),
                    rwy("10R/28L", length: 10000, width: 150, surface: .asphalt,
                        baseEnd: "10R", recipEnd: "28L",
                        baseLat: 43.5633, baseLon: -116.2417,
                        recipLat: 43.5567, recipLon: -116.2050)
                ],
                frequencies: [
                    freq(.tower, 118.100, "Boise Tower"),
                    freq(.ground, 121.700, "Boise Ground"),
                    freq(.atis, 126.400, "Boise ATIS"),
                    freq(.approach, 119.700, "Boise Approach")
                ]
            ),

            Airport(
                icao: "KJAC", faaID: "JAC", name: "Jackson Hole",
                latitude: 43.6073, longitude: -110.7378, elevation: 6451,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZLC", fssID: nil, magneticVariation: 13.0,
                patternAltitude: 7400, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("01/19", length: 6300, width: 150, surface: .asphalt,
                        baseEnd: "01", recipEnd: "19",
                        baseLat: 43.5983, baseLon: -110.7383,
                        recipLat: 43.6150, recipLon: -110.7367)
                ],
                frequencies: [
                    freq(.tower, 118.325, "Jackson Tower"),
                    freq(.ground, 121.600, "Jackson Ground"),
                    freq(.atis, 135.175, "Jackson ATIS")
                ]
            ),

            Airport(
                icao: "KBZN", faaID: "BZN", name: "Bozeman Yellowstone Intl",
                latitude: 45.7776, longitude: -111.1530, elevation: 4500,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZLC", fssID: nil, magneticVariation: 13.0,
                patternAltitude: 5500, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("12/30", length: 9003, width: 150, surface: .asphalt,
                        baseEnd: "12", recipEnd: "30",
                        baseLat: 45.7833, baseLon: -111.1683,
                        recipLat: 45.7717, recipLon: -111.1383),
                    rwy("03/21", length: 5996, width: 75, surface: .asphalt,
                        baseEnd: "03", recipEnd: "21",
                        baseLat: 45.7717, baseLon: -111.1567,
                        recipLat: 45.7850, recipLon: -111.1500)
                ],
                frequencies: [
                    freq(.tower, 118.800, "Bozeman Tower"),
                    freq(.ground, 121.600, "Bozeman Ground"),
                    freq(.atis, 119.600, "Bozeman ATIS")
                ]
            ),
        ]
    }
}
