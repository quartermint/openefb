//
//  NortheastAirports.swift
//  efb-212
//
//  Northeast US airports seed data (NY, NJ, MA, CT, PA, MD).
//

import Foundation

extension AirportSeedData {

    nonisolated static func northeastAirports() -> [Airport] {
        [
            Airport(
                icao: "KJFK", faaID: "JFK", name: "John F Kennedy Intl",
                latitude: 40.6398, longitude: -73.7789, elevation: 13,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZNY", fssID: nil, magneticVariation: -13.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("04L/22R", length: 12079, width: 200, surface: .asphalt,
                        baseEnd: "04L", recipEnd: "22R",
                        baseLat: 40.6267, baseLon: -73.7883,
                        recipLat: 40.6533, recipLon: -73.7683),
                    rwy("04R/22L", length: 8400, width: 200, surface: .asphalt,
                        baseEnd: "04R", recipEnd: "22L",
                        baseLat: 40.6300, baseLon: -73.7800,
                        recipLat: 40.6483, recipLon: -73.7650),
                    rwy("13L/31R", length: 10000, width: 200, surface: .asphalt,
                        baseEnd: "13L", recipEnd: "31R",
                        baseLat: 40.6483, baseLon: -73.7917,
                        recipLat: 40.6317, recipLon: -73.7650),
                    rwy("13R/31L", length: 14511, width: 200, surface: .concrete,
                        baseEnd: "13R", recipEnd: "31L",
                        baseLat: 40.6517, baseLon: -73.8017,
                        recipLat: 40.6233, recipLon: -73.7550)
                ],
                frequencies: [
                    freq(.tower, 119.100, "Kennedy Tower"),
                    freq(.ground, 121.900, "Kennedy Ground"),
                    freq(.atis, 128.725, "Kennedy ATIS"),
                    freq(.approach, 132.400, "New York Approach"),
                    freq(.clearance, 135.050, "Kennedy Clearance")
                ]
            ),

