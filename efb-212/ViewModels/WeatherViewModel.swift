//
//  WeatherViewModel.swift
//  efb-212
//
//  Weather data management for airport info sheet and weather displays.
//  Fetches METAR/TAF from WeatherService and provides decoded weather fields.
//  Per locked decision: auto-refresh on airport open + manual refresh button.
//

import Foundation
import Observation

@Observable
@MainActor
final class WeatherViewModel {

    // MARK: - Dependencies

    let weatherService: any WeatherServiceProtocol

    // MARK: - State

    var currentWeather: WeatherCache?
    var currentTAF: String?
    var isLoading: Bool = false
    var error: EFBError?

    // MARK: - Private

    /// Track current station for manual refresh.
    private var currentStationID: String?

    // MARK: - Init

    init(weatherService: any WeatherServiceProtocol) {
        self.weatherService = weatherService
    }

    // MARK: - Load Weather

    /// Load METAR and TAF for a station. Called on airport info sheet appear.
    func loadWeather(for stationID: String) async {
        currentStationID = stationID
        isLoading = true
        error = nil

        do {
            currentWeather = try await weatherService.fetchMETAR(for: stationID)
        } catch let fetchError as EFBError {
            error = fetchError
            // Keep cached weather if available
            currentWeather = weatherService.cachedWeather(for: stationID)
        } catch {
            self.error = EFBError.weatherFetchFailed(underlying: error)
            currentWeather = weatherService.cachedWeather(for: stationID)
        }

        do {
            currentTAF = try await weatherService.fetchTAF(for: stationID)
        } catch {
            // TAF fetch failure is non-critical; METAR is primary
            currentTAF = nil
        }

        isLoading = false
    }

    /// Manual refresh. Bypasses 15-min cache by clearing cache first.
    /// Per locked decision: "Weather auto-refreshes with 15-minute METAR cache,
    /// auto-refresh when airport info is opened, plus manual refresh button."
    func refreshWeather() async {
        guard let stationID = currentStationID else { return }

        // Force re-fetch by clearing service cache for this station
        if let service = weatherService as? WeatherService {
            await service.clearCache(for: stationID)
        }

        await loadWeather(for: stationID)
    }

    // MARK: - Decoded Weather Fields

    /// Formatted wind string: "310/08 KT" or "310/08 G15 KT" or "Calm"
    var decodedWind: String {
        guard let wx = currentWeather else { return "---" }
        guard let dir = wx.windDirection, let spd = wx.windSpeed else { return "---" }
        if spd == 0 { return "Calm" }
        if let gust = wx.windGust {
            return String(format: "%03d/%02d G%d KT", dir, spd, gust)
        }
        return String(format: "%03d/%02d KT", dir, spd)
    }

    /// Formatted ceiling: "2500' BKN" or "CLR"
    var decodedCeiling: String {
        guard let wx = currentWeather else { return "---" }
        if let ceil = wx.ceiling {
            return "\(ceil)' BKN"
        }
        return "CLR"
    }

    /// Formatted visibility: "10 SM" or ">10 SM"
    var decodedVisibility: String {
        guard let wx = currentWeather, let vis = wx.visibility else { return "---" }
        if vis.contains("+") || vis == "10" {
            return ">10 SM"
        }
        return "\(vis) SM"
    }

    /// Formatted temperature: "16C"
    var decodedTemp: String {
        guard let wx = currentWeather, let temp = wx.temperature else { return "---" }
        return "\(Int(temp))C"  // degrees Celsius
    }

    /// Formatted dewpoint: "9C"
    var decodedDew: String {
        guard let wx = currentWeather, let dew = wx.dewpoint else { return "---" }
        return "\(Int(dew))C"  // degrees Celsius
    }
}
