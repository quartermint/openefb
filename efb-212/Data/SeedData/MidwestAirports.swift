//
//  MidwestAirports.swift
//  efb-212
//
//  Midwest airports seed data (IL, OH, MI, MN, WI, MO, IN, KS).
//

import Foundation

extension AirportSeedData {

    nonisolated static func midwestAirports() -> [Airport] {
        [
            Airport(
                icao: "KORD", faaID: "ORD", name: "Chicago O'Hare Intl",
                latitude: 41.9742, longitude: -87.9073, elevation: 672,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZAU", fssID: nil, magneticVariation: -3.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("10L/28R", length: 13000, width: 200, surface: .concrete,
                        baseEnd: "10L", recipEnd: "28R",
                        baseLat: 41.9800, baseLon: -87.9333,
                        recipLat: 41.9700, recipLon: -87.8867),
                    rwy("10C/28C", length: 10801, width: 200, surface: .concrete,
                        baseEnd: "10C", recipEnd: "28C",
                        baseLat: 41.9767, baseLon: -87.9283,
                        recipLat: 41.9683, recipLon: -87.8917),
                    rwy("10R/28L", length: 7500, width: 150, surface: .concrete,
                        baseEnd: "10R", recipEnd: "28L",
                        baseLat: 41.9717, baseLon: -87.9200,
                        recipLat: 41.9667, recipLon: -87.8950),
                    rwy("09L/27R", length: 7967, width: 150, surface: .concrete,
                        baseEnd: "09L", recipEnd: "27R",
                        baseLat: 41.9833, baseLon: -87.9150,
                        recipLat: 41.9800, recipLon: -87.8883)
                ],
                frequencies: [
                    freq(.tower, 120.750, "O'Hare Tower"),
                    freq(.ground, 121.750, "O'Hare Ground"),
                    freq(.atis, 135.400, "O'Hare ATIS"),
                    freq(.approach, 119.000, "Chicago Approach"),
                    freq(.clearance, 121.600, "O'Hare Clearance")
                ]
            ),

