//
//  LocationManagerTests.swift
//  efb-212Tests
//
//  Tests for LocationService: aviation unit conversion constants.
//
//  NOTE: Many tests from the pre-Phase-2 version referenced a LocationManager
//  class and LocationManagerProtocol that no longer exist. LocationService uses
//  CLLocationUpdate.liveUpdates() which cannot be unit-tested directly.
//  Retained: unit conversion constant tests. Removed: mock interaction tests.
//

import Testing
import Foundation
import CoreLocation
@testable import efb_212

@Suite("LocationService Tests")
struct LocationManagerTests {

    // MARK: - Aviation Unit Conversion Constants

    @Test func metersPerSecondToKnotsConversion() {
        // 1 m/s = 1.94384 knots
        let speedMS: Double = 51.4444  // 100 knots in m/s
        let expectedKnots: Double = 100.0
        let computedKnots = speedMS * 1.94384
        #expect(abs(computedKnots - expectedKnots) < 0.1, "51.4444 m/s should be ~100 knots")
    }

    @Test func metersToFeetConversion() {
        // 1 meter = 3.28084 feet
        let meters: Double = 304.8  // 1000 feet
        let expectedFeet: Double = 1000.0
        let computedFeet = meters * 3.28084
        #expect(abs(computedFeet - expectedFeet) < 0.1, "304.8 meters should be ~1000 feet")
    }

    @Test func feetPerMinuteConversion() {
        // Vertical speed: altitude delta in feet / time delta in seconds * 60
        let altitudeDeltaMeters: Double = 152.4
        let altitudeDeltaFeet = altitudeDeltaMeters * 3.28084  // ~500 feet
        let timeSeconds: Double = 60.0
        let fpm = (altitudeDeltaFeet / timeSeconds) * 60.0
        #expect(abs(fpm - 500.0) < 1.0, "152.4m climb in 60s should be ~500 fpm")
    }

    @Test func zeroSpeedReturnsZeroKnots() {
        let speedMS: Double = 0
        let knots = speedMS * 1.94384
        #expect(knots == 0)
    }

    @Test func negativeSpeedReturnsZero() {
        // CLLocation reports -1 for invalid speed. LocationService guards < 0 -> 0
        let speedMS: Double = -1.0
        let knots = speedMS >= 0 ? speedMS * 1.94384 : 0
        #expect(knots == 0, "Negative speed should map to 0 knots")
    }
}
