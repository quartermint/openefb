//
//  MockNetworkManager.swift
//  efb-212Tests
//
//  Mock reachability service for testing components that depend on ReachabilityServiceProtocol.
//

import Foundation
@testable import efb_212

final class MockNetworkManager: ReachabilityServiceProtocol, @unchecked Sendable {
    var isConnected: Bool = true
    var isExpensive: Bool = false

    func start() {}
    func stop() {}
}