            Airport(
                icao: "KMDW", faaID: "MDW", name: "Chicago Midway Intl",
                latitude: 41.7868, longitude: -87.7522, elevation: 620,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZAU", fssID: nil, magneticVariation: -3.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("04L/22R", length: 5507, width: 150, surface: .asphalt,
                        baseEnd: "04L", recipEnd: "22R",
                        baseLat: 41.7800, baseLon: -87.7567,
                        recipLat: 41.7917, recipLon: -87.7467),
                    rwy("04R/22L", length: 6522, width: 150, surface: .asphalt,
                        baseEnd: "04R", recipEnd: "22L",
                        baseLat: 41.7817, baseLon: -87.7600,
                        recipLat: 41.7950, recipLon: -87.7483),
                    rwy("13C/31C", length: 6522, width: 150, surface: .asphalt,
                        baseEnd: "13C", recipEnd: "31C",
                        baseLat: 41.7933, baseLon: -87.7583,
                        recipLat: 41.7800, recipLon: -87.7450)
                ],
                frequencies: [
                    freq(.tower, 118.700, "Midway Tower"),
                    freq(.ground, 121.650, "Midway Ground"),
                    freq(.atis, 132.750, "Midway ATIS"),
                    freq(.approach, 119.000, "Chicago Approach")
                ]
            ),

            Airport(
                icao: "KPWK", faaID: "PWK", name: "Chicago Executive",
                latitude: 42.1142, longitude: -87.9015, elevation: 647,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZAU", fssID: nil, magneticVariation: -3.0,
                patternAltitude: 1600, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("16/34", length: 5001, width: 100, surface: .asphalt,
                        baseEnd: "16", recipEnd: "34",
                        baseLat: 42.1217, baseLon: -87.9033,
                        recipLat: 42.1083, recipLon: -87.8983),
                    rwy("12/30", length: 3680, width: 75, surface: .asphalt,
                        baseEnd: "12", recipEnd: "30",
                        baseLat: 42.1167, baseLon: -87.9083,
                        recipLat: 42.1117, recipLon: -87.8967)
                ],
                frequencies: [
                    freq(.tower, 120.750, "Chicago Exec Tower"),
                    freq(.ground, 121.600, "Chicago Exec Ground"),
                    freq(.atis, 128.100, "Chicago Exec ATIS")
                ]
            ),

            Airport(
                icao: "KDTW", faaID: "DTW", name: "Detroit Metro Wayne County",
                latitude: 42.2124, longitude: -83.3534, elevation: 645,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZOB", fssID: nil, magneticVariation: -6.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("04L/22R", length: 10001, width: 200, surface: .concrete,
                        baseEnd: "04L", recipEnd: "22R",
                        baseLat: 42.2017, baseLon: -83.3633,
                        recipLat: 42.2250, recipLon: -83.3450),
                    rwy("04R/22L", length: 12003, width: 200, surface: .concrete,
                        baseEnd: "04R", recipEnd: "22L",
                        baseLat: 42.2050, baseLon: -83.3700,
                        recipLat: 42.2317, recipLon: -83.3483),
                    rwy("03L/21R", length: 8501, width: 150, surface: .concrete,
                        baseEnd: "03L", recipEnd: "21R",
                        baseLat: 42.2033, baseLon: -83.3517,
                        recipLat: 42.2233, recipLon: -83.3383),
                    rwy("03R/21L", length: 8501, width: 150, surface: .concrete,
                        baseEnd: "03R", recipEnd: "21L",
                        baseLat: 42.2067, baseLon: -83.3583,
                        recipLat: 42.2267, recipLon: -83.3450)
                ],
                frequencies: [
                    freq(.tower, 119.450, "Detroit Tower"),
                    freq(.ground, 121.800, "Detroit Ground"),
                    freq(.atis, 135.000, "Detroit ATIS"),
                    freq(.approach, 118.400, "Detroit Approach")
                ]
            ),

            Airport(
                icao: "KARB", faaID: "ARB", name: "Ann Arbor Muni",
                latitude: 42.2230, longitude: -83.7455, elevation: 839,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: 120.300, unicomFrequency: nil,
                artccID: "ZOB", fssID: nil, magneticVariation: -6.0,
                patternAltitude: 1700, fuelTypes: ["100LL"],
                hasBeaconLight: true,
                runways: [
                    rwy("06/24", length: 3505, width: 75, surface: .asphalt,
                        baseEnd: "06", recipEnd: "24",
                        baseLat: 42.2217, baseLon: -83.7517,
                        recipLat: 42.2250, recipLon: -83.7400)
                ],
                frequencies: [
                    freq(.ctaf, 120.300, "Ann Arbor Traffic"),
                    freq(.awos, 124.250, "Ann Arbor AWOS")
                ]
            ),

            Airport(
                icao: "KMSP", faaID: "MSP", name: "Minneapolis-St Paul Intl",
                latitude: 44.8820, longitude: -93.2218, elevation: 841,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZMP", fssID: nil, magneticVariation: 0.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("12L/30R", length: 10000, width: 200, surface: .concrete,
                        baseEnd: "12L", recipEnd: "30R",
                        baseLat: 44.8900, baseLon: -93.2383,
                        recipLat: 44.8717, recipLon: -93.2050),
                    rwy("12R/30L", length: 8200, width: 150, surface: .concrete,
                        baseEnd: "12R", recipEnd: "30L",
                        baseLat: 44.8867, baseLon: -93.2350,
                        recipLat: 44.8717, recipLon: -93.2067),
                    rwy("04/22", length: 11006, width: 150, surface: .concrete,
                        baseEnd: "04", recipEnd: "22",
                        baseLat: 44.8717, baseLon: -93.2283,
                        recipLat: 44.8967, recipLon: -93.2117),
                    rwy("17/35", length: 8000, width: 150, surface: .concrete,
                        baseEnd: "17", recipEnd: "35",
                        baseLat: 44.8933, baseLon: -93.2167,
                        recipLat: 44.8717, recipLon: -93.2117)
                ],
                frequencies: [
                    freq(.tower, 126.700, "Minneapolis Tower"),
                    freq(.ground, 121.900, "Minneapolis Ground"),
                    freq(.atis, 135.350, "Minneapolis ATIS"),
                    freq(.approach, 119.300, "Minneapolis Approach")
                ]
            ),

            Airport(
                icao: "KFCM", faaID: "FCM", name: "Flying Cloud",
                latitude: 44.8272, longitude: -93.4571, elevation: 906,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZMP", fssID: nil, magneticVariation: 0.0,
                patternAltitude: 1700, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("10L/28R", length: 3900, width: 75, surface: .asphalt,
                        baseEnd: "10L", recipEnd: "28R",
                        baseLat: 44.8283, baseLon: -93.4650,
                        recipLat: 44.8267, recipLon: -93.4517),
                    rwy("10R/28L", length: 5000, width: 100, surface: .asphalt,
                        baseEnd: "10R", recipEnd: "28L",
                        baseLat: 44.8250, baseLon: -93.4667,
                        recipLat: 44.8233, recipLon: -93.4483),
                    rwy("18/36", length: 2691, width: 50, surface: .turf,
                        lighting: .none,
                        baseEnd: "18", recipEnd: "36",
                        baseLat: 44.8317, baseLon: -93.4550,
                        recipLat: 44.8250, recipLon: -93.4550)
                ],
                frequencies: [
                    freq(.tower, 120.700, "Flying Cloud Tower"),
                    freq(.ground, 121.600, "Flying Cloud Ground"),
                    freq(.atis, 127.575, "Flying Cloud ATIS")
                ]
            ),

            Airport(
                icao: "KMKE", faaID: "MKE", name: "Milwaukee Mitchell Intl",
                latitude: 42.9472, longitude: -87.8966, elevation: 723,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZAU", fssID: nil, magneticVariation: -3.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("01L/19R", length: 9690, width: 200, surface: .concrete,
                        baseEnd: "01L", recipEnd: "19R",
                        baseLat: 42.9350, baseLon: -87.8983,
                        recipLat: 42.9600, recipLon: -87.8933),
                    rwy("01R/19L", length: 6996, width: 150, surface: .asphalt,
                        baseEnd: "01R", recipEnd: "19L",
                        baseLat: 42.9383, baseLon: -87.9050,
                        recipLat: 42.9567, recipLon: -87.9017),
                    rwy("07L/25R", length: 9948, width: 150, surface: .concrete,
                        baseEnd: "07L", recipEnd: "25R",
                        baseLat: 42.9517, baseLon: -87.9133,
                        recipLat: 42.9433, recipLon: -87.8783),
                    rwy("07R/25L", length: 4183, width: 100, surface: .asphalt,
                        baseEnd: "07R", recipEnd: "25L",
                        baseLat: 42.9500, baseLon: -87.9083,
                        recipLat: 42.9467, recipLon: -87.8933)
                ],
                frequencies: [
                    freq(.tower, 119.100, "Milwaukee Tower"),
                    freq(.ground, 121.700, "Milwaukee Ground"),
                    freq(.atis, 127.800, "Milwaukee ATIS"),
                    freq(.approach, 124.350, "Milwaukee Approach")
                ]
            ),

            Airport(
                icao: "KOSH", faaID: "OSH", name: "Wittman Regional",
                latitude: 43.9844, longitude: -88.5570, elevation: 808,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZAU", fssID: nil, magneticVariation: -3.0,
                patternAltitude: 1600, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("09/27", length: 8002, width: 150, surface: .asphalt,
                        baseEnd: "09", recipEnd: "27",
                        baseLat: 43.9850, baseLon: -88.5717,
                        recipLat: 43.9833, recipLon: -88.5433),
                    rwy("18/36", length: 6179, width: 150, surface: .asphalt,
                        baseEnd: "18", recipEnd: "36",
                        baseLat: 43.9933, baseLon: -88.5567,
                        recipLat: 43.9767, recipLon: -88.5567)
                ],
                frequencies: [
                    freq(.tower, 118.500, "Oshkosh Tower"),
                    freq(.ground, 121.900, "Oshkosh Ground"),
                    freq(.atis, 124.400, "Oshkosh ATIS")
                ]
            ),

            Airport(
                icao: "KMCI", faaID: "MCI", name: "Kansas City Intl",
                latitude: 39.2976, longitude: -94.7139, elevation: 1026,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZKC", fssID: nil, magneticVariation: -2.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("01L/19R", length: 10801, width: 150, surface: .concrete,
                        baseEnd: "01L", recipEnd: "19R",
                        baseLat: 39.2833, baseLon: -94.7217,
                        recipLat: 39.3117, recipLon: -94.7133),
                    rwy("01R/19L", length: 9500, width: 150, surface: .concrete,
                        baseEnd: "01R", recipEnd: "19L",
                        baseLat: 39.2850, baseLon: -94.7100,
                        recipLat: 39.3100, recipLon: -94.7017),
                    rwy("09/27", length: 9500, width: 150, surface: .concrete,
                        baseEnd: "09", recipEnd: "27",
                        baseLat: 39.3000, baseLon: -94.7283,
                        recipLat: 39.2950, recipLon: -94.6967)
                ],
                frequencies: [
                    freq(.tower, 128.350, "Kansas City Tower"),
                    freq(.ground, 121.650, "Kansas City Ground"),
                    freq(.atis, 128.375, "Kansas City ATIS"),
                    freq(.approach, 123.900, "Kansas City Approach")
                ]
            ),

            Airport(
                icao: "KSTL", faaID: "STL", name: "St Louis Lambert Intl",
                latitude: 38.7487, longitude: -90.3700, elevation: 618,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZKC", fssID: nil, magneticVariation: -2.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("12L/30R", length: 11019, width: 200, surface: .concrete,
                        baseEnd: "12L", recipEnd: "30R",
                        baseLat: 38.7567, baseLon: -90.3883,
                        recipLat: 38.7400, recipLon: -90.3517),
                    rwy("12R/30L", length: 9003, width: 150, surface: .concrete,
                        baseEnd: "12R", recipEnd: "30L",
                        baseLat: 38.7533, baseLon: -90.3833,
                        recipLat: 38.7400, recipLon: -90.3550),
                    rwy("06/24", length: 7602, width: 150, surface: .concrete,
                        baseEnd: "06", recipEnd: "24",
                        baseLat: 38.7467, baseLon: -90.3800,
                        recipLat: 38.7500, recipLon: -90.3533)
                ],
                frequencies: [
                    freq(.tower, 120.400, "St Louis Tower"),
                    freq(.ground, 121.900, "St Louis Ground"),
                    freq(.atis, 125.775, "St Louis ATIS"),
                    freq(.approach, 124.700, "St Louis Approach")
                ]
            ),

            Airport(
                icao: "KIND", faaID: "IND", name: "Indianapolis Intl",
                latitude: 39.7173, longitude: -86.2944, elevation: 797,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZID", fssID: nil, magneticVariation: -5.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("05L/23R", length: 11200, width: 150, surface: .concrete,
                        baseEnd: "05L", recipEnd: "23R",
                        baseLat: 39.7050, baseLon: -86.3117,
                        recipLat: 39.7300, recipLon: -86.2800),
                    rwy("05R/23L", length: 10005, width: 150, surface: .concrete,
                        baseEnd: "05R", recipEnd: "23L",
                        baseLat: 39.7083, baseLon: -86.3150,
                        recipLat: 39.7300, recipLon: -86.2883)
                ],
                frequencies: [
                    freq(.tower, 119.300, "Indianapolis Tower"),
                    freq(.ground, 121.700, "Indianapolis Ground"),
                    freq(.atis, 127.250, "Indianapolis ATIS"),
                    freq(.approach, 119.300, "Indianapolis Approach")
                ]
            ),

            Airport(
                icao: "KEYE", faaID: "EYE", name: "Eagle Creek Airpark",
                latitude: 39.8308, longitude: -86.2942, elevation: 823,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZID", fssID: nil, magneticVariation: -5.0,
                patternAltitude: 1600, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("03/21", length: 4200, width: 75, surface: .asphalt,
                        baseEnd: "03", recipEnd: "21",
                        baseLat: 39.8267, baseLon: -86.2967,
                        recipLat: 39.8350, recipLon: -86.2917)
                ],
                frequencies: [
                    freq(.tower, 119.350, "Eagle Creek Tower"),
                    freq(.ground, 121.600, "Eagle Creek Ground"),
                    freq(.atis, 135.200, "Eagle Creek ATIS")
                ]
            ),

            Airport(
                icao: "KCLE", faaID: "CLE", name: "Cleveland Hopkins Intl",
                latitude: 41.4117, longitude: -81.8498, elevation: 791,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZOB", fssID: nil, magneticVariation: -7.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("06L/24R", length: 8999, width: 150, surface: .asphalt,
                        baseEnd: "06L", recipEnd: "24R",
                        baseLat: 41.4083, baseLon: -81.8667,
                        recipLat: 41.4167, recipLon: -81.8350),
                    rwy("06R/24L", length: 6017, width: 150, surface: .asphalt,
                        baseEnd: "06R", recipEnd: "24L",
                        baseLat: 41.4050, baseLon: -81.8617,
                        recipLat: 41.4117, recipLon: -81.8400),
                    rwy("10/28", length: 6014, width: 150, surface: .asphalt,
                        baseEnd: "10", recipEnd: "28",
                        baseLat: 41.4150, baseLon: -81.8617,
                        recipLat: 41.4100, recipLon: -81.8400)
                ],
                frequencies: [
                    freq(.tower, 124.500, "Cleveland Tower"),
                    freq(.ground, 121.700, "Cleveland Ground"),
                    freq(.atis, 127.850, "Cleveland ATIS"),
                    freq(.approach, 124.000, "Cleveland Approach")
                ]
            ),

            Airport(
                icao: "KCMH", faaID: "CMH", name: "John Glenn Columbus Intl",
                latitude: 39.9980, longitude: -82.8919, elevation: 815,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZOB", fssID: nil, magneticVariation: -6.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("10L/28R", length: 10113, width: 150, surface: .asphalt,
                        baseEnd: "10L", recipEnd: "28R",
                        baseLat: 40.0017, baseLon: -82.9133,
                        recipLat: 39.9933, recipLon: -82.8767),
                    rwy("10R/28L", length: 8000, width: 150, surface: .asphalt,
                        baseEnd: "10R", recipEnd: "28L",
                        baseLat: 39.9983, baseLon: -82.9083,
                        recipLat: 39.9917, recipLon: -82.8800)
                ],
                frequencies: [
                    freq(.tower, 118.300, "Columbus Tower"),
                    freq(.ground, 121.900, "Columbus Ground"),
                    freq(.atis, 134.050, "Columbus ATIS"),
                    freq(.approach, 118.500, "Columbus Approach")
                ]
            ),

            Airport(
                icao: "KOSU", faaID: "OSU", name: "Ohio State University",
                latitude: 40.0798, longitude: -83.0730, elevation: 905,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZOB", fssID: nil, magneticVariation: -6.0,
                patternAltitude: 1700, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("09L/27R", length: 5004, width: 100, surface: .asphalt,
                        baseEnd: "09L", recipEnd: "27R",
                        baseLat: 40.0800, baseLon: -83.0833,
                        recipLat: 40.0800, recipLon: -83.0633),
                    rwy("09R/27L", length: 2992, width: 100, surface: .asphalt,
                        baseEnd: "09R", recipEnd: "27L",
                        baseLat: 40.0783, baseLon: -83.0800,
                        recipLat: 40.0783, recipLon: -83.0667)
                ],
                frequencies: [
                    freq(.tower, 121.300, "OSU Tower"),
                    freq(.ground, 121.600, "OSU Ground"),
                    freq(.atis, 128.600, "OSU ATIS")
                ]
            ),
        ]
    }
}
