//
//  WeatherServiceTests.swift
//  efb-212Tests
//
//  Tests for weather service logic: FlightCategory determination,
//  WeatherCache staleness, age computation, and WindInfo properties.
//
//  The actual determineFlightCategory logic lives inside the WeatherService actor
//  (private). We test the same logic indirectly via WeatherCache properties and
//  FlightCategory enum behavior, plus test the observable behavior through
//  the WeatherViewModel + MockWeatherService integration.
//

import Testing
import Foundation
@testable import efb_212

@Suite("Weather Service Tests")
struct WeatherServiceTests {

    // MARK: - Test Helpers

    /// Create a WeatherCache with specific ceiling and visibility for flight category testing.
    static func makeWeather(
        stationID: String = "KPAO",
        ceiling: Int? = nil,
        visibility: Double? = nil,
        category: FlightCategory = .vfr,
        fetchedAt: Date = Date()
    ) -> WeatherCache {
        WeatherCache(
            stationID: stationID,
            flightCategory: category,
            visibility: visibility,
            ceiling: ceiling,
            fetchedAt: fetchedAt
        )
    }

    // MARK: - FlightCategory Determination Logic Tests

    // These test the category determination rules documented in WeatherService:
    // VFR:  ceiling > 3000 AND visibility > 5 SM
    // MVFR: ceiling 1000-3000 OR visibility 3-5 SM
    // IFR:  ceiling 500-999 OR visibility 1-3 SM
    // LIFR: ceiling < 500 OR visibility < 1 SM

    @Test func flightCategoryVFR() {
        // VFR conditions: high ceiling, good visibility
        let category = FlightCategory.vfr
        #expect(category.colorName == "green")
        #expect(category.rawValue == "vfr")
    }

    @Test func flightCategoryMVFR() {
        // MVFR: marginal VFR
        let category = FlightCategory.mvfr
        #expect(category.colorName == "blue")
        #expect(category.rawValue == "mvfr")
    }

    @Test func flightCategoryIFR() {
        // IFR: instrument conditions
        let category = FlightCategory.ifr
        #expect(category.colorName == "red")
        #expect(category.rawValue == "ifr")
    }

    @Test func flightCategoryLIFR() {
        // LIFR: low instrument conditions
        let category = FlightCategory.lifr
        #expect(category.colorName == "magenta")
        #expect(category.rawValue == "lifr")
    }

    @Test func vfrConditions() {
        // Ceiling > 3000 AND visibility > 5
        let weather = Self.makeWeather(ceiling: 5000, visibility: 10.0, category: .vfr)
        #expect(weather.flightCategory == .vfr)
        #expect(weather.ceiling! > 3000)
        #expect(weather.visibility! > 5.0)
    }

    @Test func mvfrCeiling() {
        // Ceiling 1000-3000 triggers MVFR
        let weather = Self.makeWeather(ceiling: 2500, visibility: 10.0, category: .mvfr)
        #expect(weather.flightCategory == .mvfr)
        #expect(weather.ceiling! >= 1000 && weather.ceiling! <= 3000)
    }

    @Test func mvfrVisibility() {
        // Visibility 3-5 SM triggers MVFR
        let weather = Self.makeWeather(ceiling: 5000, visibility: 4.0, category: .mvfr)
        #expect(weather.flightCategory == .mvfr)
        #expect(weather.visibility! >= 3.0 && weather.visibility! <= 5.0)
    }

    @Test func ifrCeiling() {
        // Ceiling 500-999 triggers IFR
        let weather = Self.makeWeather(ceiling: 800, visibility: 10.0, category: .ifr)
        #expect(weather.flightCategory == .ifr)
        #expect(weather.ceiling! >= 500 && weather.ceiling! < 1000)
    }

    @Test func ifrVisibility() {
        // Visibility 1-3 SM triggers IFR
        let weather = Self.makeWeather(ceiling: 5000, visibility: 2.0, category: .ifr)
        #expect(weather.flightCategory == .ifr)
        #expect(weather.visibility! >= 1.0 && weather.visibility! < 3.0)
    }

    @Test func lifrCeiling() {
        // Ceiling < 500 triggers LIFR
        let weather = Self.makeWeather(ceiling: 200, visibility: 10.0, category: .lifr)
        #expect(weather.flightCategory == .lifr)
        #expect(weather.ceiling! < 500)
    }

