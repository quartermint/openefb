//
//  WeatherViewModel.swift
//  efb-212
//
//  Manages weather data state for views. Fetches METAR/TAF data,
//  tracks staleness, and provides age-based badge coloring.
//  MainActor by default (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor).
//

import Foundation
import Combine
import SwiftUI

final class WeatherViewModel: ObservableObject {

    // MARK: - Published State

    /// Weather data keyed by ICAO station ID.
    @Published var weatherData: [String: WeatherCache] = [:]

    /// Whether a weather fetch is in progress.
    @Published var isLoading: Bool = false

    /// Last error encountered during weather operations.
    @Published var error: EFBError?

    // MARK: - Dependencies

    private let weatherService: any WeatherServiceProtocol

    // MARK: - Init

    init(weatherService: any WeatherServiceProtocol) {
        self.weatherService = weatherService
    }

    // MARK: - Fetch Methods

    /// Fetch weather for a single station and update published state.
    /// - Parameter stationID: ICAO identifier (e.g., "KPAO").
    func fetchWeather(for stationID: String) async {
        let id = stationID.uppercased()
        isLoading = true
        defer { isLoading = false }

        do {
            let weather = try await weatherService.fetchMETAR(for: id)
            weatherData[id] = weather
            error = nil
        } catch let efbError as EFBError {
            error = efbError
        } catch {
            self.error = .weatherFetchFailed(underlying: error)
        }
    }

    /// Fetch weather for multiple stations and update published state.
    /// - Parameter ids: Array of ICAO identifiers.
    func fetchWeatherForStations(_ ids: [String]) async {
        let uppercased = ids.map { $0.uppercased() }
        guard !uppercased.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let results = try await weatherService.fetchWeatherForStations(uppercased)
            for weather in results {
                weatherData[weather.stationID] = weather
            }
            error = nil
        } catch let efbError as EFBError {
            error = efbError
        } catch {
            self.error = .weatherFetchFailed(underlying: error)
        }
    }

    /// Refresh weather for all currently tracked stations.
    func refreshAll() async {
        let stationIDs = Array(weatherData.keys)
        guard !stationIDs.isEmpty else { return }

        await fetchWeatherForStations(stationIDs)
    }

    // MARK: - Weather Age Badge Color

    /// Color indicating weather data freshness for a given station.
    /// - Green: less than 30 minutes old
    /// - Yellow: 30-60 minutes old
    /// - Red: more than 60 minutes old
    /// - Parameter stationID: ICAO identifier.
    /// - Returns: SwiftUI Color for the age badge.
    func ageBadgeColor(for stationID: String) -> Color {
        guard let weather = weatherData[stationID.uppercased()] else {
            return .gray
        }
        return Self.ageBadgeColor(for: weather)
    }

    /// Color indicating weather data freshness for a WeatherCache.
    /// - Green: less than 30 minutes old
    /// - Yellow: 30-60 minutes old
    /// - Red: more than 60 minutes old
    static func ageBadgeColor(for weather: WeatherCache) -> Color {
        let ageMinutes = weather.age / 60.0
        if ageMinutes < 30 {
            return .green
        } else if ageMinutes < 60 {
            return .yellow
        } else {
            return .red
        }
    }

    /// Formatted age string for a station's weather data.
    /// - Parameter stationID: ICAO identifier.
    /// - Returns: Human-readable age string (e.g., "5 min", "1h 15m").
    func ageString(for stationID: String) -> String? {
        guard let weather = weatherData[stationID.uppercased()] else {
            return nil
        }
        return Self.ageString(for: weather)
    }

    /// Formatted age string for a WeatherCache entry.
    static func ageString(for weather: WeatherCache) -> String {
        let totalMinutes = Int(weather.age / 60)
        if totalMinutes < 1 {
            return "<1 min"
        } else if totalMinutes < 60 {
            return "\(totalMinutes) min"
        } else {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            if minutes == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(minutes)m"
        }
    }
}
