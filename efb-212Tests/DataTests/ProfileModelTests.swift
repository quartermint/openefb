//
//  ProfileModelTests.swift
//  efb-212Tests
//
//  Unit tests for AircraftProfile, PilotProfile, and FlightPlanRecord SwiftData models.
//  Tests computed property round-trips, validation, and FlightPlan conversion.
//

import Testing
import Foundation
@testable import efb_212

@Suite("Profile Model Tests")
struct ProfileModelTests {

    // MARK: - AircraftProfile Tests

    @Test func aircraftProfileCreation() {
        let profile = SchemaV1.AircraftProfile(nNumber: "N4543A")
        #expect(profile.nNumber == "N4543A")
        #expect(profile.isActive == false)
        #expect(profile.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }

    @Test func aircraftVSpeedsRoundTrip() {
        let profile = SchemaV1.AircraftProfile(nNumber: "N4543A")
        let speeds = VSpeeds(vr: 55, vy: 76)
        profile.vSpeeds = speeds

        let readBack = profile.vSpeeds
        #expect(readBack != nil)
        #expect(readBack?.vr == 55)
        #expect(readBack?.vy == 76)
        #expect(readBack?.vx == nil)  // not set
    }

    @Test func aircraftIsValidWithNNumber() {
        let profile = SchemaV1.AircraftProfile(nNumber: "N123AB")
        #expect(profile.isValid == true)
    }

    @Test func aircraftIsInvalidWithEmptyNNumber() {
        let profile = SchemaV1.AircraftProfile(nNumber: "")
        #expect(profile.isValid == false)
    }

    // MARK: - PilotProfile Tests

    @Test func pilotProfileCreation() {
        let profile = SchemaV1.PilotProfile()
        profile.name = "Test Pilot"
        #expect(profile.name == "Test Pilot")
    }

    @Test func pilotNightLandingsRoundTrip() {
        let profile = SchemaV1.PilotProfile()
        let entry = SchemaV1.NightLandingEntry(date: Date(), count: 3)
        profile.nightLandingEntries = [entry]

        let readBack = profile.nightLandingEntries
        #expect(readBack.count == 1)
        #expect(readBack.first?.count == 3)
    }

    @Test func pilotMedicalClassEnumRoundTrip() {
        let profile = SchemaV1.PilotProfile()
        profile.medicalClassEnum = .first
        #expect(profile.medicalClassEnum == .first)
        #expect(profile.medicalClass == "first")
    }

    @Test func pilotCertificateTypeEnumRoundTrip() {
        let profile = SchemaV1.PilotProfile()
        profile.certificateTypeEnum = .privatePilot
        #expect(profile.certificateTypeEnum == .privatePilot)
        #expect(profile.certificateType == "private")
    }

    // MARK: - FlightPlanRecord Tests

    @Test func flightPlanRecordToFlightPlan() {
        let record = SchemaV1.FlightPlanRecord()
        record.departureICAO = "KPAO"
        record.departureName = "Palo Alto"
        record.departureLatitude = 37.4613
        record.departureLongitude = -122.1150
        record.destinationICAO = "KSQL"
        record.destinationName = "San Carlos"
        record.destinationLatitude = 37.5119
        record.destinationLongitude = -122.2494
        record.totalDistanceNM = 5.3
        record.cruiseAltitude = 2500  // feet MSL
        record.cruiseSpeedKts = 110  // knots TAS

        let plan = record.toFlightPlan()
        #expect(plan.departure == "KPAO")
        #expect(plan.destination == "KSQL")
        #expect(plan.totalDistance == 5.3)
        #expect(plan.cruiseAltitude == 2500)
        #expect(plan.cruiseSpeed == 110)
        #expect(plan.waypoints.count == 2)
        #expect(plan.waypoints.first?.identifier == "KPAO")
        #expect(plan.waypoints.last?.identifier == "KSQL")
    }
}
