//
//  Protocols.swift
//  efb-212
//
//  All service protocols for dependency injection and testability.
//

import Foundation
import CoreLocation
import Combine

// MARK: - Database Manager Protocol

protocol DatabaseManagerProtocol: Sendable {
    // Aviation data (GRDB)
    func airport(byICAO icao: String) async throws -> Airport?
    func airports(near coordinate: CLLocationCoordinate2D, radiusNM: Double) async throws -> [Airport]
    func searchAirports(query: String, limit: Int) async throws -> [Airport]
    func airspaces(containing coordinate: CLLocationCoordinate2D, altitude: Double) async throws -> [Airspace]
    func nearestAirports(to coordinate: CLLocationCoordinate2D, count: Int) async throws -> [Airport]

    // Weather cache (ephemeral GRDB)
    func cachedWeather(for stationID: String) async throws -> WeatherCache?
    func cacheWeather(_ weather: WeatherCache) async throws
    func staleWeatherStations(olderThan interval: TimeInterval) async throws -> [String]
    func clearWeatherCache() async throws

    // NASR import
    func importNASRData(from url: URL, progress: @escaping (Double) -> Void) async throws

    // Seed data
    func loadSeedDataIfNeeded()
}

// MARK: - Location Manager Protocol

protocol LocationManagerProtocol: AnyObject {
    var location: CLLocation? { get }
    var heading: CLHeading? { get }
    var locationPublisher: AnyPublisher<CLLocation, Never> { get }
    func requestAuthorization()
    func startUpdating()
    func stopUpdating()
}

// MARK: - Weather Service Protocol

protocol WeatherServiceProtocol: Sendable {
    func fetchMETAR(for stationID: String) async throws -> WeatherCache
    func fetchTAF(for stationID: String) async throws -> String
    func fetchWeatherForStations(_ stationIDs: [String]) async throws -> [WeatherCache]
    func cachedWeather(for stationID: String) -> WeatherCache?
}

// MARK: - Network Manager Protocol

protocol NetworkManagerProtocol: Sendable {
    func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T
    func fetchData(from url: URL) async throws -> Data
    func download(from url: URL, to destination: URL) async throws
    var isConnected: Bool { get }
}

// MARK: - Audio Manager Protocol (Phase 2)

protocol AudioManagerProtocol: AnyObject {
    func startRecording(quality: String) throws
    func stopRecording() throws -> URL
    var isRecording: Bool { get }
}
