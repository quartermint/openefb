//
//  ReachabilityService.swift
//  efb-212
//
//  NWPathMonitor wrapper for network status monitoring.
//  Reports connectivity and whether connection is expensive (cellular).
//  Used by AppState to indicate when operating with cached data.
//

import Foundation
import Network

@Observable
final class ReachabilityService: ReachabilityServiceProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "efb.reachability")

    var isConnected: Bool = false
    var isExpensive: Bool = false  // cellular connection

    // MARK: - Monitoring

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = (path.status == .satisfied)
                self?.isExpensive = path.isExpensive
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }
}
