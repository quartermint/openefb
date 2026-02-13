//
//  MockNetworkManager.swift
//  efb-212Tests
//
//  Mock network manager for testing components that depend on NetworkManagerProtocol.
//

import Foundation
@testable import efb_212

final class MockNetworkManager: NetworkManagerProtocol, @unchecked Sendable {
    var mockData: [URL: Data] = [:]
    var isConnected: Bool = true
    var shouldFail: Bool = false

    func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        if shouldFail { throw EFBError.networkUnavailable }
        guard let data = mockData[url] else { throw EFBError.networkUnavailable }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func fetchData(from url: URL) async throws -> Data {
        if shouldFail { throw EFBError.networkUnavailable }
        guard let data = mockData[url] else { throw EFBError.networkUnavailable }
        return data
    }

    func download(from url: URL, to destination: URL) async throws {
        if shouldFail { throw EFBError.networkUnavailable }
    }
}
