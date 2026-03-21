//
//  MockTFRService.swift
//  efb-212Tests
//
//  Mock TFR service for testing components that depend on TFRServiceProtocol.
//

import Foundation
import CoreLocation
@testable import efb_212

final class MockTFRService: TFRServiceProtocol, @unchecked Sendable {
    var mockTFRs: [TFR] = []
    var shouldFail: Bool = false
    var fetchCallCount: Int = 0

    func fetchTFRs(near coordinate: CLLocationCoordinate2D, radiusNM: Double) async throws -> [TFR] {
        fetchCallCount += 1
        if shouldFail {
            throw EFBError.tfrFetchFailed(underlying: NSError(domain: "test", code: -1))
        }
        return mockTFRs
    }

    func activeTFRs() async throws -> [TFR] {
        fetchCallCount += 1
        if shouldFail {
            throw EFBError.tfrFetchFailed(underlying: NSError(domain: "test", code: -1))
        }
        return mockTFRs
    }
}
