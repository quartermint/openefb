//
//  MockWeatherService.swift
//  efb-212Tests
//
//  Mock weather service for testing components that depend on WeatherServiceProtocol.
//  Tracks call counts for verification and supports configurable responses.
//

import Foundation
@testable import efb_212

final class MockWeatherService: WeatherServiceProtocol, @unchecked Sendable {

    // MARK: - Configurable Responses

    /// Weather data keyed by station ICAO ID.
    var mockWeather: [String: WeatherCache] = [:]

    /// Override TAF response. If nil, returns a default "TAF <id> mock data" string.
    var mockTAF: String?

    /// Whether all fetch methods should throw an error.
    var shouldFail: Bool = false

    // MARK: - Call Tracking

    /// Number of times fetchMETAR was called.
    var fetchMETARCallCount: Int = 0

    /// Number of times fetchTAF was called.
    var fetchTAFCallCount: Int = 0

    /// Number of times fetchWeatherForStations was called.
    var fetchStationsCallCount: Int = 0

    // MARK: - WeatherServiceProtocol

    func fetchMETAR(for stationID: String) async throws -> WeatherCache {
        fetchMETARCallCount += 1
        if shouldFail {
            throw EFBError.weatherFetchFailed(underlying: NSError(domain: "test", code: -1))
        }
        guard let weather = mockWeather[stationID] else {
            throw EFBError.weatherFetchFailed(underlying: NSError(domain: "test", code: -1))
        }
        return weather
    }

    func fetchTAF(for stationID: String) async throws -> String {
        fetchTAFCallCount += 1
        if shouldFail {
            throw EFBError.weatherFetchFailed(underlying: NSError(domain: "test", code: -1))
        }
        return mockTAF ?? "TAF \(stationID) mock data"
    }

    func fetchWeatherForStations(_ stationIDs: [String]) async throws -> [WeatherCache] {
        fetchStationsCallCount += 1
        if shouldFail {
            throw EFBError.weatherFetchFailed(underlying: NSError(domain: "test", code: -1))
        }
        return stationIDs.compactMap { mockWeather[$0] }
    }

    func cachedWeather(for stationID: String) -> WeatherCache? {
        mockWeather[stationID]
    }
}
