//
//  SouthwestAirports.swift
//  efb-212
//
//  Arizona and New Mexico airports seed data.
//

import Foundation

extension AirportSeedData {

    nonisolated static func southwestAirports() -> [Airport] {
        [
            Airport(
                icao: "KPHX", faaID: "PHX", name: "Phoenix Sky Harbor Intl",
                latitude: 33.4373, longitude: -112.0078, elevation: 1135,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZAB", fssID: nil, magneticVariation: 11.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("07L/25R", length: 7800, width: 150, surface: .asphalt,
                        baseEnd: "07L", recipEnd: "25R",
                        baseLat: 33.4400, baseLon: -112.0233,
                        recipLat: 33.4350, recipLon: -111.9967),
                    rwy("07R/25L", length: 10300, width: 150, surface: .asphalt,
                        baseEnd: "07R", recipEnd: "25L",
                        baseLat: 33.4367, baseLon: -112.0250,
                        recipLat: 33.4317, recipLon: -111.9900),
                    rwy("08/26", length: 11489, width: 150, surface: .concrete,
                        baseEnd: "08", recipEnd: "26",
                        baseLat: 33.4333, baseLon: -112.0267,
                        recipLat: 33.4300, recipLon: -111.9850)
                ],
                frequencies: [
                    freq(.tower, 118.700, "Phoenix Tower"),
                    freq(.ground, 121.900, "Phoenix Ground"),
                    freq(.atis, 120.675, "Phoenix ATIS"),
                    freq(.approach, 119.200, "Phoenix Approach")
                ]
            ),

