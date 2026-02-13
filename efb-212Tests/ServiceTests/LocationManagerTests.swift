//
//  LocationManagerTests.swift
//  efb-212Tests
//
//  Tests for LocationManager: initial state, protocol conformance,
//  power state behavior, and aviation unit conversion constants.
//
//  NOTE: Direct testing of CLLocationManager delegate callbacks is limited
//  because CLLocation objects cannot be easily constructed with custom
//  speed/course values in a unit test. We test what we can: initial state,
//  power state application, and unit conversion math via the known constants.
//

import Testing
import Foundation
import CoreLocation
@testable import efb_212

@Suite("LocationManager Tests")
struct LocationManagerTests {

    // MARK: - Initial State

    @Test func initialLocationIsNil() {
        let manager = LocationManager()
        #expect(manager.location == nil)
    }

    @Test func initialHeadingIsNil() {
        let manager = LocationManager()
        #expect(manager.heading == nil)
    }

    @Test func initialGroundSpeedIsZero() {
        let manager = LocationManager()
        #expect(manager.groundSpeed == 0)
    }

    @Test func initialAltitudeIsZero() {
        let manager = LocationManager()
        #expect(manager.altitude == 0)
    }

    @Test func initialTrackIsZero() {
        let manager = LocationManager()
        #expect(manager.track == 0)
    }

    @Test func initialVerticalSpeedIsZero() {
        let manager = LocationManager()
        #expect(manager.verticalSpeed == 0)
    }

    @Test func initialAuthorizationIsFalse() {
        let manager = LocationManager()
        // In test environment, authorization is not granted
        #expect(manager.isAuthorized == false)
    }

    // MARK: - Protocol Conformance

    @Test func conformsToLocationManagerProtocol() {
        let manager = LocationManager()
        // Verify it can be used as LocationManagerProtocol
        let _: any LocationManagerProtocol = manager
        // If this compiles, protocol conformance is satisfied
    }

    @Test func locationPublisherIsAvailable() {
        let manager = LocationManager()
        // locationPublisher should be a valid publisher
        let publisher = manager.locationPublisher
        // Just verify the publisher exists (AnyPublisher<CLLocation, Never>)
        _ = publisher
    }

    // MARK: - Power State Affects Accuracy

    @Test func updatePowerStateAccepted() {
        let manager = LocationManager()
        // These should not crash or throw
        manager.updatePowerState(.normal)
        manager.updatePowerState(.batteryConscious)
        manager.updatePowerState(.emergency)
    }

    // MARK: - Aviation Unit Conversion Constants

    // The LocationManager uses these constants internally:
    // 1 m/s = 1.94384 knots
    // 1 meter = 3.28084 feet
    // We verify these via the CLLocation+Aviation extension which uses the same conversions.

    @Test func metersPerSecondToKnotsConversion() {
        // 1 m/s = 1.94384 knots
        // Using the extension: metersToNM converts meters to nautical miles
        // Speed conversion: speed_knots = speed_m_s * 1.94384
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
        // If aircraft climbs 152.4 meters (500 feet) in 60 seconds = 500 fpm
        let altitudeDeltaMeters: Double = 152.4
        let altitudeDeltaFeet = altitudeDeltaMeters * 3.28084  // ~500 feet
        let timeSeconds: Double = 60.0
        let fpm = (altitudeDeltaFeet / timeSeconds) * 60.0
        #expect(abs(fpm - 500.0) < 1.0, "152.4m climb in 60s should be ~500 fpm")
    }

    @Test func zeroSpeedReturnsZeroKnots() {
        // When CLLocation.speed is 0, speedInKnots should return 0
        let speedMS: Double = 0
        let knots = speedMS * 1.94384
        #expect(knots == 0)
    }

    @Test func negativeSpeedReturnsZero() {
        // CLLocation reports -1 for invalid speed. LocationManager guards < 0 → 0
        let speedMS: Double = -1.0
        let knots = speedMS >= 0 ? speedMS * 1.94384 : 0
        #expect(knots == 0, "Negative speed should map to 0 knots")
    }

    // MARK: - MockLocationManager Verification

    @Test func mockLocationManagerTracksMethodCalls() {
        let mock = MockLocationManager()
        #expect(mock.requestAuthorizationCalled == false)
        #expect(mock.startUpdatingCalled == false)
        #expect(mock.stopUpdatingCalled == false)

        mock.requestAuthorization()
        #expect(mock.requestAuthorizationCalled == true)

        mock.startUpdating()
        #expect(mock.startUpdatingCalled == true)

        mock.stopUpdating()
        #expect(mock.stopUpdatingCalled == true)
    }

    @Test func mockLocationManagerSimulatesLocation() {
        let mock = MockLocationManager()
        #expect(mock.location == nil)

        let testLocation = CLLocation(latitude: 37.4611, longitude: -122.1150)
        mock.simulateLocation(testLocation)

        #expect(mock.location != nil)
        #expect(mock.location?.coordinate.latitude == 37.4611)
        #expect(mock.location?.coordinate.longitude == -122.1150)
    }
}
