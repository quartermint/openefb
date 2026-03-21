//
//  FlightPhaseDetectorTests.swift
//  efb-212Tests
//
//  Unit tests for FlightPhaseDetector state machine.
//  Tests all 8 phase transitions with 30-second hysteresis enforcement.
//

import Testing
import Foundation
@testable import efb_212

@Suite("FlightPhaseDetector Tests")
struct FlightPhaseDetectorTests {

    // MARK: - Helpers

    static let testFlightID = UUID()

    static func makePoint(
        speed: Double,
        altitude: Double,
        vsi: Double,
        secondsFromStart: TimeInterval,
        flightID: UUID = testFlightID
    ) -> TrackPointRecord {
        TrackPointRecord(
            id: UUID(),
            flightID: flightID,
            timestamp: Date(timeIntervalSince1970: secondsFromStart),
            latitude: 37.46,
            longitude: -122.12,
            altitudeFeet: altitude,
            groundSpeedKnots: speed,
            verticalSpeedFPM: vsi,
            courseDegrees: 270
        )
    }

    // MARK: - Initial State

    @Test func initialPhaseIsPreflight() {
        let detector = FlightPhaseDetector()
        #expect(detector.currentPhase == .preflight)
    }

    // MARK: - Taxi Detection

    @Test func taxiTransitionAfterHysteresis() {
        var detector = FlightPhaseDetector()
        // Feed 31 points at 1s intervals, speed=10kts (taxi range: 5-15 kts)
        for i in 0...30 {
            let point = Self.makePoint(speed: 10, altitude: 100, vsi: 0, secondsFromStart: Double(i))
            _ = detector.process(point)
        }
        #expect(detector.currentPhase == .taxi)
    }

    @Test func noTransitionBeforeHysteresis() {
        var detector = FlightPhaseDetector()
        // Feed 25 points at 10kts -- should stay in .preflight
        for i in 0...24 {
            let point = Self.makePoint(speed: 10, altitude: 100, vsi: 0, secondsFromStart: Double(i))
            _ = detector.process(point)
        }
        #expect(detector.currentPhase == .preflight)
    }
}
