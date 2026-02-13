//
//  WestCoastAirports.swift
//  efb-212
//
//  California and Nevada airports seed data.
//

import Foundation

extension AirportSeedData {

    nonisolated static func westCoastAirports() -> [Airport] {
        [
            // ── San Francisco Bay Area ──

            Airport(
                icao: "KSFO", faaID: "SFO", name: "San Francisco Intl",
                latitude: 37.6213, longitude: -122.3790, elevation: 13,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZOA", fssID: nil, magneticVariation: 14.0,
                patternAltitude: 1000, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("10L/28R", length: 11870, width: 200, surface: .asphalt,
                        baseEnd: "10L", recipEnd: "28R",
                        baseLat: 37.6286, baseLon: -122.3930,
                        recipLat: 37.6117, recipLon: -122.3573),
                    rwy("10R/28L", length: 11381, width: 200, surface: .asphalt,
                        baseEnd: "10R", recipEnd: "28L",
                        baseLat: 37.6233, baseLon: -122.3940,
                        recipLat: 37.6067, recipLon: -122.3583),
                    rwy("01L/19R", length: 7650, width: 200, surface: .asphalt,
                        baseEnd: "01L", recipEnd: "19R",
                        baseLat: 37.6098, baseLon: -122.3816,
                        recipLat: 37.6303, recipLon: -122.3720),
                    rwy("01R/19L", length: 8648, width: 200, surface: .asphalt,
                        baseEnd: "01R", recipEnd: "19L",
                        baseLat: 37.6098, baseLon: -122.3730,
                        recipLat: 37.6330, recipLon: -122.3630)
                ],
                frequencies: [
                    freq(.tower, 120.500, "SFO Tower"),
                    freq(.ground, 121.800, "SFO Ground"),
                    freq(.atis, 118.850, "SFO ATIS"),
                    freq(.approach, 135.650, "NorCal Approach"),
                    freq(.clearance, 118.200, "SFO Clearance")
                ]
            ),

            Airport(
                icao: "KOAK", faaID: "OAK", name: "Oakland Intl",
                latitude: 37.7213, longitude: -122.2208, elevation: 9,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZOA", fssID: nil, magneticVariation: 14.0,
                patternAltitude: 1000, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("12/30", length: 10520, width: 150, surface: .asphalt,
                        baseEnd: "12", recipEnd: "30",
                        baseLat: 37.7283, baseLon: -122.2350,
                        recipLat: 37.7100, recipLon: -122.2050),
                    rwy("10L/28R", length: 6213, width: 150, surface: .asphalt,
                        baseEnd: "10L", recipEnd: "28R",
                        baseLat: 37.7267, baseLon: -122.2317,
                        recipLat: 37.7200, recipLon: -122.2133),
                    rwy("10R/28L", length: 5454, width: 150, surface: .asphalt,
                        baseEnd: "10R", recipEnd: "28L",
                        baseLat: 37.7233, baseLon: -122.2300,
                        recipLat: 37.7183, recipLon: -122.2133)
                ],
                frequencies: [
                    freq(.tower, 118.300, "Oakland Tower"),
                    freq(.ground, 121.900, "Oakland Ground"),
                    freq(.atis, 128.500, "Oakland ATIS"),
                    freq(.approach, 125.350, "NorCal Approach"),
                    freq(.clearance, 118.200, "Oakland Clearance")
                ]
            ),

