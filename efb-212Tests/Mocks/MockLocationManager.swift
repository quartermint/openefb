//
//  MockLocationManager.swift
//  efb-212Tests
//
//  Mock location manager for testing components that depend on LocationManagerProtocol.
//

import Foundation
import CoreLocation
import Combine
@testable import efb_212

final class MockLocationManager: LocationServiceProtocol, @unchecked Sendable {
    var isTracking: Bool = false

    var requestAuthorizationCalled = false
    var startTrackingCalled = false
    var stopTrackingCalled = false

    func startTracking() async {
        startTrackingCalled = true
        isTracking = true
    }

    func stopTracking() {
        stopTrackingCalled = true
        isTracking = false
    }
}