            Airport(
                icao: "KSDL", faaID: "SDL", name: "Scottsdale",
                latitude: 33.6229, longitude: -111.9105, elevation: 1510,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZAB", fssID: nil, magneticVariation: 11.0,
                patternAltitude: 2500, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("03/21", length: 8249, width: 100, surface: .asphalt,
                        baseEnd: "03", recipEnd: "21",
                        baseLat: 33.6150, baseLon: -111.9150,
                        recipLat: 33.6317, recipLon: -111.9067)
                ],
                frequencies: [
                    freq(.tower, 119.900, "Scottsdale Tower"),
                    freq(.ground, 121.900, "Scottsdale Ground"),
                    freq(.atis, 118.100, "Scottsdale ATIS")
                ]
            ),

            Airport(
                icao: "KDVT", faaID: "DVT", name: "Phoenix Deer Valley",
                latitude: 33.6883, longitude: -112.0833, elevation: 1478,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZAB", fssID: nil, magneticVariation: 11.0,
                patternAltitude: 2500, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("07L/25R", length: 4501, width: 75, surface: .asphalt,
                        baseEnd: "07L", recipEnd: "25R",
                        baseLat: 33.6900, baseLon: -112.0917,
                        recipLat: 33.6867, recipLon: -112.0750),
                    rwy("07R/25L", length: 8208, width: 100, surface: .asphalt,
                        baseEnd: "07R", recipEnd: "25L",
                        baseLat: 33.6867, baseLon: -112.0983,
                        recipLat: 33.6833, recipLon: -112.0700)
                ],
                frequencies: [
                    freq(.tower, 118.400, "Deer Valley Tower"),
                    freq(.ground, 121.700, "Deer Valley Ground"),
                    freq(.atis, 126.475, "Deer Valley ATIS")
                ]
            ),

            Airport(
                icao: "KTUS", faaID: "TUS", name: "Tucson Intl",
                latitude: 32.1161, longitude: -110.9410, elevation: 2643,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZAB", fssID: nil, magneticVariation: 11.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("11L/29R", length: 10996, width: 150, surface: .concrete,
                        baseEnd: "11L", recipEnd: "29R",
                        baseLat: 32.1200, baseLon: -110.9617,
                        recipLat: 32.1117, recipLon: -110.9233),
                    rwy("11R/29L", length: 7000, width: 150, surface: .asphalt,
                        baseEnd: "11R", recipEnd: "29L",
                        baseLat: 32.1133, baseLon: -110.9533,
                        recipLat: 32.1083, recipLon: -110.9283)
                ],
                frequencies: [
                    freq(.tower, 118.300, "Tucson Tower"),
                    freq(.ground, 121.700, "Tucson Ground"),
                    freq(.atis, 128.450, "Tucson ATIS"),
                    freq(.approach, 118.700, "Tucson Approach")
                ]
            ),

            Airport(
                icao: "KFLG", faaID: "FLG", name: "Flagstaff Pulliam",
                latitude: 35.1385, longitude: -111.6712, elevation: 7014,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZAB", fssID: nil, magneticVariation: 11.0,
                patternAltitude: 7800, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("03/21", length: 6999, width: 150, surface: .asphalt,
                        baseEnd: "03", recipEnd: "21",
                        baseLat: 35.1300, baseLon: -111.6767,
                        recipLat: 35.1467, recipLon: -111.6650)
                ],
                frequencies: [
                    freq(.ctaf, 119.200, "Flagstaff Traffic"),
                    freq(.awos, 118.375, "Flagstaff AWOS")
                ]
            ),

            Airport(
                icao: "KSED", faaID: "SED", name: "Sedona",
                latitude: 34.8486, longitude: -111.7885, elevation: 4830,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: 122.700, unicomFrequency: nil,
                artccID: "ZAB", fssID: nil, magneticVariation: 11.0,
                patternAltitude: 5830, fuelTypes: ["100LL"],
                hasBeaconLight: true,
                runways: [
                    rwy("03/21", length: 5132, width: 100, surface: .asphalt,
                        baseEnd: "03", recipEnd: "21",
                        baseLat: 34.8417, baseLon: -111.7917,
                        recipLat: 34.8550, recipLon: -111.7850)
                ],
                frequencies: [
                    freq(.ctaf, 122.700, "Sedona Traffic"),
                    freq(.awos, 128.025, "Sedona AWOS")
                ]
            ),

            Airport(
                icao: "KABQ", faaID: "ABQ", name: "Albuquerque Intl Sunport",
                latitude: 35.0402, longitude: -106.6093, elevation: 5355,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZAB", fssID: nil, magneticVariation: 9.0,
                patternAltitude: nil, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("08/26", length: 13793, width: 150, surface: .concrete,
                        baseEnd: "08", recipEnd: "26",
                        baseLat: 35.0400, baseLon: -106.6350,
                        recipLat: 35.0400, recipLon: -106.5833),
                    rwy("03/21", length: 10000, width: 150, surface: .asphalt,
                        baseEnd: "03", recipEnd: "21",
                        baseLat: 35.0300, baseLon: -106.6167,
                        recipLat: 35.0517, recipLon: -106.6050),
                    rwy("17/35", length: 6000, width: 100, surface: .asphalt,
                        baseEnd: "17", recipEnd: "35",
                        baseLat: 35.0483, baseLon: -106.6150,
                        recipLat: 35.0333, recipLon: -106.6117)
                ],
                frequencies: [
                    freq(.tower, 118.000, "Albuquerque Tower"),
                    freq(.ground, 121.900, "Albuquerque Ground"),
                    freq(.atis, 127.050, "Albuquerque ATIS"),
                    freq(.approach, 123.900, "Albuquerque Approach")
                ]
            ),

            Airport(
                icao: "KSAF", faaID: "SAF", name: "Santa Fe Muni",
                latitude: 35.6171, longitude: -106.0884, elevation: 6348,
                type: .airport, ownership: .publicOwned,
                ctafFrequency: nil, unicomFrequency: 122.950,
                artccID: "ZAB", fssID: nil, magneticVariation: 9.0,
                patternAltitude: 7300, fuelTypes: ["100LL", "Jet-A"],
                hasBeaconLight: true,
                runways: [
                    rwy("02/20", length: 6316, width: 75, surface: .asphalt,
                        baseEnd: "02", recipEnd: "20",
                        baseLat: 35.6100, baseLon: -106.0900,
                        recipLat: 35.6250, recipLon: -106.0867),
                    rwy("10/28", length: 8366, width: 150, surface: .asphalt,
                        baseEnd: "10", recipEnd: "28",
                        baseLat: 35.6183, baseLon: -106.1033,
                        recipLat: 35.6150, recipLon: -106.0733)
                ],
                frequencies: [
                    freq(.tower, 119.500, "Santa Fe Tower"),
                    freq(.ground, 121.900, "Santa Fe Ground"),
                    freq(.awos, 118.050, "Santa Fe AWOS")
                ]
            ),
        ]
    }
}