            Airport(
                icao: "KSJC", faaID: "SJC", name: "San Jose Intl",
                latitude: 37.3626, longitude: -121.9291, elevation: 62,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZOA", fssID: nil, magneticVariation: 14.0,
                patternAltitude: 1000, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("12L/30R", length: 11000, width: 150, surface: .asphalt,
                        baseEnd: "12L", recipEnd: "30R",
                        baseLat: 37.3750, baseLon: -121.9433,
                        recipLat: 37.3500, recipLon: -121.9133),
                    rwy("12R/30L", length: 11000, width: 150, surface: .asphalt,
                        baseEnd: "12R", recipEnd: "30L",
                        baseLat: 37.3717, baseLon: -121.9400,
                        recipLat: 37.3467, recipLon: -121.9100)
                ],
                frequencies: [
                    freq(.tower, 124.000, "San Jose Tower"),
                    freq(.ground, 121.700, "San Jose Ground"),
                    freq(.atis, 114.100, "San Jose ATIS"),
                    freq(.approach, 124.000, "NorCal Approach")
                ]
            ),

            Airport(
                icao: "KPAO", faaID: "PAO", name: "Palo Alto",
                latitude: 37.4611, longitude: -122.1150, elevation: 4,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: 135.275, unicomFrequency: nil,
                artccID: "ZOA", fssID: nil, magneticVariation: 14.0,
                patternAltitude: 800, fuelTypes: ["100LL"],
                hasBeaconLight: true,
                runways: [
                    rwy("13/31", length: 2443, width: 60, surface: .asphalt,
                        lighting: .partTime,
                        baseEnd: "13", recipEnd: "31",
                        baseLat: 37.4650, baseLon: -122.1200,
                        recipLat: 37.4572, recipLon: -122.1100)
                ],
                frequencies: [
                    freq(.ctaf, 135.275, "Palo Alto Traffic"),
                    freq(.atis, 127.850, "Palo Alto ATIS")
                ]
            ),

            Airport(
                icao: "KRHV", faaID: "RHV", name: "Reid-Hillview",
                latitude: 37.3329, longitude: -121.8199, elevation: 135,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZOA", fssID: nil, magneticVariation: 14.0,
                patternAltitude: 1000, fuelTypes: ["100LL"],
                hasBeaconLight: true,
                runways: [
                    rwy("13L/31R", length: 3100, width: 75, surface: .asphalt,
                        baseEnd: "13L", recipEnd: "31R",
                        baseLat: 37.3367, baseLon: -121.8250,
                        recipLat: 37.3292, recipLon: -121.8150),
                    rwy("13R/31L", length: 3100, width: 75, surface: .asphalt,
                        baseEnd: "13R", recipEnd: "31L",
                        baseLat: 37.3350, baseLon: -121.8233,
                        recipLat: 37.3275, recipLon: -121.8133)
                ],
                frequencies: [
                    freq(.tower, 132.750, "Reid-Hillview Tower"),
                    freq(.ground, 121.600, "Reid-Hillview Ground"),
                    freq(.atis, 125.200, "Reid-Hillview ATIS")
                ]
            ),

            Airport(
                icao: "KSQL", faaID: "SQL", name: "San Carlos",
                latitude: 37.5118, longitude: -122.2495, elevation: 5,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZOA", fssID: nil, magneticVariation: 14.0,
                patternAltitude: 800, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("12/30", length: 2600, width: 75, surface: .asphalt,
                        baseEnd: "12", recipEnd: "30",
                        baseLat: 37.5150, baseLon: -122.2533,
                        recipLat: 37.5086, recipLon: -122.2457)
                ],
                frequencies: [
                    freq(.tower, 119.000, "San Carlos Tower"),
                    freq(.ground, 121.600, "San Carlos Ground"),
                    freq(.atis, 125.900, "San Carlos ATIS")
                ]
            ),

            Airport(
                icao: "KHWD", faaID: "HWD", name: "Hayward Executive",
                latitude: 37.6592, longitude: -122.1217, elevation: 52,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZOA", fssID: nil, magneticVariation: 14.0,
                patternAltitude: 1000, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("10L/28R", length: 5694, width: 150, surface: .asphalt,
                        baseEnd: "10L", recipEnd: "28R",
                        baseLat: 37.6617, baseLon: -122.1317,
                        recipLat: 37.6567, recipLon: -122.1117),
                    rwy("10R/28L", length: 3107, width: 75, surface: .asphalt,
                        baseEnd: "10R", recipEnd: "28L",
                        baseLat: 37.6583, baseLon: -122.1283,
                        recipLat: 37.6550, recipLon: -122.1133)
                ],
                frequencies: [
                    freq(.tower, 120.200, "Hayward Tower"),
                    freq(.ground, 121.400, "Hayward Ground"),
                    freq(.atis, 127.000, "Hayward ATIS")
                ]
            ),

            Airport(
                icao: "KCCR", faaID: "CCR", name: "Buchanan Field",
                latitude: 37.9897, longitude: -122.0569, elevation: 23,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZOA", fssID: nil, magneticVariation: 14.0,
                patternAltitude: 1000, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("01L/19R", length: 5001, width: 150, surface: .asphalt,
                        baseEnd: "01L", recipEnd: "19R",
                        baseLat: 37.9833, baseLon: -122.0583,
                        recipLat: 37.9967, recipLon: -122.0550),
                    rwy("01R/19L", length: 2770, width: 75, surface: .asphalt,
                        baseEnd: "01R", recipEnd: "19L",
                        baseLat: 37.9850, baseLon: -122.0550,
                        recipLat: 37.9933, recipLon: -122.0533)
                ],
                frequencies: [
                    freq(.tower, 123.900, "Buchanan Tower"),
                    freq(.ground, 121.600, "Buchanan Ground"),
                    freq(.atis, 125.800, "Buchanan ATIS")
                ]
            ),

            Airport(
                icao: "KLVK", faaID: "LVK", name: "Livermore Muni",
                latitude: 37.6934, longitude: -121.8204, elevation: 400,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZOA", fssID: nil, magneticVariation: 14.0,
                patternAltitude: 1200, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("07L/25R", length: 5253, width: 100, surface: .asphalt,
                        baseEnd: "07L", recipEnd: "25R",
                        baseLat: 37.6917, baseLon: -121.8300,
                        recipLat: 37.6950, recipLon: -121.8117),
                    rwy("07R/25L", length: 2699, width: 75, surface: .asphalt,
                        baseEnd: "07R", recipEnd: "25L",
                        baseLat: 37.6900, baseLon: -121.8267,
                        recipLat: 37.6917, recipLon: -121.8150)
                ],
                frequencies: [
                    freq(.tower, 118.100, "Livermore Tower"),
                    freq(.ground, 121.600, "Livermore Ground"),
                    freq(.atis, 119.650, "Livermore ATIS")
                ]
            ),

            // ── Southern California ──

            Airport(
                icao: "KLAX", faaID: "LAX", name: "Los Angeles Intl",
                latitude: 33.9425, longitude: -118.4081, elevation: 128,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZLA", fssID: nil, magneticVariation: 13.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("06L/24R", length: 8925, width: 150, surface: .asphalt,
                        baseEnd: "06L", recipEnd: "24R",
                        baseLat: 33.9500, baseLon: -118.4217,
                        recipLat: 33.9417, recipLon: -118.3983),
                    rwy("06R/24L", length: 10285, width: 150, surface: .asphalt,
                        baseEnd: "06R", recipEnd: "24L",
                        baseLat: 33.9467, baseLon: -118.4233,
                        recipLat: 33.9367, recipLon: -118.3950),
                    rwy("07L/25R", length: 12091, width: 150, surface: .concrete,
                        baseEnd: "07L", recipEnd: "25R",
                        baseLat: 33.9383, baseLon: -118.4233,
                        recipLat: 33.9333, recipLon: -118.3867),
                    rwy("07R/25L", length: 11095, width: 200, surface: .concrete,
                        baseEnd: "07R", recipEnd: "25L",
                        baseLat: 33.9350, baseLon: -118.4200,
                        recipLat: 33.9317, recipLon: -118.3867)
                ],
                frequencies: [
                    freq(.tower, 133.900, "LAX Tower"),
                    freq(.ground, 121.650, "LAX Ground South"),
                    freq(.atis, 133.800, "LAX ATIS"),
                    freq(.approach, 124.500, "SoCal Approach"),
                    freq(.clearance, 121.400, "LAX Clearance")
                ]
            ),

            Airport(
                icao: "KSAN", faaID: "SAN", name: "San Diego Intl",
                latitude: 32.7336, longitude: -117.1897, elevation: 17,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZLA", fssID: nil, magneticVariation: 12.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("09/27", length: 9401, width: 200, surface: .asphalt,
                        baseEnd: "09", recipEnd: "27",
                        baseLat: 32.7333, baseLon: -117.2033,
                        recipLat: 32.7333, recipLon: -117.1750)
                ],
                frequencies: [
                    freq(.tower, 118.300, "Lindbergh Tower"),
                    freq(.ground, 123.900, "Lindbergh Ground"),
                    freq(.atis, 134.800, "San Diego ATIS"),
                    freq(.approach, 119.600, "SoCal Approach")
                ]
            ),

            Airport(
                icao: "KSNA", faaID: "SNA", name: "John Wayne-Orange County",
                latitude: 33.6757, longitude: -117.8682, elevation: 56,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZLA", fssID: nil, magneticVariation: 13.0,
                patternAltitude: 1000, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("02L/20R", length: 5701, width: 150, surface: .asphalt,
                        baseEnd: "02L", recipEnd: "20R",
                        baseLat: 33.6683, baseLon: -117.8700,
                        recipLat: 33.6833, recipLon: -117.8650),
                    rwy("02R/20L", length: 2887, width: 75, surface: .asphalt,
                        baseEnd: "02R", recipEnd: "20L",
                        baseLat: 33.6700, baseLon: -117.8667,
                        recipLat: 33.6783, recipLon: -117.8633)
                ],
                frequencies: [
                    freq(.tower, 119.900, "John Wayne Tower"),
                    freq(.ground, 126.000, "John Wayne Ground"),
                    freq(.atis, 126.000, "John Wayne ATIS"),
                    freq(.approach, 124.100, "SoCal Approach")
                ]
            ),

            Airport(
                icao: "KCRQ", faaID: "CRQ", name: "McClellan-Palomar",
                latitude: 33.1283, longitude: -117.2803, elevation: 331,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZLA", fssID: nil, magneticVariation: 12.0,
                patternAltitude: 1200, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("06/24", length: 4897, width: 150, surface: .asphalt,
                        baseEnd: "06", recipEnd: "24",
                        baseLat: 33.1267, baseLon: -117.2883,
                        recipLat: 33.1300, recipLon: -117.2717)
                ],
                frequencies: [
                    freq(.tower, 132.350, "Palomar Tower"),
                    freq(.ground, 121.600, "Palomar Ground"),
                    freq(.atis, 128.350, "Palomar ATIS")
                ]
            ),

            Airport(
                icao: "KBUR", faaID: "BUR", name: "Hollywood Burbank",
                latitude: 34.2007, longitude: -118.3585, elevation: 778,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZLA", fssID: nil, magneticVariation: 13.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("08/26", length: 6886, width: 150, surface: .asphalt,
                        baseEnd: "08", recipEnd: "26",
                        baseLat: 34.2017, baseLon: -118.3717,
                        recipLat: 34.1983, recipLon: -118.3450),
                    rwy("15/33", length: 5802, width: 150, surface: .asphalt,
                        baseEnd: "15", recipEnd: "33",
                        baseLat: 34.2067, baseLon: -118.3617,
                        recipLat: 34.1933, recipLon: -118.3533)
                ],
                frequencies: [
                    freq(.tower, 119.500, "Burbank Tower"),
                    freq(.ground, 121.900, "Burbank Ground"),
                    freq(.atis, 126.850, "Burbank ATIS"),
                    freq(.approach, 124.500, "SoCal Approach")
                ]
            ),

            Airport(
                icao: "KSMO", faaID: "SMO", name: "Santa Monica Muni",
                latitude: 34.0158, longitude: -118.4513, elevation: 177,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZLA", fssID: nil, magneticVariation: 13.0,
                patternAltitude: 1100, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("03/21", length: 4987, width: 150, surface: .asphalt,
                        baseEnd: "03", recipEnd: "21",
                        baseLat: 34.0100, baseLon: -118.4550,
                        recipLat: 34.0217, recipLon: -118.4467)
                ],
                frequencies: [
                    freq(.tower, 120.100, "Santa Monica Tower"),
                    freq(.ground, 121.900, "Santa Monica Ground"),
                    freq(.atis, 119.150, "Santa Monica ATIS")
                ]
            ),

            Airport(
                icao: "KVNY", faaID: "VNY", name: "Van Nuys",
                latitude: 34.2098, longitude: -118.4900, elevation: 802,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZLA", fssID: nil, magneticVariation: 13.0,
                patternAltitude: 1600, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("16L/34R", length: 4011, width: 75, surface: .asphalt,
                        baseEnd: "16L", recipEnd: "34R",
                        baseLat: 34.2150, baseLon: -118.4933,
                        recipLat: 34.2050, recipLon: -118.4867),
                    rwy("16R/34L", length: 8001, width: 150, surface: .asphalt,
                        baseEnd: "16R", recipEnd: "34L",
                        baseLat: 34.2200, baseLon: -118.4883,
                        recipLat: 34.1983, recipLon: -118.4883)
                ],
                frequencies: [
                    freq(.tower, 119.300, "Van Nuys Tower"),
                    freq(.ground, 121.700, "Van Nuys Ground"),
                    freq(.atis, 113.100, "Van Nuys ATIS"),
                    freq(.approach, 120.200, "SoCal Approach")
                ]
            ),

            Airport(
                icao: "KTOA", faaID: "TOA", name: "Zamperini Field",
                latitude: 33.8034, longitude: -118.3396, elevation: 103,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZLA", fssID: nil, magneticVariation: 13.0,
                patternAltitude: 1000, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("11L/29R", length: 5001, width: 150, surface: .asphalt,
                        baseEnd: "11L", recipEnd: "29R",
                        baseLat: 33.8033, baseLon: -118.3483,
                        recipLat: 33.8033, recipLon: -118.3317),
                    rwy("11R/29L", length: 3000, width: 60, surface: .asphalt,
                        baseEnd: "11R", recipEnd: "29L",
                        baseLat: 33.8017, baseLon: -118.3450,
                        recipLat: 33.8017, recipLon: -118.3333)
                ],
                frequencies: [
                    freq(.tower, 124.000, "Torrance Tower"),
                    freq(.ground, 121.800, "Torrance Ground"),
                    freq(.atis, 126.225, "Torrance ATIS")
                ]
            ),

            Airport(
                icao: "KCMA", faaID: "CMA", name: "Camarillo",
                latitude: 34.2137, longitude: -119.0943, elevation: 77,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZLA", fssID: nil, magneticVariation: 13.0,
                patternAltitude: 900, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("08/26", length: 6013, width: 150, surface: .asphalt,
                        baseEnd: "08", recipEnd: "26",
                        baseLat: 34.2133, baseLon: -119.1050,
                        recipLat: 34.2133, recipLon: -119.0833)
                ],
                frequencies: [
                    freq(.tower, 120.900, "Camarillo Tower"),
                    freq(.ground, 121.800, "Camarillo Ground"),
                    freq(.awos, 118.575, "Camarillo AWOS")
                ]
            ),

            // ── Central California ──

            Airport(
                icao: "KSMF", faaID: "SMF", name: "Sacramento Intl",
                latitude: 38.6954, longitude: -121.5908, elevation: 27,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZOA", fssID: nil, magneticVariation: 14.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("16L/34R", length: 8601, width: 150, surface: .concrete,
                        baseEnd: "16L", recipEnd: "34R",
                        baseLat: 38.7067, baseLon: -121.5950,
                        recipLat: 38.6833, recipLon: -121.5867),
                    rwy("16R/34L", length: 8601, width: 150, surface: .concrete,
                        baseEnd: "16R", recipEnd: "34L",
                        baseLat: 38.7067, baseLon: -121.5883,
                        recipLat: 38.6833, recipLon: -121.5800)
                ],
                frequencies: [
                    freq(.tower, 119.500, "Sacramento Tower"),
                    freq(.ground, 121.700, "Sacramento Ground"),
                    freq(.atis, 125.150, "Sacramento ATIS"),
                    freq(.approach, 126.850, "NorCal Approach")
                ]
            ),

            Airport(
                icao: "KSAC", faaID: "SAC", name: "Sacramento Executive",
                latitude: 38.5125, longitude: -121.4933, elevation: 24,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZOA", fssID: nil, magneticVariation: 14.0,
                patternAltitude: 1000, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("02/20", length: 5503, width: 150, surface: .asphalt,
                        baseEnd: "02", recipEnd: "20",
                        baseLat: 38.5050, baseLon: -121.4950,
                        recipLat: 38.5200, recipLon: -121.4917),
                    rwy("12/30", length: 3836, width: 150, surface: .asphalt,
                        baseEnd: "12", recipEnd: "30",
                        baseLat: 38.5150, baseLon: -121.4983,
                        recipLat: 38.5100, recipLon: -121.4883)
                ],
                frequencies: [
                    freq(.tower, 124.350, "Sacramento Exec Tower"),
                    freq(.ground, 121.900, "Sacramento Exec Ground"),
                    freq(.atis, 118.850, "Sacramento Exec ATIS")
                ]
            ),

            Airport(
                icao: "KFAT", faaID: "FAT", name: "Fresno Yosemite Intl",
                latitude: 36.7762, longitude: -119.7181, elevation: 336,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZOA", fssID: nil, magneticVariation: 14.0,
                patternAltitude: 1200, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("11L/29R", length: 9222, width: 150, surface: .asphalt,
                        baseEnd: "11L", recipEnd: "29R",
                        baseLat: 36.7783, baseLon: -119.7333,
                        recipLat: 36.7733, recipLon: -119.7017),
                    rwy("11R/29L", length: 7204, width: 150, surface: .asphalt,
                        baseEnd: "11R", recipEnd: "29L",
                        baseLat: 36.7750, baseLon: -119.7267,
                        recipLat: 36.7717, recipLon: -119.7017)
                ],
                frequencies: [
                    freq(.tower, 118.200, "Fresno Tower"),
                    freq(.ground, 121.700, "Fresno Ground"),
                    freq(.atis, 118.850, "Fresno ATIS")
                ]
            ),

            Airport(
                icao: "KSBP", faaID: "SBP", name: "San Luis Obispo Co Rgnl",
                latitude: 35.2368, longitude: -120.6424, elevation: 212,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZLA", fssID: nil, magneticVariation: 14.0,
                patternAltitude: 1000, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("11/29", length: 6100, width: 150, surface: .asphalt,
                        baseEnd: "11", recipEnd: "29",
                        baseLat: 35.2367, baseLon: -120.6533,
                        recipLat: 35.2367, recipLon: -120.6317),
                    rwy("07/25", length: 2900, width: 150, surface: .asphalt,
                        baseEnd: "07", recipEnd: "25",
                        baseLat: 35.2400, baseLon: -120.6467,
                        recipLat: 35.2383, recipLon: -120.6367)
                ],
                frequencies: [
                    freq(.tower, 124.000, "San Luis Tower"),
                    freq(.ground, 121.600, "San Luis Ground"),
                    freq(.atis, 118.700, "San Luis ATIS")
                ]
            ),

            // ── Nevada ──

            Airport(
                icao: "KLAS", faaID: "LAS", name: "Harry Reid Intl",
                latitude: 36.0840, longitude: -115.1537, elevation: 2181,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZLA", fssID: nil, magneticVariation: 12.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("08L/26R", length: 14510, width: 150, surface: .asphalt,
                        baseEnd: "08L", recipEnd: "26R",
                        baseLat: 36.0800, baseLon: -115.1783,
                        recipLat: 36.0883, recipLon: -115.1283),
                    rwy("08R/26L", length: 10527, width: 150, surface: .asphalt,
                        baseEnd: "08R", recipEnd: "26L",
                        baseLat: 36.0767, baseLon: -115.1700,
                        recipLat: 36.0833, recipLon: -115.1333),
                    rwy("01L/19R", length: 9775, width: 150, surface: .asphalt,
                        baseEnd: "01L", recipEnd: "19R",
                        baseLat: 36.0733, baseLon: -115.1567,
                        recipLat: 36.0983, recipLon: -115.1483),
                    rwy("01R/19L", length: 9775, width: 150, surface: .asphalt,
                        baseEnd: "01R", recipEnd: "19L",
                        baseLat: 36.0733, baseLon: -115.1483,
                        recipLat: 36.0983, recipLon: -115.1400)
                ],
                frequencies: [
                    freq(.tower, 119.900, "Las Vegas Tower"),
                    freq(.ground, 121.700, "Las Vegas Ground"),
                    freq(.atis, 132.400, "Las Vegas ATIS"),
                    freq(.approach, 125.900, "Las Vegas Approach")
                ]
            ),

            Airport(
                icao: "KVGT", faaID: "VGT", name: "North Las Vegas",
                latitude: 36.2107, longitude: -115.1944, elevation: 2205,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZLA", fssID: nil, magneticVariation: 12.0,
                patternAltitude: 3200, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("07/25", length: 5004, width: 75, surface: .asphalt,
                        baseEnd: "07", recipEnd: "25",
                        baseLat: 36.2100, baseLon: -115.2033,
                        recipLat: 36.2117, recipLon: -115.1867),
                    rwy("12L/30R", length: 5004, width: 75, surface: .asphalt,
                        baseEnd: "12L", recipEnd: "30R",
                        baseLat: 36.2150, baseLon: -115.2017,
                        recipLat: 36.2067, recipLon: -115.1883),
                    rwy("12R/30L", length: 4203, width: 75, surface: .asphalt,
                        baseEnd: "12R", recipEnd: "30L",
                        baseLat: 36.2133, baseLon: -115.1983,
                        recipLat: 36.2067, recipLon: -115.1883)
                ],
                frequencies: [
                    freq(.tower, 125.700, "North Las Vegas Tower"),
                    freq(.ground, 121.750, "North Las Vegas Ground"),
                    freq(.atis, 118.050, "North Las Vegas ATIS")
                ]
            ),

            Airport(
                icao: "KHND", faaID: "HND", name: "Henderson Executive",
                latitude: 35.9728, longitude: -115.1343, elevation: 2492,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZLA", fssID: nil, magneticVariation: 12.0,
                patternAltitude: 3500, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("17L/35R", length: 6501, width: 100, surface: .asphalt,
                        baseEnd: "17L", recipEnd: "35R",
                        baseLat: 35.9817, baseLon: -115.1367,
                        recipLat: 35.9650, recipLon: -115.1317),
                    rwy("17R/35L", length: 5001, width: 75, surface: .asphalt,
                        baseEnd: "17R", recipEnd: "35L",
                        baseLat: 35.9783, baseLon: -115.1317,
                        recipLat: 35.9667, recipLon: -115.1283)
                ],
                frequencies: [
                    freq(.tower, 125.100, "Henderson Tower"),
                    freq(.ground, 121.600, "Henderson Ground"),
                    freq(.atis, 118.225, "Henderson ATIS")
                ]
            ),

            Airport(
                icao: "KRNO", faaID: "RNO", name: "Reno-Tahoe Intl",
                latitude: 39.4991, longitude: -119.7681, elevation: 4415,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZOA", fssID: nil, magneticVariation: 14.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("16L/34R", length: 11001, width: 150, surface: .asphalt,
                        baseEnd: "16L", recipEnd: "34R",
                        baseLat: 39.5117, baseLon: -119.7733,
                        recipLat: 39.4833, recipLon: -119.7617),
                    rwy("16R/34L", length: 9000, width: 150, surface: .asphalt,
                        baseEnd: "16R", recipEnd: "34L",
                        baseLat: 39.5083, baseLon: -119.7683,
                        recipLat: 39.4867, recipLon: -119.7583),
                    rwy("07/25", length: 6102, width: 150, surface: .asphalt,
                        baseEnd: "07", recipEnd: "25",
                        baseLat: 39.5017, baseLon: -119.7800,
                        recipLat: 39.4983, recipLon: -119.7583)
                ],
                frequencies: [
                    freq(.tower, 118.700, "Reno Tower"),
                    freq(.ground, 121.900, "Reno Ground"),
                    freq(.atis, 135.800, "Reno ATIS"),
                    freq(.approach, 119.200, "Reno Approach")
                ]
            ),
        ]
    }
}
