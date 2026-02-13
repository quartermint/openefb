//
//  SoutheastAirports.swift
//  efb-212
//
//  Southeast US airports seed data (FL, GA, NC, SC, VA, TN).
//

import Foundation

extension AirportSeedData {

    nonisolated static func southeastAirports() -> [Airport] {
        [
            Airport(
                icao: "KATL", faaID: "ATL", name: "Hartsfield-Jackson Atlanta Intl",
                latitude: 33.6367, longitude: -84.4281, elevation: 1026,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZTL", fssID: nil, magneticVariation: -5.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("08L/26R", length: 9000, width: 150, surface: .concrete,
                        baseEnd: "08L", recipEnd: "26R",
                        baseLat: 33.6400, baseLon: -84.4450,
                        recipLat: 33.6333, recipLon: -84.4133),
                    rwy("08R/26L", length: 9000, width: 150, surface: .concrete,
                        baseEnd: "08R", recipEnd: "26L",
                        baseLat: 33.6367, baseLon: -84.4450,
                        recipLat: 33.6300, recipLon: -84.4133),
                    rwy("09L/27R", length: 9000, width: 150, surface: .concrete,
                        baseEnd: "09L", recipEnd: "27R",
                        baseLat: 33.6333, baseLon: -84.4433,
                        recipLat: 33.6267, recipLon: -84.4117),
                    rwy("09R/27L", length: 11890, width: 150, surface: .concrete,
                        baseEnd: "09R", recipEnd: "27L",
                        baseLat: 33.6300, baseLon: -84.4483,
                        recipLat: 33.6200, recipLon: -84.4067),
                    rwy("10/28", length: 9000, width: 150, surface: .concrete,
                        baseEnd: "10", recipEnd: "28",
                        baseLat: 33.6267, baseLon: -84.4450,
                        recipLat: 33.6200, recipLon: -84.4133)
                ],
                frequencies: [
                    freq(.tower, 119.500, "Atlanta Tower"),
                    freq(.ground, 121.900, "Atlanta Ground"),
                    freq(.atis, 125.550, "Atlanta ATIS"),
                    freq(.approach, 119.100, "Atlanta Approach"),
                    freq(.clearance, 121.650, "Atlanta Clearance")
                ]
            ),

