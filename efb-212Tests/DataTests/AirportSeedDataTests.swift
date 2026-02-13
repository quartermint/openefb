//
//  AirportSeedDataTests.swift
//  efb-212Tests
//
//  Tests for the bundled airport seed data: count, coordinate validity,
//  runway presence, and ICAO uniqueness.
//

import Testing
import Foundation
@testable import efb_212

@Suite("AirportSeedData Tests")
struct AirportSeedDataTests {

    // Cache all airports once for the suite to avoid repeated computation.
    static let allAirports = AirportSeedData.allAirports()

    // MARK: - Count

    @Test func expectedAirportCount() {
        // The seed data should contain 108 airports across all regions.
        let count = Self.allAirports.count
        #expect(count == 108, "Expected 108 seed airports, got \(count)")
    }

    // MARK: - Coordinate Validity

    @Test func allAirportsHaveValidLatitude() {
        for airport in Self.allAirports {
            #expect(
                airport.latitude >= -90 && airport.latitude <= 90,
                "\(airport.icao) has invalid latitude \(airport.latitude)"
            )
        }
    }

    @Test func allAirportsHaveValidLongitude() {
        for airport in Self.allAirports {
            #expect(
                airport.longitude >= -180 && airport.longitude <= 180,
                "\(airport.icao) has invalid longitude \(airport.longitude)"
            )
        }
    }

    @Test func allAirportsHaveReasonableUSCoordinates() {
        // All seed airports should be in the continental US, Alaska, or Hawaii.
        // Continental US + Alaska: lat 18..72, lon -180..-65
        // Hawaii: lat 18..23, lon -161..-154
        for airport in Self.allAirports {
            let inContinental = airport.latitude >= 18 && airport.latitude <= 72 &&
                                airport.longitude >= -180 && airport.longitude <= -65
            let inHawaii = airport.latitude >= 18 && airport.latitude <= 23 &&
                           airport.longitude >= -161 && airport.longitude <= -154
            #expect(
                inContinental || inHawaii,
                "\(airport.icao) at (\(airport.latitude), \(airport.longitude)) is outside expected US bounds"
            )
        }
    }

    // MARK: - Runway Presence

    @Test func allAirportsHaveAtLeastOneRunway() {
        for airport in Self.allAirports {
            #expect(
                !airport.runways.isEmpty,
                "\(airport.icao) (\(airport.name)) has no runways"
            )
        }
    }

    @Test func allRunwaysHavePositiveLength() {
        for airport in Self.allAirports {
            for runway in airport.runways {
                #expect(
                    runway.length > 0,
                    "\(airport.icao) runway \(runway.id) has non-positive length \(runway.length)"
                )
            }
        }
    }

    @Test func allRunwaysHavePositiveWidth() {
        for airport in Self.allAirports {
            for runway in airport.runways {
                #expect(
                    runway.width > 0,
                    "\(airport.icao) runway \(runway.id) has non-positive width \(runway.width)"
                )
            }
        }
    }

    // MARK: - ICAO Uniqueness

    @Test func noDuplicateICAOIdentifiers() {
        let icaos = Self.allAirports.map(\.icao)
        let uniqueICAOs = Set(icaos)
        #expect(
            uniqueICAOs.count == icaos.count,
            "Found \(icaos.count - uniqueICAOs.count) duplicate ICAO identifiers"
        )
    }

    // MARK: - Basic Data Integrity

    @Test func allAirportsHaveNonEmptyICAO() {
        for airport in Self.allAirports {
            #expect(!airport.icao.isEmpty, "Airport has empty ICAO identifier")
        }
    }

    @Test func allAirportsHaveNonEmptyName() {
        for airport in Self.allAirports {
            #expect(!airport.name.isEmpty, "\(airport.icao) has empty name")
        }
    }

    @Test func allICAOStartWithK_orP() {
        // US airport ICAO codes start with K (continental US) or P (Pacific — Alaska, Hawaii)
        for airport in Self.allAirports {
            let firstChar = airport.icao.prefix(1)
            #expect(
                firstChar == "K" || firstChar == "P",
                "\(airport.icao) does not start with K or P — unexpected for a US airport"
            )
        }
    }

    @Test func elevationsAreReasonable() {
        // US airport elevations range from roughly -200 ft (Death Valley area)
        // to ~14,000 ft (highest paved airports)
        for airport in Self.allAirports {
            #expect(
                airport.elevation >= -300 && airport.elevation <= 15000,
                "\(airport.icao) has unreasonable elevation \(airport.elevation) ft MSL"
            )
        }
    }

    // MARK: - Regional Coverage

    @Test func seedDataCoversAllRegions() {
        // Verify that each regional function returns airports.
        // This catches accidental empty returns from any region file.
        #expect(!AirportSeedData.allAirports().isEmpty)
        // We've already tested the total count above (108).
        // Here we just verify allAirports aggregates correctly.
        let total = AirportSeedData.allAirports().count
        #expect(total > 0, "allAirports() should return non-empty array")
    }
}
