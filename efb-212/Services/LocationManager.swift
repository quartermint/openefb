//
//  LocationManager.swift
//  efb-212
//
//  CLLocationManager wrapper with aviation unit conversions.
//  Publishes position, groundSpeed (knots), altitude (feet MSL),
//  track (degrees true), and verticalSpeed (fpm) via Combine.
//
//  Supports adaptive GPS sampling rates based on PowerState.
//  All types are @MainActor by default (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor).
//

import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, LocationManagerProtocol, ObservableObject {

    // MARK: - LocationManagerProtocol Properties

    @Published private(set) var location: CLLocation?
    @Published private(set) var heading: CLHeading?

    var locationPublisher: AnyPublisher<CLLocation, Never> {
        locationSubject.eraseToAnyPublisher()
    }

    // MARK: - Aviation-Unit Properties

    /// Ground speed in knots, converted from CLLocation's m/s.
    @Published private(set) var groundSpeed: Double = 0       // knots

    /// GPS altitude in feet MSL, converted from CLLocation's meters.
    @Published private(set) var altitude: Double = 0           // feet MSL

    /// Track over ground in degrees true.
    @Published private(set) var track: Double = 0              // degrees true

    /// Vertical speed in feet per minute, computed from successive altitude samples.
    @Published private(set) var verticalSpeed: Double = 0      // fpm

    /// Whether location authorization has been granted.
    @Published private(set) var isAuthorized: Bool = false

    // MARK: - Private Properties

    private let clManager = CLLocationManager()
    private let locationSubject = PassthroughSubject<CLLocation, Never>()

    /// Previous location for vertical speed computation.
    private var previousLocation: CLLocation?

    /// Current power state — drives adaptive sampling interval.
    private var powerState: PowerState = .normal

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Unit Conversion Constants

    /// 1 m/s = 1.94384 knots
    private static let metersPerSecondToKnots: Double = 1.94384

    /// 1 meter = 3.28084 feet
    private static let metersToFeet: Double = 3.28084

    // MARK: - Init

    override init() {
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        clManager.activityType = .otherNavigation  // aviation — high accuracy, no road snapping
        // Background location requires UIBackgroundModes "location" in Info.plist.
        // Only enable if the capability is configured to avoid assertion crash.
        let bgModes = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String] ?? []
        if bgModes.contains("location") {
            clManager.allowsBackgroundLocationUpdates = true
            clManager.showsBackgroundLocationIndicator = true
        }
        clManager.pausesLocationUpdatesAutomatically = false
        applyPowerState(.normal)
    }

    // MARK: - LocationManagerProtocol Methods

    func requestAuthorization() {
        clManager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        clManager.startUpdatingLocation()
        clManager.startUpdatingHeading()
    }

    func stopUpdating() {
        clManager.stopUpdatingLocation()
        clManager.stopUpdatingHeading()
        previousLocation = nil
    }

    // MARK: - Adaptive Sampling

    /// Update GPS sampling rate based on power state.
    /// Normal: best accuracy (~1 Hz), batteryConscious: 10m filter (~0.33 Hz),
    /// emergency: 50m filter (~0.2 Hz).
    func updatePowerState(_ state: PowerState) {
        powerState = state
        applyPowerState(state)
    }

    private func applyPowerState(_ state: PowerState) {
        switch state {
        case .normal:
            clManager.desiredAccuracy = kCLLocationAccuracyBest
            clManager.distanceFilter = kCLDistanceFilterNone
        case .batteryConscious:
            clManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            clManager.distanceFilter = 10  // meters — reduces update frequency
        case .emergency:
            clManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            clManager.distanceFilter = 50  // meters — minimum viable updates
        }
    }

    // MARK: - Aviation Unit Conversions

    /// Convert CLLocation speed (m/s) to knots. Returns 0 if speed is invalid.
    private func speedInKnots(_ metersPerSecond: Double) -> Double {
        guard metersPerSecond >= 0 else { return 0 }
        return metersPerSecond * Self.metersPerSecondToKnots
    }

    /// Convert CLLocation altitude (meters) to feet.
    private func altitudeInFeet(_ meters: Double) -> Double {
        meters * Self.metersToFeet
    }

    /// Compute vertical speed in feet per minute from two successive locations.
    private func computeVerticalSpeed(from previous: CLLocation, to current: CLLocation) -> Double {
        let timeDelta = current.timestamp.timeIntervalSince(previous.timestamp)
        guard timeDelta > 0.1 else { return verticalSpeed }  // avoid division by near-zero

        let altitudeDelta = current.altitude - previous.altitude  // meters
        let altitudeDeltaFeet = altitudeDelta * Self.metersToFeet
        return (altitudeDeltaFeet / timeDelta) * 60.0  // feet per minute
    }

    /// Process a new CLLocation: convert to aviation units and publish.
    private func processLocation(_ newLocation: CLLocation) {
        location = newLocation
        groundSpeed = speedInKnots(newLocation.speed)
        altitude = altitudeInFeet(newLocation.altitude)

        // Track: CLLocation.course is degrees true (0-360), -1 if invalid
        if newLocation.course >= 0 {
            track = newLocation.course
        }

        // Vertical speed from successive samples
        if let prev = previousLocation {
            verticalSpeed = computeVerticalSpeed(from: prev, to: newLocation)
        }

        previousLocation = newLocation
        locationSubject.send(newLocation)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        MainActor.assumeIsolated {
            processLocation(latest)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        MainActor.assumeIsolated {
            heading = newHeading
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        MainActor.assumeIsolated {
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                isAuthorized = true
            default:
                isAuthorized = false
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Log but don't crash — GPS failures are transient in flight
        print("[LocationManager] Location error: \(error.localizedDescription)")
    }
}
