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

final class MockLocationManager: LocationManagerProtocol {
    var location: CLLocation?
    var heading: CLHeading?
    private let locationSubject = PassthroughSubject<CLLocation, Never>()
    var locationPublisher: AnyPublisher<CLLocation, Never> { locationSubject.eraseToAnyPublisher() }

    var requestAuthorizationCalled = false
    var startUpdatingCalled = false
    var stopUpdatingCalled = false

    func requestAuthorization() {
        requestAuthorizationCalled = true
    }

    func startUpdating() {
        startUpdatingCalled = true
    }

    func stopUpdating() {
        stopUpdatingCalled = true
    }

    func simulateLocation(_ location: CLLocation) {
        self.location = location
        locationSubject.send(location)
    }
}