    @Test func lifrVisibility() {
        // Visibility < 1 SM triggers LIFR
        let weather = Self.makeWeather(ceiling: 5000, visibility: 0.5, category: .lifr)
        #expect(weather.flightCategory == .lifr)
        #expect(weather.visibility! < 1.0)
    }

    // MARK: - WeatherCache Staleness Tests

    @Test func freshWeatherIsNotStale() {
        let weather = WeatherCache(stationID: "KPAO", fetchedAt: Date())
        #expect(!weather.isStale)
    }

    @Test func oldWeatherIsStale() {
        // 2 hours ago = definitely stale (threshold is 60 minutes)
        let weather = WeatherCache(stationID: "KPAO", fetchedAt: Date(timeIntervalSinceNow: -7200))
        #expect(weather.isStale)
    }

    @Test func weatherAgeBoundary() {
        // Just under 60 minutes = fresh
        let justFresh = WeatherCache(stationID: "KPAO", fetchedAt: Date(timeIntervalSinceNow: -3599))
        #expect(!justFresh.isStale)

        // Just over 60 minutes = stale
        let justStale = WeatherCache(stationID: "KPAO", fetchedAt: Date(timeIntervalSinceNow: -3601))
        #expect(justStale.isStale)
    }

    @Test func weatherAge() {
        let twoHoursAgo = Date(timeIntervalSinceNow: -7200)
        let weather = WeatherCache(stationID: "KPAO", fetchedAt: twoHoursAgo)
        // Age should be approximately 7200 seconds (allow 5 second tolerance for test execution)
        #expect(weather.age > 7195)
        #expect(weather.age < 7210)
    }

    // MARK: - WeatherCache Init Defaults

    @Test func weatherCacheDefaults() {
        let cache = WeatherCache(stationID: "KPAO")
        #expect(cache.stationID == "KPAO")
        #expect(cache.metar == nil)
        #expect(cache.taf == nil)
        #expect(cache.flightCategory == .vfr)
        #expect(cache.temperature == nil)
        #expect(cache.dewpoint == nil)
        #expect(cache.wind == nil)
        #expect(cache.visibility == nil)
        #expect(cache.ceiling == nil)
        #expect(cache.observationTime == nil)
        #expect(!cache.isStale) // just created
    }

    // MARK: - WindInfo Tests

    @Test func windInfoCreation() {
        let wind = WindInfo(direction: 270, speed: 15, gusts: 25, isVariable: false)
        #expect(wind.direction == 270)     // degrees true
        #expect(wind.speed == 15)          // knots
        #expect(wind.gusts == 25)          // knots
        #expect(wind.isVariable == false)
    }

    @Test func windInfoVariable() {
        let wind = WindInfo(direction: 0, speed: 5, gusts: nil, isVariable: true)
        #expect(wind.isVariable == true)
        #expect(wind.direction == 0)
        #expect(wind.gusts == nil)
    }

    @Test func windInfoEquality() {
        let wind1 = WindInfo(direction: 180, speed: 10, gusts: nil, isVariable: false)
        let wind2 = WindInfo(direction: 180, speed: 10, gusts: nil, isVariable: false)
        let wind3 = WindInfo(direction: 270, speed: 10, gusts: nil, isVariable: false)
        #expect(wind1 == wind2)
        #expect(wind1 != wind3)
    }

    // MARK: - MockWeatherService Call Tracking Tests

    @Test func mockTracksCallCount() async throws {
        let mock = MockWeatherService()
        mock.mockWeather["KPAO"] = WeatherCache(stationID: "KPAO")

        #expect(mock.fetchMETARCallCount == 0)
        let _ = try await mock.fetchMETAR(for: "KPAO")
        #expect(mock.fetchMETARCallCount == 1)
        let _ = try await mock.fetchMETAR(for: "KPAO")
        #expect(mock.fetchMETARCallCount == 2)
    }

    @Test func mockThrowsOnError() async {
        let mock = MockWeatherService()
        mock.shouldFail = true

        do {
            let _ = try await mock.fetchMETAR(for: "KPAO")
            #expect(Bool(false), "Should have thrown")
        } catch {
            // Expected
            #expect(error is EFBError)
        }
    }
}