            Airport(
                icao: "KLGA", faaID: "LGA", name: "LaGuardia",
                latitude: 40.7772, longitude: -73.8726, elevation: 21,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZNY", fssID: nil, magneticVariation: -13.0,
                patternAltitude: nil, fuelTypes: ["Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("04/22", length: 7001, width: 150, surface: .asphalt,
                        baseEnd: "04", recipEnd: "22",
                        baseLat: 40.7700, baseLon: -73.8800,
                        recipLat: 40.7850, recipLon: -73.8633),
                    rwy("13/31", length: 7001, width: 150, surface: .asphalt,
                        baseEnd: "13", recipEnd: "31",
                        baseLat: 40.7833, baseLon: -73.8817,
                        recipLat: 40.7700, recipLon: -73.8633)
                ],
                frequencies: [
                    freq(.tower, 118.700, "LaGuardia Tower"),
                    freq(.ground, 121.700, "LaGuardia Ground"),
                    freq(.atis, 125.950, "LaGuardia ATIS"),
                    freq(.approach, 120.800, "New York Approach"),
                    freq(.clearance, 125.800, "LaGuardia Clearance")
                ]
            ),

            Airport(
                icao: "KEWR", faaID: "EWR", name: "Newark Liberty Intl",
                latitude: 40.6925, longitude: -74.1687, elevation: 18,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZNY", fssID: nil, magneticVariation: -13.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("04L/22R", length: 11000, width: 150, surface: .asphalt,
                        baseEnd: "04L", recipEnd: "22R",
                        baseLat: 40.6800, baseLon: -74.1767,
                        recipLat: 40.7050, recipLon: -74.1583),
                    rwy("04R/22L", length: 10000, width: 150, surface: .asphalt,
                        baseEnd: "04R", recipEnd: "22L",
                        baseLat: 40.6833, baseLon: -74.1800,
                        recipLat: 40.7067, recipLon: -74.1617),
                    rwy("11/29", length: 6800, width: 150, surface: .asphalt,
                        baseEnd: "11", recipEnd: "29",
                        baseLat: 40.6983, baseLon: -74.1800,
                        recipLat: 40.6917, recipLon: -74.1567)
                ],
                frequencies: [
                    freq(.tower, 118.300, "Newark Tower"),
                    freq(.ground, 121.800, "Newark Ground"),
                    freq(.atis, 115.100, "Newark ATIS"),
                    freq(.approach, 119.200, "New York Approach"),
                    freq(.clearance, 118.300, "Newark Clearance")
                ]
            ),

            Airport(
                icao: "KHPN", faaID: "HPN", name: "Westchester County",
                latitude: 41.0670, longitude: -73.7076, elevation: 439,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZNY", fssID: nil, magneticVariation: -13.0,
                patternAltitude: 1200, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("11/29", length: 4451, width: 100, surface: .asphalt,
                        baseEnd: "11", recipEnd: "29",
                        baseLat: 41.0683, baseLon: -73.7150,
                        recipLat: 41.0650, recipLon: -73.7000),
                    rwy("16/34", length: 6549, width: 150, surface: .asphalt,
                        baseEnd: "16", recipEnd: "34",
                        baseLat: 41.0750, baseLon: -73.7100,
                        recipLat: 41.0583, recipLon: -73.7050)
                ],
                frequencies: [
                    freq(.tower, 119.700, "Westchester Tower"),
                    freq(.ground, 121.600, "Westchester Ground"),
                    freq(.atis, 118.550, "Westchester ATIS")
                ]
            ),

            Airport(
                icao: "KFRG", faaID: "FRG", name: "Republic",
                latitude: 40.7288, longitude: -73.4134, elevation: 82,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZNY", fssID: nil, magneticVariation: -13.0,
                patternAltitude: 1000, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("01/19", length: 5516, width: 150, surface: .asphalt,
                        baseEnd: "01", recipEnd: "19",
                        baseLat: 40.7217, baseLon: -73.4150,
                        recipLat: 40.7367, recipLon: -73.4117),
                    rwy("14/32", length: 6827, width: 150, surface: .asphalt,
                        baseEnd: "14", recipEnd: "32",
                        baseLat: 40.7350, baseLon: -73.4217,
                        recipLat: 40.7217, recipLon: -73.4050)
                ],
                frequencies: [
                    freq(.tower, 118.800, "Republic Tower"),
                    freq(.ground, 121.600, "Republic Ground"),
                    freq(.atis, 124.800, "Republic ATIS")
                ]
            ),

            Airport(
                icao: "KBOS", faaID: "BOS", name: "Boston Logan Intl",
                latitude: 42.3656, longitude: -71.0096, elevation: 20,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZBW", fssID: nil, magneticVariation: -14.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("04L/22R", length: 7861, width: 150, surface: .asphalt,
                        baseEnd: "04L", recipEnd: "22R",
                        baseLat: 42.3550, baseLon: -71.0183,
                        recipLat: 42.3767, recipLon: -70.9983),
                    rwy("04R/22L", length: 10005, width: 150, surface: .asphalt,
                        baseEnd: "04R", recipEnd: "22L",
                        baseLat: 42.3517, baseLon: -71.0150,
                        recipLat: 42.3783, recipLon: -70.9917),
                    rwy("09/27", length: 7000, width: 150, surface: .asphalt,
                        baseEnd: "09", recipEnd: "27",
                        baseLat: 42.3683, baseLon: -71.0200,
                        recipLat: 42.3617, recipLon: -70.9950),
                    rwy("15L/33R", length: 2557, width: 100, surface: .asphalt,
                        baseEnd: "15L", recipEnd: "33R",
                        baseLat: 42.3750, baseLon: -71.0100,
                        recipLat: 42.3683, recipLon: -71.0067),
                    rwy("15R/33L", length: 10083, width: 150, surface: .asphalt,
                        baseEnd: "15R", recipEnd: "33L",
                        baseLat: 42.3800, baseLon: -71.0150,
                        recipLat: 42.3533, recipLon: -70.9967)
                ],
                frequencies: [
                    freq(.tower, 128.800, "Boston Tower"),
                    freq(.ground, 121.900, "Boston Ground"),
                    freq(.atis, 135.000, "Boston ATIS"),
                    freq(.approach, 120.600, "Boston Approach"),
                    freq(.clearance, 121.650, "Boston Clearance")
                ]
            ),

            Airport(
                icao: "KBED", faaID: "BED", name: "Laurence G Hanscom Field",
                latitude: 42.4700, longitude: -71.2890, elevation: 133,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZBW", fssID: nil, magneticVariation: -14.0,
                patternAltitude: 1100, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("05/23", length: 5106, width: 150, surface: .asphalt,
                        baseEnd: "05", recipEnd: "23",
                        baseLat: 42.4650, baseLon: -71.2967,
                        recipLat: 42.4750, recipLon: -71.2800),
                    rwy("11/29", length: 7011, width: 150, surface: .asphalt,
                        baseEnd: "11", recipEnd: "29",
                        baseLat: 42.4733, baseLon: -71.3017,
                        recipLat: 42.4667, recipLon: -71.2783)
                ],
                frequencies: [
                    freq(.tower, 118.500, "Hanscom Tower"),
                    freq(.ground, 121.600, "Hanscom Ground"),
                    freq(.atis, 124.600, "Hanscom ATIS")
                ]
            ),

            Airport(
                icao: "KPHL", faaID: "PHL", name: "Philadelphia Intl",
                latitude: 39.8721, longitude: -75.2411, elevation: 36,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZNY", fssID: nil, magneticVariation: -12.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("09L/27R", length: 10506, width: 200, surface: .asphalt,
                        baseEnd: "09L", recipEnd: "27R",
                        baseLat: 39.8750, baseLon: -75.2617,
                        recipLat: 39.8700, recipLon: -75.2250),
                    rwy("09R/27L", length: 9500, width: 150, surface: .asphalt,
                        baseEnd: "09R", recipEnd: "27L",
                        baseLat: 39.8717, baseLon: -75.2583,
                        recipLat: 39.8667, recipLon: -75.2250),
                    rwy("08/26", length: 5000, width: 150, surface: .asphalt,
                        baseEnd: "08", recipEnd: "26",
                        baseLat: 39.8683, baseLon: -75.2533,
                        recipLat: 39.8650, recipLon: -75.2350),
                    rwy("17/35", length: 6500, width: 150, surface: .asphalt,
                        baseEnd: "17", recipEnd: "35",
                        baseLat: 39.8800, baseLon: -75.2400,
                        recipLat: 39.8633, recipLon: -75.2367)
                ],
                frequencies: [
                    freq(.tower, 118.500, "Philadelphia Tower"),
                    freq(.ground, 121.900, "Philadelphia Ground"),
                    freq(.atis, 133.400, "Philadelphia ATIS"),
                    freq(.approach, 119.750, "Philadelphia Approach")
                ]
            ),

            Airport(
                icao: "KBWI", faaID: "BWI", name: "Baltimore/Washington Intl",
                latitude: 39.1754, longitude: -76.6683, elevation: 146,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZDC", fssID: nil, magneticVariation: -10.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("10/28", length: 9519, width: 200, surface: .asphalt,
                        baseEnd: "10", recipEnd: "28",
                        baseLat: 39.1783, baseLon: -76.6867,
                        recipLat: 39.1733, recipLon: -76.6533),
                    rwy("15L/33R", length: 5000, width: 150, surface: .asphalt,
                        baseEnd: "15L", recipEnd: "33R",
                        baseLat: 39.1833, baseLon: -76.6717,
                        recipLat: 39.1717, recipLon: -76.6650),
                    rwy("15R/33L", length: 10502, width: 150, surface: .asphalt,
                        baseEnd: "15R", recipEnd: "33L",
                        baseLat: 39.1900, baseLon: -76.6767,
                        recipLat: 39.1633, recipLon: -76.6600)
                ],
                frequencies: [
                    freq(.tower, 119.000, "Baltimore Tower"),
                    freq(.ground, 121.900, "Baltimore Ground"),
                    freq(.atis, 115.100, "Baltimore ATIS"),
                    freq(.approach, 119.000, "Potomac Approach")
                ]
            ),

            Airport(
                icao: "KGAI", faaID: "GAI", name: "Montgomery Co Airpark",
                latitude: 39.1683, longitude: -77.1660, elevation: 539,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZDC", fssID: nil, magneticVariation: -10.0,
                patternAltitude: 1400, fuelTypes: ["100LL"],
                hasBeaconLight: true,
                runways: [
                    rwy("14/32", length: 4202, width: 75, surface: .asphalt,
                        baseEnd: "14", recipEnd: "32",
                        baseLat: 39.1733, baseLon: -77.1700,
                        recipLat: 39.1633, recipLon: -77.1617)
                ],
                frequencies: [
                    freq(.tower, 120.050, "Montgomery Tower"),
                    freq(.ground, 121.600, "Montgomery Ground"),
                    freq(.atis, 121.475, "Montgomery ATIS")
                ]
            ),

            Airport(
                icao: "KTTD", faaID: "TTD", name: "Portland Troutdale",
                latitude: 45.5494, longitude: -122.4013, elevation: 39,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZSE", fssID: nil, magneticVariation: 16.0,
                patternAltitude: 1000, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("07/25", length: 5399, width: 100, surface: .asphalt,
                        baseEnd: "07", recipEnd: "25",
                        baseLat: 45.5483, baseLon: -122.4117,
                        recipLat: 45.5500, recipLon: -122.3917)
                ],
                frequencies: [
                    freq(.tower, 128.950, "Troutdale Tower"),
                    freq(.ground, 121.600, "Troutdale Ground"),
                    freq(.awos, 134.750, "Troutdale AWOS")
                ]
            ),
        ]
    }
}