            Airport(
                icao: "KPDK", faaID: "PDK", name: "DeKalb-Peachtree",
                latitude: 33.8756, longitude: -84.3020, elevation: 1003,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZTL", fssID: nil, magneticVariation: -5.0,
                patternAltitude: 1800, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("03L/21R", length: 6001, width: 100, surface: .asphalt,
                        baseEnd: "03L", recipEnd: "21R",
                        baseLat: 33.8683, baseLon: -84.3067,
                        recipLat: 33.8833, recipLon: -84.2983),
                    rwy("03R/21L", length: 3746, width: 75, surface: .asphalt,
                        baseEnd: "03R", recipEnd: "21L",
                        baseLat: 33.8717, baseLon: -84.3033,
                        recipLat: 33.8800, recipLon: -84.2983)
                ],
                frequencies: [
                    freq(.tower, 120.900, "Peachtree Tower"),
                    freq(.ground, 121.600, "Peachtree Ground"),
                    freq(.atis, 125.600, "Peachtree ATIS")
                ]
            ),

            Airport(
                icao: "KMIA", faaID: "MIA", name: "Miami Intl",
                latitude: 25.7959, longitude: -80.2870, elevation: 8,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZMA", fssID: nil, magneticVariation: -5.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("08L/26R", length: 8600, width: 200, surface: .asphalt,
                        baseEnd: "08L", recipEnd: "26R",
                        baseLat: 25.8017, baseLon: -80.3017,
                        recipLat: 25.7933, recipLon: -80.2733),
                    rwy("08R/26L", length: 10506, width: 200, surface: .asphalt,
                        baseEnd: "08R", recipEnd: "26L",
                        baseLat: 25.7983, baseLon: -80.3050,
                        recipLat: 25.7883, recipLon: -80.2700),
                    rwy("09/27", length: 13016, width: 200, surface: .asphalt,
                        baseEnd: "09", recipEnd: "27",
                        baseLat: 25.7917, baseLon: -80.3100,
                        recipLat: 25.7850, recipLon: -80.2633),
                    rwy("12/30", length: 9354, width: 150, surface: .asphalt,
                        baseEnd: "12", recipEnd: "30",
                        baseLat: 25.8017, baseLon: -80.2933,
                        recipLat: 25.7867, recipLon: -80.2750)
                ],
                frequencies: [
                    freq(.tower, 118.300, "Miami Tower"),
                    freq(.ground, 121.800, "Miami Ground"),
                    freq(.atis, 132.450, "Miami ATIS"),
                    freq(.approach, 124.800, "Miami Approach")
                ]
            ),

            Airport(
                icao: "KFLL", faaID: "FLL", name: "Fort Lauderdale-Hollywood Intl",
                latitude: 26.0726, longitude: -80.1527, elevation: 9,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZMA", fssID: nil, magneticVariation: -5.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("10L/28R", length: 9000, width: 150, surface: .asphalt,
                        baseEnd: "10L", recipEnd: "28R",
                        baseLat: 26.0783, baseLon: -80.1700,
                        recipLat: 26.0700, recipLon: -80.1383),
                    rwy("10R/28L", length: 6930, width: 150, surface: .asphalt,
                        baseEnd: "10R", recipEnd: "28L",
                        baseLat: 26.0733, baseLon: -80.1667,
                        recipLat: 26.0667, recipLon: -80.1417)
                ],
                frequencies: [
                    freq(.tower, 119.350, "Fort Lauderdale Tower"),
                    freq(.ground, 121.400, "Fort Lauderdale Ground"),
                    freq(.atis, 128.375, "Fort Lauderdale ATIS"),
                    freq(.approach, 128.400, "Fort Lauderdale Approach")
                ]
            ),

            Airport(
                icao: "KTPA", faaID: "TPA", name: "Tampa Intl",
                latitude: 27.9755, longitude: -82.5332, elevation: 26,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZJX", fssID: nil, magneticVariation: -5.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("01L/19R", length: 11002, width: 150, surface: .asphalt,
                        baseEnd: "01L", recipEnd: "19R",
                        baseLat: 27.9617, baseLon: -82.5350,
                        recipLat: 27.9900, recipLon: -82.5317),
                    rwy("01R/19L", length: 11002, width: 150, surface: .asphalt,
                        baseEnd: "01R", recipEnd: "19L",
                        baseLat: 27.9617, baseLon: -82.5283,
                        recipLat: 27.9900, recipLon: -82.5250),
                    rwy("10/28", length: 6999, width: 150, surface: .asphalt,
                        baseEnd: "10", recipEnd: "28",
                        baseLat: 27.9783, baseLon: -82.5450,
                        recipLat: 27.9733, recipLon: -82.5200)
                ],
                frequencies: [
                    freq(.tower, 119.500, "Tampa Tower"),
                    freq(.ground, 121.700, "Tampa Ground"),
                    freq(.atis, 119.775, "Tampa ATIS"),
                    freq(.approach, 119.900, "Tampa Approach")
                ]
            ),

            Airport(
                icao: "KMCO", faaID: "MCO", name: "Orlando Intl",
                latitude: 28.4294, longitude: -81.3089, elevation: 96,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZJX", fssID: nil, magneticVariation: -5.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("17L/35R", length: 12005, width: 200, surface: .concrete,
                        baseEnd: "17L", recipEnd: "35R",
                        baseLat: 28.4467, baseLon: -81.3133,
                        recipLat: 28.4150, recipLon: -81.3050),
                    rwy("17R/35L", length: 12004, width: 200, surface: .concrete,
                        baseEnd: "17R", recipEnd: "35L",
                        baseLat: 28.4467, baseLon: -81.3017,
                        recipLat: 28.4150, recipLon: -81.2933),
                    rwy("18L/36R", length: 10000, width: 200, surface: .concrete,
                        baseEnd: "18L", recipEnd: "36R",
                        baseLat: 28.4433, baseLon: -81.3250,
                        recipLat: 28.4167, recipLon: -81.3200),
                    rwy("18R/36L", length: 9000, width: 150, surface: .concrete,
                        baseEnd: "18R", recipEnd: "36L",
                        baseLat: 28.4400, baseLon: -81.3317,
                        recipLat: 28.4167, recipLon: -81.3267)
                ],
                frequencies: [
                    freq(.tower, 118.450, "Orlando Tower"),
                    freq(.ground, 121.800, "Orlando Ground"),
                    freq(.atis, 124.800, "Orlando ATIS"),
                    freq(.approach, 124.800, "Orlando Approach")
                ]
            ),

            Airport(
                icao: "KORL", faaID: "ORL", name: "Orlando Executive",
                latitude: 28.5455, longitude: -81.3329, elevation: 113,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZJX", fssID: nil, magneticVariation: -5.0,
                patternAltitude: 1000, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("07/25", length: 6003, width: 150, surface: .asphalt,
                        baseEnd: "07", recipEnd: "25",
                        baseLat: 28.5450, baseLon: -81.3433,
                        recipLat: 28.5450, recipLon: -81.3233),
                    rwy("13/31", length: 4627, width: 100, surface: .asphalt,
                        baseEnd: "13", recipEnd: "31",
                        baseLat: 28.5500, baseLon: -81.3383,
                        recipLat: 28.5400, recipLon: -81.3283)
                ],
                frequencies: [
                    freq(.tower, 118.700, "Orlando Exec Tower"),
                    freq(.ground, 121.600, "Orlando Exec Ground"),
                    freq(.atis, 124.075, "Orlando Exec ATIS")
                ]
            ),

            Airport(
                icao: "KCLT", faaID: "CLT", name: "Charlotte Douglas Intl",
                latitude: 35.2140, longitude: -80.9431, elevation: 748,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZTL", fssID: nil, magneticVariation: -7.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("18L/36R", length: 10000, width: 150, surface: .concrete,
                        baseEnd: "18L", recipEnd: "36R",
                        baseLat: 35.2267, baseLon: -80.9517,
                        recipLat: 35.2000, recipLon: -80.9400),
                    rwy("18C/36C", length: 9000, width: 150, surface: .concrete,
                        baseEnd: "18C", recipEnd: "36C",
                        baseLat: 35.2267, baseLon: -80.9450,
                        recipLat: 35.2033, recipLon: -80.9350),
                    rwy("18R/36L", length: 10000, width: 150, surface: .concrete,
                        baseEnd: "18R", recipEnd: "36L",
                        baseLat: 35.2267, baseLon: -80.9383,
                        recipLat: 35.2000, recipLon: -80.9283),
                    rwy("05/23", length: 7502, width: 150, surface: .concrete,
                        baseEnd: "05", recipEnd: "23",
                        baseLat: 35.2100, baseLon: -80.9567,
                        recipLat: 35.2200, recipLon: -80.9333)
                ],
                frequencies: [
                    freq(.tower, 119.900, "Charlotte Tower"),
                    freq(.ground, 121.900, "Charlotte Ground"),
                    freq(.atis, 118.575, "Charlotte ATIS"),
                    freq(.approach, 125.350, "Charlotte Approach")
                ]
            ),

            Airport(
                icao: "KRDU", faaID: "RDU", name: "Raleigh-Durham Intl",
                latitude: 35.8776, longitude: -78.7875, elevation: 435,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZDC", fssID: nil, magneticVariation: -8.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("05L/23R", length: 10000, width: 150, surface: .asphalt,
                        baseEnd: "05L", recipEnd: "23R",
                        baseLat: 35.8667, baseLon: -78.7983,
                        recipLat: 35.8883, recipLon: -78.7750),
                    rwy("05R/23L", length: 7500, width: 150, surface: .asphalt,
                        baseEnd: "05R", recipEnd: "23L",
                        baseLat: 35.8700, baseLon: -78.8017,
                        recipLat: 35.8867, recipLon: -78.7833)
                ],
                frequencies: [
                    freq(.tower, 124.750, "Raleigh Tower"),
                    freq(.ground, 121.900, "Raleigh Ground"),
                    freq(.atis, 120.700, "Raleigh ATIS"),
                    freq(.approach, 124.950, "Raleigh Approach")
                ]
            ),

            Airport(
                icao: "KIAD", faaID: "IAD", name: "Washington Dulles Intl",
                latitude: 38.9445, longitude: -77.4558, elevation: 313,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZDC", fssID: nil, magneticVariation: -10.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("01L/19R", length: 11500, width: 150, surface: .concrete,
                        baseEnd: "01L", recipEnd: "19R",
                        baseLat: 38.9300, baseLon: -77.4567,
                        recipLat: 38.9600, recipLon: -77.4500),
                    rwy("01C/19C", length: 11000, width: 150, surface: .concrete,
                        baseEnd: "01C", recipEnd: "19C",
                        baseLat: 38.9317, baseLon: -77.4500,
                        recipLat: 38.9600, recipLon: -77.4433),
                    rwy("01R/19L", length: 11500, width: 150, surface: .concrete,
                        baseEnd: "01R", recipEnd: "19L",
                        baseLat: 38.9317, baseLon: -77.4433,
                        recipLat: 38.9617, recipLon: -77.4367),
                    rwy("12/30", length: 10501, width: 150, surface: .concrete,
                        baseEnd: "12", recipEnd: "30",
                        baseLat: 38.9500, baseLon: -77.4700,
                        recipLat: 38.9383, recipLon: -77.4350)
                ],
                frequencies: [
                    freq(.tower, 120.100, "Dulles Tower"),
                    freq(.ground, 121.900, "Dulles Ground"),
                    freq(.atis, 134.850, "Dulles ATIS"),
                    freq(.approach, 120.100, "Potomac Approach"),
                    freq(.clearance, 134.850, "Dulles Clearance")
                ]
            ),

            Airport(
                icao: "KDCA", faaID: "DCA", name: "Ronald Reagan Washington Natl",
                latitude: 38.8521, longitude: -77.0377, elevation: 15,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZDC", fssID: nil, magneticVariation: -10.0,
                patternAltitude: nil, fuelTypes: ["Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("01/19", length: 6869, width: 150, surface: .asphalt,
                        baseEnd: "01", recipEnd: "19",
                        baseLat: 38.8433, baseLon: -77.0400,
                        recipLat: 38.8617, recipLon: -77.0367),
                    rwy("04/22", length: 5000, width: 150, surface: .asphalt,
                        baseEnd: "04", recipEnd: "22",
                        baseLat: 38.8483, baseLon: -77.0417,
                        recipLat: 38.8583, recipLon: -77.0317)
                ],
                frequencies: [
                    freq(.tower, 119.100, "Reagan Tower"),
                    freq(.ground, 121.700, "Reagan Ground"),
                    freq(.atis, 132.650, "Reagan ATIS"),
                    freq(.approach, 119.100, "Potomac Approach")
                ]
            ),

            Airport(
                icao: "KJYO", faaID: "JYO", name: "Leesburg Executive",
                latitude: 39.0778, longitude: -77.5575, elevation: 389,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: 123.075, unicomFrequency: nil,
                artccID: "ZDC", fssID: nil, magneticVariation: -10.0,
                patternAltitude: 1300, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("17/35", length: 5500, width: 100, surface: .asphalt,
                        baseEnd: "17", recipEnd: "35",
                        baseLat: 39.0850, baseLon: -77.5583,
                        recipLat: 39.0700, recipLon: -77.5567)
                ],
                frequencies: [
                    freq(.ctaf, 123.075, "Leesburg Traffic"),
                    freq(.awos, 128.325, "Leesburg AWOS")
                ]
            ),

            Airport(
                icao: "KHEF", faaID: "HEF", name: "Manassas Regional",
                latitude: 38.7214, longitude: -77.5153, elevation: 192,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZDC", fssID: nil, magneticVariation: -10.0,
                patternAltitude: 1100, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("16L/34R", length: 6200, width: 100, surface: .asphalt,
                        baseEnd: "16L", recipEnd: "34R",
                        baseLat: 38.7300, baseLon: -77.5167,
                        recipLat: 38.7133, recipLon: -77.5133),
                    rwy("16R/34L", length: 3700, width: 100, surface: .asphalt,
                        baseEnd: "16R", recipEnd: "34L",
                        baseLat: 38.7267, baseLon: -77.5117,
                        recipLat: 38.7167, recipLon: -77.5100)
                ],
                frequencies: [
                    freq(.tower, 124.200, "Manassas Tower"),
                    freq(.ground, 121.600, "Manassas Ground"),
                    freq(.awos, 118.375, "Manassas AWOS")
                ]
            ),

            Airport(
                icao: "KBNA", faaID: "BNA", name: "Nashville Intl",
                latitude: 36.1246, longitude: -86.6782, elevation: 599,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZME", fssID: nil, magneticVariation: -4.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("02L/20R", length: 8001, width: 150, surface: .asphalt,
                        baseEnd: "02L", recipEnd: "20R",
                        baseLat: 36.1133, baseLon: -86.6817,
                        recipLat: 36.1350, recipLon: -86.6750),
                    rwy("02C/20C", length: 11030, width: 150, surface: .asphalt,
                        baseEnd: "02C", recipEnd: "20C",
                        baseLat: 36.1083, baseLon: -86.6733,
                        recipLat: 36.1383, recipLon: -86.6667),
                    rwy("02R/20L", length: 7703, width: 150, surface: .asphalt,
                        baseEnd: "02R", recipEnd: "20L",
                        baseLat: 36.1133, baseLon: -86.6650,
                        recipLat: 36.1333, recipLon: -86.6583),
                    rwy("13/31", length: 8000, width: 150, surface: .asphalt,
                        baseEnd: "13", recipEnd: "31",
                        baseLat: 36.1317, baseLon: -86.6883,
                        recipLat: 36.1183, recipLon: -86.6667)
                ],
                frequencies: [
                    freq(.tower, 118.600, "Nashville Tower"),
                    freq(.ground, 121.900, "Nashville Ground"),
                    freq(.atis, 127.400, "Nashville ATIS"),
                    freq(.approach, 118.000, "Nashville Approach")
                ]
            ),

            Airport(
                icao: "KJKA", faaID: "JKA", name: "Jack Edwards Natl",
                latitude: 30.2905, longitude: -87.6718, elevation: 25,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: 123.000, unicomFrequency: nil,
                artccID: "ZHU", fssID: nil, magneticVariation: -2.0,
                patternAltitude: 1000, fuelTypes: ["100LL"],
                hasBeaconLight: true,
                runways: [
                    rwy("09/27", length: 6960, width: 100, surface: .asphalt,
                        baseEnd: "09", recipEnd: "27",
                        baseLat: 30.2900, baseLon: -87.6833,
                        recipLat: 30.2900, recipLon: -87.6600)
                ],
                frequencies: [
                    freq(.ctaf, 123.000, "Jack Edwards Traffic"),
                    freq(.awos, 119.225, "Jack Edwards AWOS")
                ]
            ),
        ]
    }
}
